#!/bin/sh

# TODO:
# - add some sort of "don't fetch, use the local source" logic
# - verify that the entire build can be run from the local checkout

# Possible optimizations:
# - don't check out non-Linux fragments (will need to patch features for this)

baseDir=$(pwd)
workDirectory=
buildID=
baseBuilder=
eclipseBuilder=
baseBuilderTag="R35_M7"

usage="usage:  <build ID> [-workdir <working directory>] [-baseBuilder <path to org.eclipse.releng.basebuilder checkout>] [-eclipseBuilder <path to org.eclipse.releng.eclipsebuilder checkout>] [-baseBuilderTag <org.eclipse.releng.basebuilder tag to check out>]"

while [ $# -gt 0 ]
do
        case "$1" in
                -workdir) workDirectory="$2"; shift;;
                -workDir) workDirectory="$2"; shift;;
                -baseBuilder) baseBuilder="$2"; shift;;
                -baseBuilderTag) baseBuilderTag="$2"; shift;;
                -eclipseBuilder) eclipseBuilder="$2"; shift;;
                -help) echo $usage; exit 0;;
                --help) echo $usage; exit 0;;
                -h) echo $usage; exit 0;;
                *) buildID="$1";
        esac
        shift
done

# Must specify a build ID
if [ "x${buildID}x" == "xx" ]; then
    echo >&2 "Must specify build ID.  Example:  I20090522-1710 ."
    echo >&2 "${usage}"
    exit 1
else
  echo "Going to create source tarballs for ${buildID}."
fi

if [ "x${workDirectory}x" == "xx" ]; then
  workDirectory=/tmp/eclipseSDKBuild
  echo "Working directory not set; using /tmp/eclipseSDKBuild."
fi

if [ "x${baseBuilder}x" == "xx" ]; then
  baseBuilder=${workDirectory}/org.eclipse.releng.basebuilder
  echo "Basebuilder checkout not specified; will check out ${baseBuilderTag} into ${baseBuilder}."
fi
if [ "x${eclipseBuilder}x" == "xx" ]; then
  eclipseBuilder=${workDirectory}/org.eclipse.releng.eclipsebuilder
  echo "Eclipsebuilder checkout not specified; will check out into ${eclipseBuilder}."
fi

fetchDirectory=${workDirectory}/fetch
mkdir -p ${fetchDirectory}
cvsRepo=":pserver:anonymous@dev.eclipse.org:/cvsroot/eclipse"
mapsRoot="org.eclipse.releng/maps"

# Fetch basebuilder
if [ ! -e ${baseBuilder} ]; then
  mkdir -p ${baseBuilder}
  pushd ${baseBuilder}/..
  cvs -d${cvsRepo} co -r ${baseBuilderTag} org.eclipse.releng.basebuilder
  popd
fi

# Fetch eclipsebuilder
if [ ! -e ${eclipseBuilder} ]; then
  mkdir -p ${eclipseBuilder}
  pushd ${eclipseBuilder}/..
  cvs -d${cvsRepo} co org.eclipse.releng.eclipsebuilder
  cd org.eclipse.releng.eclipsebuilder
  patch -p0 < ${baseDir}/patches/eclipse-addFetchMasterAndTestsTargets.patch
  popd
fi

# Build must be run from within o.e.r.eclipsebuilder checkout
pushd ${eclipseBuilder}

java -jar \
${baseBuilder}/plugins/org.eclipse.equinox.launcher_*.jar \
-consolelog \
-application org.eclipse.ant.core.antRunner \
-f buildAll.xml \
fetchMasterFeature \
-DbuildDirectory=${fetchDirectory} \
-DskipBase=true \
-DmapsRepo=${cvsRepo} \
-DmapCvsRoot=${cvsRepo} \
-DmapsCvsRoot=${cvsRepo} \
-DmapsRoot=${mapsRoot} \
-DmapsCheckoutTag=${buildID} \
-DmapVersionTag=${buildID} \
2>&1 | tee ${workDirectory}/sourcesFetch.log

tar cjf eclipse-${buildID}-fetched.tar.bz2 ${fetchDirectory}
rm -rf ${fetchDirectory}/*

java -jar \
${baseBuilder}/plugins/org.eclipse.equinox.launcher_*.jar \
-consolelog \
-application org.eclipse.ant.core.antRunner \
-f buildAll.xml \
fetchSdkTestsFeature \
-DbuildDirectory=${fetchDirectory} \
-DskipBase=true \
-DmapsRepo=${cvsRepo} \
-DmapCvsRoot=${cvsRepo} \
-DmapsCvsRoot=${cvsRepo} \
-DmapsRoot=${mapsRoot} \
-DmapsCheckoutTag=${buildID} \
-DmapVersionTag=${buildID} \
2>&1 | tee ${workDirectory}/testsFetch.log

tar cjf eclipse-sdktests-${buildID}-fetched.tar.bz2 ${fetchDirectory}

popd
