#!/bin/sh
set -e 

usage='usage: $0 <launcherDir>'

launcherDir=$1

if [ "x$launcherDir"x = 'xx' ]; then
   echo >&2 "$usage"
   exit 1
fi

java -jar \
$launcherDir/org.eclipse.equinox.launcher_*.jar \
-consolelog \
-data build/eclipse-3.6.0-src \
-application org.eclipse.ant.core.antRunner \
-f pdebuild.xml generateScripts \
-DbuildDirectory=build/eclipse-3.6.0-src \
-DskipBase=true \
-DsdkSource=build/eclipse-3.6.0-src \
2>&1 | tee ./generatePdeBuildScripts.log
