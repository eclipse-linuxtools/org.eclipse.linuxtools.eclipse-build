#!/bin/sh

# FIXME:  do we need to do these steps anymore?

#Prepare sources
#ant -f fetch.xml applyPatches

#Build ecj with system compiler
#cd SDK/jdtcoresrc
#ant -f compilejdtcorewithjavac.xml

#Build ecj with itself
#export CLASSPATH=ecj.jar
#ant -f compilejdtcore.xml

#Copy ecj jar to the base folder
#cd ../..
#rm -f ecj.jar
#cp SDK/ecj.jar ecj.jar

#Build Eclipse SDK with the built ecj
#export CLASSPATH=ecj.jar

if `uname -m > /dev/null 2>&1`; then
	echo "blah"
	arch=`uname -m`
	echo "blah"
else
	arch=`uname -p`
fi

# Massage arch for Eclipse-uname differences
case ${arch} in
	i[0-9]*86)
		arch=x86 ;;
	ia64)
		arch=ia64 ;;
	ppc)
		arch=ppc ;;
	x86_64)
		arch=x86_64 ;;
	*)
		echo "Unrecognized architecture:  $arch" 1>&2
		exit 1 ;;
esac

ant -DbuildArch=${arch}