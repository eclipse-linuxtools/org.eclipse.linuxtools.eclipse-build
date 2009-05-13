#!/bin/sh

#Prepare sources
ant -f fetch.xml applyPatches

#Build ecj with system compiler
cd SDK/jdtcoresrc
ant -f compilejdtcorewithjavac.xml

#Build ecj with itself
export CLASSPATH=ecj.jar
ant -f compilejdtcore.xml

#Copy ecj jar to the base folder
cd ../..
cp SDK/ecj.jar ecj.jar

#Build Eclipse SDK with the builded ecj
export CLASSPATH=ecj.jar
ant