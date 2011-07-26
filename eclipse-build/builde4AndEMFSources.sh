#!/bin/bash
set -e

baseDir=$(pwd)
workDirectory=
baseBuilder=
e4Builder=

buildID="HEAD"
baseBuilderTag="v20110711"
e4BuilderTag="HEAD"
label="4.1.0"
fetchTests="yes"

EMFversion=2.7.0
emfTag="R2_7_0"

cvsRepo=":pserver:anonymous@dev.eclipse.org:/cvsroot/eclipse"
mapsRoot="org.eclipse.releng/maps"
emfCVSRepo=":pserver:anonymous@dev.eclipse.org:/cvsroot/modeling"
emfCVSdir="org.eclipse.emf/org.eclipse.emf/"
mapIncludingEMF="${baseDir}"/org.eclipse.e4.sdk/maps/e4.map

usage="usage:  <build ID> [-workdir <working directory>] [-baseBuilder <path to org.eclipse.releng.basebuilder checkout>] [-e4Builder <path to org.eclipse.releng.e4Builder checkout>] [-baseBuilderTag <org.eclipse.releng.basebuilder tag to check out>] [-noTests]"

while [ $# -gt 0 ]
do
        case "$1" in
                -workdir) workDirectory="$2"; shift;;
                -workDir) workDirectory="$2"; shift;;
                -baseBuilder) baseBuilder="$2"; shift;;
                -baseBuilderTag) baseBuilderTag="$2"; shift;;
                -e4Builder) e4Builder="$2"; shift;;
                -e4BuilderTag) e4BuilderTag="$2"; shift;;
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
    echo >&2 "Must specify build ID.  Example:  R4_1 ."
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
if [ "x${e4Builder}x" = "xx" ]; then
  e4Builder="${workDirectory}"/org.eclipse.releng.e4Builder
  echo "e4Builder checkout not specified; will check out into ${e4Builder}."
fi

fetchDirectory="${workDirectory}"/fetch
mkdir -p "${fetchDirectory}"
homeDirectory="${workDirectory}"/userhome
rm -rf "${homeDirectory}"
mkdir -p "${homeDirectory}"
workspace="${workDirectory}"/workspace
rm -rf "${workspace}"
mkdir -p "${workspace}"

# Fetch basebuilder
if [ ! -e "${baseBuilder}" ]; then
  mkdir -p "${baseBuilder}"
  cd "${baseBuilder}"/..
  cvs -d${cvsRepo} co -r ${baseBuilderTag} org.eclipse.releng.basebuilder
  cd "${baseDir}"
fi

# Fetch e4 builder
if [ ! -e ${e4Builder} ]; then
  mkdir -p "${e4Builder}"
  cd "${e4Builder}"/..
  cvs -d${cvsRepo} co -r ${e4BuilderTag} -d org.eclipse.e4.builder \
    e4/releng/org.eclipse.e4.builder
  cd "${e4Builder}"
  patch -p0 < "${baseDir}"/patches/e4-addFetchTarget.patch
#  patch -p0 < "${baseDir}"/patches/e4-removeSkipMapsCheck.patch
  patch -p0 < "${baseDir}"/patches/e4-skipMirroring.patch
  cd "${baseDir}"
fi

# Fetch e4 SDK builder
if [ ! -e ${e4Builder} ]; then
  mkdir -p "${e4Builder}"
  cd "${e4Builder}"/..
  cvs -d${cvsRepo} co -r ${e4BuilderTag} -d org.eclipse.e4.sdk \
    e4/releng/org.eclipse.e4.sdk
  cd "${e4Builder}"
  cd "${baseDir}"
fi

# Build must be run from within o.e.e4.builder checkout
cd "${e4Builder}/scripts"

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
#-DmapsRoot=${mapsRoot} \
-DmapsCheckoutTag=${buildID} \
-DmapVersionTag=${buildID} \
-Duser.home="${homeDirectory}" \
2>&1 | tee ${workDirectory}/sourcesFetch.log

cd "${fetchDirectory}"

cd "${fetchDirectory}"

