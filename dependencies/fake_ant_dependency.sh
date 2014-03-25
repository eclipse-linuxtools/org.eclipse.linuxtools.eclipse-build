#!/bin/bash

# Part of this file are following directories:
# .m2/p2/repo-sdk/plugins/org.apache.ant_1.9.2.v201307241445

# Ant plugin is not a part of Fedora, so it needs to be created at build time.

# Usage:
# ./fake_ant_dependency ${ant_plugin_folder} ${javadir} ${binddir}
# where
#    ant_plugin_folder - a plugin that will have content replaced with symlinks
#    javadir - main java folder, currently /usr/share/java
#    bindir - a place where executable can be found. $3
#	 -makejar

pushd $1
	  mkdir -p lib bin
    pushd lib
        rm -rf *
        ln -s $2/ant/ant-antlr.jar
        ln -s $2/ant/ant-apache-bcel.jar
        ln -s $2/ant/ant-apache-bsf.jar
        ln -s $2/ant/ant-apache-log4j.jar
        ln -s $2/ant/ant-apache-oro.jar
        ln -s $2/ant/ant-apache-regexp.jar
        ln -s $2/ant/ant-apache-resolver.jar
        ln -s $2/ant/ant-apache-xalan2.jar
        ln -s $2/ant/ant-commons-logging.jar
        ln -s $2/ant/ant-commons-net.jar
        ln -s $2/ant/ant-javamail.jar
        ln -s $2/ant/ant-jdepend.jar
        ln -s $2/ant/ant-jmf.jar
        ln -s $2/ant/ant-jsch.jar
        ln -s $2/ant/ant-junit.jar
        ln -s $2/ant/ant-junit.jar junit4.jar
        ln -s $2/ant-launcher.jar
        ln -s $2/ant/ant-swing.jar
        ln -s $2/ant/ant-testutil.jar
        ln -s $2/ant.jar
    popd
    pushd etc
        ln -s $2/ant-bootstrap.jar
    popd
    pushd bin
        rm -rf *
        ln -s $3/ant ant
        ln -s $3/antRun antRun
    popd
    
    
    #if -makejar is specified, zip the plugin into a jar
    if [ "-makejar" = "$4" ]; then
    	cd ..
    	pluginName=`ls | grep org.apache.ant_`
    	zip -y -r ${pluginName}.jar ${pluginName}
    fi
    
popd
