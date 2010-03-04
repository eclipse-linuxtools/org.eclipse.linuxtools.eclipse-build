#!/bin/bash
set -e

# We use the upstream srcIncluded drop as input.  It can be obtained
# from:   http://download.eclipse.org/eclipse/downloads/drops/
#
# In our case, we're using:  R-3.5.2-201002111343/eclipse-sourceBuild-srcIncluded-3.5.2.zip

equinoxTag="R35x_v20100209"
ecfTag="v20090831-1453"
label="3.5.2"
buildID="R3_5_2"
upstreamSrcDrop="/tmp/eclipse-sourceBuild-srcIncluded-${label}.zip"

eclipsebuildURL=svn://dev.eclipse.org/svnroot/technology/org.eclipse.linuxtools/eclipse-build/branches/symlinkDependencies

baseBuilderTag="R3_5"

baseDir=$(pwd)
workDirectory=
baseBuilder=
eclipseBuilder=
fetchTests="no"

usage="usage:  <build ID> [-workdir <working directory>] [-upstreamSrcDrop <path to upstream srcIncluded zip>] [-baseBuilder <path to org.eclipse.releng.basebuilder checkout>] [-baseBuilderTag <org.eclipse.releng.basebuilder tag to check out>] [-noTests]"

while [ $# -gt 0 ]
do
        case "$1" in
                -workdir) workDirectory="$2"; shift;;
                -workDir) workDirectory="$2"; shift;;
                -baseBuilder) baseBuilder="$2"; shift;;
                -baseBuilderTag) baseBuilderTag="$2"; shift;;
                -upstreamSrcDrop) upstreamSrcDrop="$2"; shift;;
                -noTests) fetchTests="no"; shift;;
                -help) echo $usage; exit 0;;
                --help) echo $usage; exit 0;;
                -h) echo $usage; exit 0;;
        esac
        shift
done

if [ "x${workDirectory}x" = "xx" ]; then
  workDirectory="${baseDir}"
  echo "Working directory not set; using this directory (${baseDir})."
fi

mkdir -p ${workDirectory}
cd ${workDirectory}

# Cleanup
rm -rf eclipse-${label}-src org.eclipse.releng.eclipsebuilder

mkdir -p eclipse-${label}-src
cd eclipse-${label}-src

unzip -d upstream -q ${upstreamSrcDrop}
mv upstream/org.eclipse.releng.eclipsebuilder ..
eclipseBuilder=$(pwd)/../org.eclipse.releng.eclipsebuilder
mv upstream/src .
rm -rf upstream

cd src

# Source for ECF bits that aren't part of SDK source drop
mkdir ecf-src

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
export -r ${equinoxTag} org.eclipse.equinox/components/bundles/org.eclipse.equinox.concurrent;

mv org.eclipse.equinox/components/bundles/* ecf-src
rm -rf org.eclipse.equinox

# Get rid of src subdirectory
cd ..
mv src/* .

# Remove files from the version control system
find -depth -name CVS -exec rm -rf {} \;

# Remove prebuilt binaries
find \( -name '*.exe' -o -name '*.dll' \) -delete
find \( -name '*.jnilib' -o -name '*.sl' \) -delete
find \( -name '*.a' -o -name '*.so' -o -name '*.so.2' \) -delete
find features/org.eclipse.equinox.executable -name eclipse -delete
find \( -name '*.cvsignore' \) -delete

# Remove binary JARs
find -name '*.jar' -delete

# Remove pre-created .source bundles/features
rm -rf plugins/*\.source_*
rm -rf features/*\.source

# Remove empty directories
find -depth -type d -empty -delete

cd ..
tar cjf eclipse-${label}-src.tar.bz2 eclipse-${label}-src

#-------------- / Tests / --------------------#
if [ "${fetchTests}" = "yes" ]; then

homeDirectory="${workDirectory}"/userhome
rm -rf "${homeDirectory}"
mkdir -p "${homeDirectory}"
workspace="${workDirectory}"/workspace
rm -rf "${workspace}"
mkdir -p "${workspace}"
cvsRepo=":pserver:anonymous@dev.eclipse.org:/cvsroot/eclipse"
mapsRoot="org.eclipse.releng/maps"

pushd ${eclipseBuilder}
patch -p0 < "${baseDir}"/patches/eclipse-addFetchMasterAndTestsTargets.patch
popd

# Fetch basebuilder
if [ "x${baseBuilder}x" = "xx" ]; then
  baseBuilder="${workDirectory}"/org.eclipse.releng.basebuilder
  echo "Basebuilder checkout not specified; will check out ${baseBuilderTag} into ${baseBuilder}."
fi

if [ ! -e "${baseBuilder}" ]; then
  mkdir -p "${baseBuilder}"
  cd "${baseBuilder}"/..
  cvs -d${cvsRepo} co -r ${baseBuilderTag} org.eclipse.releng.basebuilder
  cd "${baseDir}"
fi

# Build must be run from within o.e.r.eclipsebuilder checkout
cd ${eclipsebuilder}

fetchDirectory="${workDirectory}"/fetch
mkdir -p "${fetchDirectory}"
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
mkdir eclipse-sdktests-${label}-src
mv * ${workDirectory}/eclipse-sdktests-${label}-src
tar cjf "${workDirectory}"/eclipse-sdktests-${label}-src.tar.bz2 \
  ${workDirectory}/eclipse-sdktests-${label}-src

# Testing runtests and test.xml scripts which are not in org.eclipse.test
cvs -d:pserver:anonymous@dev.eclipse.org:/cvsroot/eclipse co \
  -r ${buildID} \
  org.eclipse.releng.eclipsebuilder/eclipse/buildConfigs/sdk.tests/testScripts
scriptsDir=org.eclipse.releng.eclipsebuilder/eclipse/buildConfigs/sdk.tests/testScripts
testScripts=eclipse-sdktests-${label}-scripts
mkdir ${testScripts}
mv ${scriptsDir}/runtests ${testScripts}
mv ${scriptsDir}/test.xml ${testScripts}
rm -rf org.eclipse.releng.eclipsebuilder
tar cjf \
  "${workDirectory}"/eclipse-sdktests-${label}-fetched-scripts.tar.bz2 \
  ${testScripts}

fi
#-------------- / tests / --------------------#
rm -rf ${eclipseBuilder}

cd "${baseDir}"