# Remove files from the version control system
find -depth -name CVS -exec rm -rf {} \;

# Remove prebuilt binaries
find \( -name '*.exe' -o -name '*.dll' \) -delete
find \( -name '*.so' -o -name '*.so.2' -o -name '*.a' \) -delete
find \( -name '*.sl' -o -name '*.jnilib' \) -delete
find features/org.eclipse.equinox.executable -name eclipse -delete
find \( -name '*.cvsignore' \) -delete

# Remove unnecessary repo
rm -rf tempSite

# Remove binary JARs
find -name '*.jar' -delete

# Remove fetch logs
rm fetch_*

# Remove temporary files
find -name '*.orig' -delete

# Remove empty directories
find -type d -empty -delete

cd ..
mv fetch e4-${label}-src
tar cjf "${workDirectory}"/e4-${label}-src.tar.bz2 \
  e4-${label}-src
cd "${e4Builder}"

#if [ "${fetchTests}" = "yes" ]; then
#
#rm -rf "${fetchDirectory}"/*
#
#java -jar \
#"${baseBuilder}"/plugins/org.eclipse.equinox.launcher_*.jar \
#-consolelog \
#-data "${workspace}" \
#-application org.eclipse.ant.core.antRunner \
#-f buildAll.xml \
#fetchSdkTestsFeature \
#-DbuildDirectory="${fetchDirectory}" \
#-DskipBase=true \
#-Dhuson=true \
#-DmapsRepo=${cvsRepo} \
#-DmapCvsRoot=${cvsRepo} \
#-DmapsCvsRoot=${cvsRepo} \
#-DmapsRoot=${mapsRoot} \
#-DmapsCheckoutTag=${buildID} \
#-DmapVersionTag=${buildID} \
#-Duser.home="${homeDirectory}" \
#2>&1 | tee "${workDirectory}"/testsFetch.log
#
#cd ${workDirectory}
#mkdir ${workDirectory}/eclipse-sdktests-${label}-src
#mv ${fetchDirectory}/* ${workDirectory}/eclipse-sdktests-${label}-src
#tar cjf ${workDirectory}/eclipse-sdktests-${label}-src.tar.bz2 \
# eclipse-sdktests-${label}-src
#
#scriptsDir=org.eclipse.releng.e4Builder/eclipse/buildConfigs/sdk.tests/testScripts
#testScripts=eclipse-sdktests-${label}-scripts
#
## Testing runtests and test.xml scripts which are not in org.eclipse.test
#rm -rf org.eclipse.releng.e4Builder/eclipse/buildConfigs/sdk.tests/testScripts/*
#cvs -d ${cvsRepo} co -r ${buildID} ${scriptsDir}
#
#mkdir ${testScripts}
#mv ${scriptsDir}/runtests ${testScripts}
#mv ${scriptsDir}/test.xml ${testScripts}
#rm -rf org.eclipse.releng.e4Builder
#tar cjf ${workDirectory}/eclipse-sdktests-${label}-scripts.tar.bz2 ${testScripts}
#
#fi

cd "${baseDir}"

quiet="-q"

mkdir -p emfFore4-${EMFversion}-src
pushd emfFore4-${EMFversion}-src >/dev/null
mkdir -p features plugins

for f in $(grep emf ${mapIncludingEMF} | sed s/=.*//); do
  if [[ $f == feature* ]]; then
    element=$(echo $f | sed s/feature@//);
    fetchDir="features/$element";
    element="${emfCVSdir}/features/${element}-feature";
  else
    element=$(echo $f | sed s/plugin@//);
    fetchDir="plugins/$element";
    element="${emfCVSdir}/plugins/${element}";
  fi
  cvs -d ${emfCVSRepo} ${quiet} \
    export -r ${emfTag} -d ${fetchDir} ${element}
done
cvs -d ${emfCVSRepo} export -r ${emfTag} -d \
 features/org.eclipse.emf.license \
 ${emfCVSdir}/features/org.eclipse.emf.license-feature
popd

tar cjf emfFore4-${EMFversion}-src.tar.bz2 emfFore4-${EMFversion}-src