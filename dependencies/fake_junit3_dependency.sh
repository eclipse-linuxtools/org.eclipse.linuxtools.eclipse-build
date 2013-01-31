#!/bin/bash

# Part of this file are following directories:
# .m2/p2/repo-sdk/plugins/org.junit

# Junit3 plugin is not a part of Fedora, so it needs to be created at build time.

# Usage:
# ./fake_junit3_dependency ${junit_plugin_folder} ${javadir} [-makejar]
# where
#    junit_plugin_folder - a plugin that will have content replaced with symlinks
#    javadir - main java folder, currently /usr/share/java
#	 -makejar - set if a jar should be created

pushd $1
	ln -s $2/junit.jar
    
    
    #if -makejar is specified, zip the plugin into a jar
    if [ "-makejar" = $3 ]; then
    	cd ..
    	pluginName=`ls | grep org.junit_`
    	zip -y -r ${pluginName}.jar ${pluginName}
    fi
    
popd
