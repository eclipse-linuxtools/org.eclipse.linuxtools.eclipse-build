#! /bin/sh

fileName=eclipse-sourceBuild-srcIncluded-3.5M4.zip

if [ ! -f $fileName ]
then
	wget "http://download.eclipse.org/eclipse/downloads/drops/S-3.5M4-200812111908/$fileName"
fi

rm -fr SDK
mkdir -p SDK
unzip -d SDK -q $fileName
