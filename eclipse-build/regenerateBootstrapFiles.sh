#!/bin/sh
set -e 

usage='usage: $0 <launcherDir>'

launcherDir=$1

if [ "x$launcherDir"x = 'xx' ]; then
   echo >&2 "$usage"
   exit 1
fi

java -jar \
$launcherDir/plugins/org.eclipse.equinox.launcher_*.jar \
-debug \
-consolelog \
-data $launcherDir \
-application org.eclipse.ant.core.antRunner \
-f pdebuild.xml generateScripts \
-DskipBase=true \
-DsdkSource=build/eclipse-3.8.0-I20120320-1400-src \
2>&1 | tee ./generatePdeBuildScripts.log
