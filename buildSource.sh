#!/bin/sh

# So far, all this does is reproduce the beginning parts of the upstream
# SDK build.  I have yet to verify whether or not it actually finishes
# fetching nor whether it is buildable.  It is just a small work in
# progress so far.

# TODO:
# - add some sort of "stop after fetching" target or logic
# - add some sort of "don't fetch, use the local source" logic
# - verify that the entire build can be run from the local checkout

# Optimizations:
# - don't check out non-Linux fragments

buildID=$1
if [ "x${buildID}x" == "xx" ]; then
    echo "Must specify build ID"
    exit 1
fi

# cvs -d:pserver:anonymous@dev.eclipse.org:/cvsroot/eclipse co -r R35_M7 org.eclipse.releng.basebuilder
baseBuilder=/home/overholt/eclipse-build/basebuilder/org.eclipse.releng.basebuilder
# cvs -d:pserver:anonymous@dev.eclipse.org:/cvsroot/eclipse co org.eclipse.releng.eclipsebuilder
eclipseBuilder=/home/overholt/workspace/org.eclipse.releng.eclipsebuilder.new
buildDirectory=/tmp/eclipseSDKBuildDirectory
cvsRepo=":pserver:anonymous@dev.eclipse.org:/cvsroot/eclipse"
mapsRoot="org.eclipse.releng/maps"

# Must be run from within o.e.r.eclipsebuilder checkout
pushd ${eclipseBuilder}

java -jar \
${baseBuilder}/plugins/org.eclipse.equinox.launcher_*.jar \
-consolelog \
-application org.eclipse.ant.core.antRunner \
-buildFile buildAll.xml \
-DbuildDirectory=${buildDirectory} \
-DmapsRepo=${cvsRepo} \
-DmapsRoot=${mapsRoot} \
-DmapsCheckoutTag=${buildID} \
-DmapVersionTag=${buildID} \
2>&1 | tee ${buildDirectory}/sourceBuild.log

popd
