#!/bin/bash
set -e

baseDir=$(pwd)
workDirectory=
baseBuilder=
eclipseBuilder=

buildID="I20120320-1400"
baseBuilderTag="R4_2_primary"
eclipseBuilderTag="R4_2_primary"
label="3.8.0-I20120320-1400"
fetchTests="yes"

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
if [ "x${eclipseBuilderTag}x" = "xx" ]; then
  eclipseBuilderTag="v${buildID}"
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
  patch -p0 < "${baseDir}"/patches/eclipse-removeSkipMapsCheck.patch
  cd "${baseDir}"
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

# Extract osgi.util src for rebuilding
pushd plugins/org.eclipse.osgi.util
  if [ -e src.zip ]; then
    unzip -q -d src src.zip
    # Remove pre-compiled class files and the source.zip
    rm -r org/ src.zip
  fi
popd

# Extract osgi.services src for rebuilding
pushd plugins/org.eclipse.osgi.services
  if [ -e src.zip ]; then
    unzip -q -d src src.zip
    # Remove pre-compiled class files and the source.zip
    rm -r org/ src.zip
  fi
popd

# Remove sources for service.io
pushd plugins
  rm -rf org.eclipse.equinox.io
  rm -rf org.eclipse.osgi.services/src/org/osgi/service/io/
popd

# Remove scmCache directory
rm -rf scmCache

#fetch and prepare ecf
git clone git://git.eclipse.org/gitroot/ecf/org.eclipse.ecf.git
cd org.eclipse.ecf
git archive --format=tar --prefix=ecf-3.5.5/ R-Release_HEAD-sdk_feature-51_2012-03-19_06-12-11 | gzip >ecf-3.5.5.tar.gz
cp ecf-3.5.5.tar.gz ../
cd ..
rm -fr org.eclipse.ecf
tar -xf ecf-3.5.5.tar.gz
rm -fr ecf-3.5.5.tar.gz
cd ecf-3.5.5

# Source for ECF bthat aren't part of SDK map files
for f in \
    org.eclipse.ecf \
    org.eclipse.ecf.filetransfer \
    org.eclipse.ecf.identity \
    org.eclipse.ecf.ssl \
; do
cp -rf framework/bundles/$f ../plugins;
rm -rf framework/bundles/$f
done

for f in \
    org.eclipse.ecf.provider.filetransfer \
    org.eclipse.ecf.provider.filetransfer.httpclient \
    org.eclipse.ecf.provider.filetransfer.httpclient.ssl \
    org.eclipse.ecf.provider.filetransfer.ssl \
; do
cp -rf  providers/bundles/$f ../plugins;
rm -rf providers/bundles/$f
done
cd ..
rm -fr ecf-3.5.5

#fix paths here - they are not correctly rendered
#fetch and prepare initializer
#rm -rf rt.equinox.incubator
git clone git://git.eclipse.org/gitroot/equinox/rt.equinox.incubator.git
cd rt.equinox.incubator
git archive --format=tar --prefix=org.eclipse.equinox.initializer/ HEAD:framework/bundles/org.eclipse.equinox.initializer | gzip > org.eclipse.equinox.initializer.tar.gz
cp org.eclipse.equinox.initializer.tar.gz ../
cd ..
rm -rf rt.equinox.incubator
tar -xf org.eclipse.equinox.initializer.tar.gz
rm -rf org.eclipse.equinox.initializer.tar.gz
cp -rf org.eclipse.equinox.initializer plugins
rm -rf org.eclipse.equinox.initializer

cd "${fetchDirectory}"
# We don't want to re-ship these as those bundles inside will already be
# copied into the right places for the build
rm -rf ecfBundles orbitRepo

# Remove files from the version control system
find -depth -name CVS -exec rm -rf {} \;

# Remove prebuilt binaries
find \( -name '*.exe' -o -name '*.dll' \) -delete
find -type f \( -name '*.so' -o -name '*.so.2' -o -name '*.a' \) -delete
find \( -name '*.sl' -o -name '*.jnilib' \) -delete
find features/org.eclipse.equinox.executable -name eclipse -delete
find \( -name '*.cvsignore' \) -delete

# Remove unnecessary repo
rm -rf tempSite
# Before removing all binary JARs extract source code
# of execution profiles to build them later
pushd plugins/org.eclipse.osgi/osgi
for f in \
        ee.foundation \
        ee.minimum-1.2.0 \
        ee.minimum \
        osgi.cmpn \
        osgi.core \
; do
	mkdir -p  ../../../environments/$f/
	mkdir -p $f
	cp "$f.jar" $f/
	cd $f
	jar xf "$f.jar" || unzip "$f.jar"
	cp -rf OSGI-OPT/src/ ../../../../environments/$f/ || echo "Copying $f failed"
	cp -rf META-INF ../../../../environments/$f/ || echo "Copying $f META-INF failed"
	cp -rf LICENSE ../../../../environments/$f/ || echo "Copying $f LICENCE failed"
	cp -rf about.html ../../../../environments/$f/ || echo "Copying $f about.html failed"
	cd ..
done;
popd

# Remove binary JARs
find -type f -name '*.jar' -delete

# Remove fetch logs
rm fetch_*

# Remove unnecessary feature and plugins
rm -rf features/org.eclipse.sdk.examples
rm -rf plugins/*.examples*

# Remove temporary files
find -name '*.orig' -delete

# Remove empty directories
find -type d -empty -delete

cd ..
#mv -f fetch eclipse-${label}-src
cp -rf fetch eclipse-${label}-src
rm -rf fetch
tar cjf "${workDirectory}"/eclipse-${label}-src.tar.bz2 \
  eclipse-${label}-src
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
-Dhuson=true \
-DmapsRepo=${cvsRepo} \
-DmapCvsRoot=${cvsRepo} \
-DmapsCvsRoot=${cvsRepo} \
-DmapsRoot=${mapsRoot} \
-DmapsCheckoutTag=${buildID} \
-DmapVersionTag=${buildID} \
-Duser.home="${homeDirectory}" \
2>&1 | tee "${workDirectory}"/testsFetch.log

cd ${workDirectory}
mkdir -p ${workDirectory}/eclipse-sdktests-${label}-src
cp -rf ${fetchDirectory}/* ${workDirectory}/eclipse-sdktests-${label}-src
rm -rf ${fetchDirectory}/*
tar cjf ${workDirectory}/eclipse-sdktests-${label}-src.tar.bz2 \
 eclipse-sdktests-${label}-src

scriptsDir=org.eclipse.releng.eclipsebuilder/eclipse/buildConfigs/sdk.tests/testScripts
testScripts=eclipse-sdktests-${label}-scripts

# Testing runtests and test.xml scripts which are not in org.eclipse.test
rm -rf org.eclipse.releng.eclipsebuilder/eclipse/buildConfigs/sdk.tests/testScripts/*
cvs -d ${cvsRepo} co -r ${buildID} ${scriptsDir}

mkdir -p ${testScripts}
cp -rf ${scriptsDir}/runtests ${testScripts}
rm -rf ${scriptsDir}/runtests
cp -rf ${scriptsDir}/test.xml ${testScripts}
rm -rf ${scriptsDir}/test.xml
rm -rf org.eclipse.releng.eclipsebuilder
tar cjf ${workDirectory}/eclipse-sdktests-${label}-scripts.tar.bz2 ${testScripts}

fi

cd "${baseDir}"
