#! /bin/sh

fileName=eclipse-sourceBuild-srcIncluded-3.5M3.zip

if [ ! -f $fileName ] 
then
	wget "http://download.eclipse.org/eclipse/downloads/drops/S-3.5M3-200810301917/$fileName"
fi

unzip -q $fileName
