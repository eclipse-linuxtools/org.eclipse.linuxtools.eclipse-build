#!/bin/sh

# Possible optimizations:
# - don't check out non-Linux fragments (will need to patch features for this)

baseDir=$(pwd)
workDirectory=
buildID=I20090611-1540
baseBuilder=
eclipseBuilder=
baseBuilderTag="R3_5"
fetchTests="no"
eclipse-buildTag="R0_0_1"

usage="usage:  <build ID> [-workdir <working directory>] [-baseBuilder <path to org.eclipse.releng.basebuilder checkout>] [-eclipseBuilder <path to org.eclipse.releng.eclipsebuilder checkout>] [-baseBuilderTag <org.eclipse.releng.basebuilder tag to check out>] [-noTests]"

while [ $# -gt 0 ]
do
        case "$1" in
                -workdir) workDirectory="$2"; shift;;
                -workDir) workDirectory="$2"; shift;;
                -baseBuilder) baseBuilder="$2"; shift;;
                -baseBuilderTag) baseBuilderTag="$2"; shift;;
                -eclipseBuilder) eclipseBuilder="$2"; shift;;
                -noTests) fetchTests="no"; shift;;
                -help) echo $usage; exit 0;;
                --help) echo $usage; exit 0;;
                -h) echo $usage; exit 0;;
                *) buildID="$1";
        esac
        shift
done

# Must specify a build ID
if [ "x${buildID}x" = "xx" ]; then
    echo >&2 "Must specify build ID.  Example:  I20090611-1540 ."
    echo >&2 "${usage}"
    exit 1
else
  echo "Going to create source tarballs for ${buildID}."
fi

if [ "x${workDirectory}x" = "xx" ]; then
  workDirectory="${baseDir}"
  echo "Working directory not set; using this directory (${baseDir})."
fi

if [ "x${baseBuilder}x" = "xx" ]; then
  baseBuilder="${workDirectory}"/org.eclipse.releng.basebuilder
  echo "Basebuilder checkout not specified; will check out ${baseBuilderTag} into ${baseBuilder}."
fi
if [ "x${eclipseBuilder}x" = "xx" ]; then
  eclipseBuilder="${workDirectory}"/org.eclipse.releng.eclipsebuilder
  echo "Eclipsebuilder checkout not specified; will check out into ${eclipseBuilder}."
fi

fetchDirectory="${workDirectory}"/fetch
mkdir -p "${fetchDirectory}"
homeDirectory="${workDirectory}"/userhome
rm -rf "${homeDirectory}"
mkdir -p "${homeDirectory}"
workspace="${workDirectory}"/workspace
rm -rf "${workspace}"
mkdir -p "${workspace}"
cvsRepo=":pserver:anonymous@dev.eclipse.org:/cvsroot/eclipse"
mapsRoot="org.eclipse.releng/maps"

# Fetch basebuilder
if [ ! -e "${baseBuilder}" ]; then
  mkdir -p "${baseBuilder}"
  cd "${baseBuilder}"/..
  cvs -d${cvsRepo} co -r ${baseBuilderTag} org.eclipse.releng.basebuilder
  cd "${baseDir}"
fi

# Fetch eclipsebuilder
if [ ! -e ${eclipseBuilder} ]; then
  mkdir -p "${eclipseBuilder}"
  cd "${eclipseBuilder}"/..
  cvs -d${cvsRepo} co org.eclipse.releng.eclipsebuilder
  cd org.eclipse.releng.eclipsebuilder
  patch -p0 < "${baseDir}"/patches/eclipse-addFetchMasterAndTestsTargets.patch
  cd "${baseDir}"
fi

# Build must be run from within o.e.r.eclipsebuilder checkout
cd "${eclipseBuilder}"

java -jar \
"${baseBuilder}"/plugins/org.eclipse.equinox.launcher_*.jar \
-consolelog \
-data "${workspace}" \
-application org.eclipse.ant.core.antRunner \
-f buildAll.xml \
fetchMasterFeature \
-DbuildDirectory="${fetchDirectory}" \
-DskipBase=true \
-DmapsRepo=${cvsRepo} \
-DmapCvsRoot=${cvsRepo} \
-DmapsCvsRoot=${cvsRepo} \
-DmapsRoot=${mapsRoot} \
-DmapsCheckoutTag=${buildID} \
-DmapVersionTag=${buildID} \
-Duser.home="${homeDirectory}" \
2>&1 | tee ${workDirectory}/sourcesFetch.log

java -jar \
"${baseBuilder}"/plugins/org.eclipse.equinox.launcher_*.jar \
-consolelog \
-data "${workspace}" \
-application org.eclipse.ant.core.antRunner \
-f ../pdebuild.xml generateScripts \
-DbuildDirectory="${fetchDirectory}" \
-DskipBase=true \
-Duser.home="${homeDirectory}" \
-DsdkSource="${fetchDirectory}" \
2>&1 | tee "${workDirectory}"/generatePdeBuildScripts.log

cd "${fetchDirectory}"
mkdir eclipse-${buildID}-fetched-src
mv * eclipse-${buildID}-fetched-src
tar cjf "${workDirectory}"/eclipse-${buildID}-fetched-src.tar.bz2 \
  eclipse-${buildID}-fetched-src
cd "${eclipseBuilder}"

if [ "${fetchTests}" = "yes" ]; then

rm -rf "${fetchDirectory}"/*

java -jar \
"${baseBuilder}"/plugins/org.eclipse.equinox.launcher_*.jar \
-consolelog \
-data "${workspace}" \
-application org.eclipse.ant.core.antRunner \
-f buildAll.xml \
fetchSdkTestsFeature \
-DbuildDirectory="${fetchDirectory}" \
-DskipBase=true \
-DmapsRepo=${cvsRepo} \
-DmapCvsRoot=${cvsRepo} \
-DmapsCvsRoot=${cvsRepo} \
-DmapsRoot=${mapsRoot} \
-DmapsCheckoutTag=${buildID} \
-DmapVersionTag=${buildID} \
-Duser.home="${homeDirectory}" \
2>&1 | tee "${workDirectory}"/testsFetch.log

cd "${fetchDirectory}"
mkdir eclipse-sdktests-${buildID}-fetched-src
mv * eclipse-sdktests-${buildID}-fetched-src
tar cjf "${workDirectory}"/eclipse-sdktests-${buildID}-fetched-src.tar.bz2 \
  eclipse-sdktests-${buildID}-fetched-src

fi
cd "${baseDir}"
