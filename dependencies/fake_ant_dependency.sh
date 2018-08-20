#!/bin/bash
set -x

# Part of this file are following directories:
dir=".m2/p2/repo-sdk/plugins/org.apache.ant_*"

# Use above directory if none specified
if [ -z "$1" ] ; then
    adir="$(dirname $0)/../$dir"
    makejar=1
else
    adir="$1"
fi

# Ant plugin is not a part of Fedora, so it needs to be created at build time.

# Usage:
# ./fake_ant_dependency ${ant_plugin_folder}
# where
#    ant_plugin_folder - a plugin that will have content replaced with symlinks

pushd $adir 2>&1 >/dev/null
    mkdir -p lib bin
    rm -f lib/*.jar
    build-jar-repository -s -p lib \
        ant/ant-antlr \
        ant/ant-apache-bcel \
        ant/ant-apache-bsf \
        ant/ant-apache-log4j \
        ant/ant-apache-oro \
        ant/ant-apache-regexp \
        ant/ant-apache-resolver \
        ant/ant-apache-xalan2 \
        ant/ant-commons-logging \
        ant/ant-commons-net \
        ant/ant-javamail \
        ant/ant-jdepend \
        ant/ant-jmf \
        ant/ant-jsch \
        ant/ant-junit4 \
        ant/ant-junit \
        ant/ant-junitlauncher \
        ant/ant-launcher \
        ant/ant-swing \
        ant/ant-testutil \
        ant/ant-xz \
        ant/ant
    for j in lib/*.jar ; do
        mv $j $(echo $j | sed -e 's/ant_//')
    done
    rm -f bin/ant bin/antRun
    ln -s $(which ant) bin/ant
    ln -s $(which antRun) bin/antRun

    # If makejar is specified, zip the plugin into a jar
    if [ "$makejar" = "1" ]; then
        cd ..
        rm -f *.jar
        pluginName=`ls | grep org.apache.ant_`
        zip -y -r ${pluginName}.jar ${pluginName}
    fi
popd 2>&1 >/dev/null
