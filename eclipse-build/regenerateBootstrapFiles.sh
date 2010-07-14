#!/bin/bash

baseDir=$(pwd)
workDirectory=
buildID=R3_5_2
baseBuilder=
eclipseBuilder=
baseBuilderTag="R3_5"
eclipseBuilderTag="R3_5_2"
fetchTests="no"
orbitRepoZip=orbitRepo-R20090825191606.zip
ecfBundlesZip=ecf-R3_5_2.zip
ecfTag="v20090604-1131"

java -jar \
/usr/lib/eclipse/plugins/org.eclipse.equinox.launcher_*.jar \
-consolelog \
-data build/eclipse-vM20100210-0800-fetched-src \
-application org.eclipse.ant.core.antRunner \
-f pdebuild.xml generateScripts \
-DbuildDirectory=build/eclipse-3.5.2-src \
-DskipBase=true \
-DsdkSource=build/eclipse-3.5.2-src \
2>&1 | tee ./generatePdeBuildScripts.log
