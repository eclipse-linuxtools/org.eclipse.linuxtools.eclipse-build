#!/bin/bash

# Possible optimizations:
# - don't check out non-Linux fragments (will need to patch features for this)

baseDir=$(pwd)
workDirectory=
buildID=R3_5_1
baseBuilder=
eclipseBuilder=
baseBuilderTag="R3_5"
eclipseBuilderTag="R3_5_1"
fetchTests="no"
orbitRepoZip=orbitRepo-R20090825191606.zip
ecfBundlesZip=ecf-R3_5_1.zip
ecfTag="v20090604-1131"

usage="usage:  <build ID> [-workdir <working directory>] [-baseBuilder <path to org.eclipse.releng.basebuilder checkout>] [-eclipseBuilder <path to org.eclipse.releng.eclipsebuilder checkout>] [-baseBuilderTag <org.eclipse.releng.basebuilder tag to check out>] [-noTests]"

while [ $# -gt 0 ]
do
        case "$1" in
                -workdir) workDirectory="$2"; shift;;
                -workDir) workDirectory="$2"; shift;;
                -baseBuilder) baseBuilder="$2"; shift;;
                -baseBuilderTag) baseBuilderTag="$2"; shift;;
                -eclipseBuilder) eclipseBuilder="$2"; shift;;
                -eclipseBuilderTag) eclipseBuilderTag="$2"; shift;;
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
    echo >&2 "Must specify build ID.  Example:  R3_5_1 ."
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
  cvs -d${cvsRepo} co -r ${eclipseBuilderTag} org.eclipse.releng.eclipsebuilder
  cd "${eclipseBuilder}"
  patch -p0 < "${baseDir}"/patches/eclipse-addFetchMasterAndTestsTargets.patch
  cd "${baseDir}"
fi

if [ -e ${orbitRepoZip} ]; then
  if [ ! -e ${fetchDirectory}/orbitRepo ]; then
    # Unzip Orbit repo
    # Note:  This is a zip of the repository available at:
    #
    #  http://download.eclipse.org/tools/orbit/downloads/drops/R20090825191606/updateSite
    #
    #  temporarily available at:
    #
    #  http://build.eclipse.org/eclipse/e4/build/e4/downloads/drops/4.0.0/targets/orbit/orbitRepo-R20090825191606.zip
    #
    # To avoid issues with mirrors that were out of sync with the repo, we
    # use this zipped copy.  Thanks to Paul Webster for help generating
    # it.  This is only done if we have a local copy of it.
    mkdir -p ${fetchDirectory}/orbitRepo
    unzip -q -d ${fetchDirectory}/orbitRepo ${orbitRepoZip}
  fi
fi

# Due to timeouts with eclipse.org, we keep a zipped copy of the binary
# ECF jars used y p2
if [ -e ${ecfBundlesZip} ]; then
  if [ ! -e ${fetchDirectory}/ecfBundles ]; then
    unzip -q -d ${fetchDirectory} ${ecfBundlesZip}
  fi
fi

if [ -e ${fetchDirectory}/orbitRepo ]; then
  cd "${eclipseBuilder}"
  patch -p0 < "${baseDir}"/patches/eclipse-dontusefullmoonformaster.patch
  cd "${baseDir}"
fi

if [ -e ${fetchDirectory}/ecfBundles ]; then
  cd "${eclipseBuilder}"
  patch -p0 < "${baseDir}"/patches/eclipse-useLocalECFBundles.patch
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

cd "${fetchDirectory}"

mkdir ecf-src

# Source for ECF bits that aren't part of SDK map files
for f in \
    org.eclipse.ecf \
    org.eclipse.ecf.filetransfer \
    org.eclipse.ecf.identity \
    org.eclipse.ecf.ssl \
; do
cvs -d :pserver:anonymous@dev.eclipse.org:/cvsroot/rt \
export -r ${ecfTag} org.eclipse.ecf/framework/bundles/$f;
done

mv org.eclipse.ecf/framework/bundles/* ecf-src
rm -fr org.eclipse.ecf/framework

for f in \
    org.eclipse.ecf.provider.filetransfer \
    org.eclipse.ecf.provider.filetransfer.httpclient \
    org.eclipse.ecf.provider.filetransfer.httpclient.ssl \
    org.eclipse.ecf.provider.filetransfer.ssl \
; do
cvs -d :pserver:anonymous@dev.eclipse.org:/cvsroot/rt \
export -r ${ecfTag} org.eclipse.ecf/providers/bundles/$f;
done

mv org.eclipse.ecf/providers/bundles/* ecf-src
rm -fr org.eclipse.ecf

cvs -d :pserver:anonymous@dev.eclipse.org:/cvsroot/rt \
export -r ${buildID} org.eclipse.equinox/components/bundles/org.eclipse.equinox.concurrent;

mv org.eclipse.equinox/components/bundles/* ecf-src
rm -rf org.eclipse.equinox

cd "${fetchDirectory}"
# We don't want to re-ship these as those bundles inside will already be
# copied into the right places for the build
rm -rf ecfBundles orbitRepo

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

# Testing runtests and test.xml scripts which are not in org.eclipse.test
cvs -d:pserver:anonymous@dev.eclipse.org:/cvsroot/eclipse co \
  -r ${buildID} \
  org.eclipse.releng.eclipsebuilder/eclipse/buildConfigs/sdk.tests/testScripts
scriptsDir=org.eclipse.releng.eclipsebuilder/eclipse/buildConfigs/sdk.tests/testScripts
testScripts=eclipse-sdktests-${buildID}-fetched-scripts
mkdir ${testScripts}
mv ${scriptsDir}/runtests ${testScripts}
mv ${scriptsDir}/test.xml ${testScripts}
rm -rf org.eclipse.releng.eclipsebuilder
tar cjf \
  "${workDirectory}"/eclipse-sdktests-${buildID}-fetched-scripts.tar.bz2 \
  ${testScripts}

fi

cd "${baseDir}"
