#!/bin/bash
set -x

# Part of this file are following directories:
# .m2/p2/repo-sdk/plugins/org.apache.ant_1.10.1.v20170407-1341

# Ant plugin is not a part of Fedora, so it needs to be created at build time.

# Usage:
# ./fake_ant_dependency ${ant_plugin_folder} [-makejar]
# where
#    ant_plugin_folder - a plugin that will have content replaced with symlinks
#    -makejar - optionally create a jar-shaped bundle instead of dir-shaped

pushd $1
    mkdir -p lib
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
        ant/ant-launcher \
        ant/ant-swing \
        ant/ant-testutil \
        ant/ant
    for j in lib/*.jar ; do
        mv $j $(echo $j | sed -e 's/ant_//')
    done

    # If -makejar is specified, zip the plugin into a jar
    if [ "-makejar" = "$2" ]; then
        cd ..
        pluginName=`ls | grep org.apache.ant_`
        zip -y -r ${pluginName}.jar ${pluginName}
    fi
popd
