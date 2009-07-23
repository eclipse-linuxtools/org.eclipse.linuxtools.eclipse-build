#!/bin/sh

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