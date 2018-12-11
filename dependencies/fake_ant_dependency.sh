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
    antlibdir="$(realpath $(dirname $(which ant) )/../share/ant/lib)"
    for antlib in $(ls -1 $antlibdir) ; do
        ln -s $antlibdir/$antlib lib/$antlib
    done
    rm -f bin/ant
    ln -s $(which ant) bin/ant

    # If makejar is specified, zip the plugin into a jar
    if [ "$makejar" = "1" ]; then
        cd ..
        rm -f *.jar
        pluginName=`ls | grep org.apache.ant_`
        zip -y -r ${pluginName}.jar ${pluginName}
    fi
popd 2>&1 >/dev/null
