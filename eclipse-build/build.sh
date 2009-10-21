#!/bin/sh

if `uname -m > /dev/null 2>&1`; then
	arch=`uname -m`
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
	ppc64)
		arch=ppc64 ;;
	x86_64)
		arch=x86_64 ;;
	sparc)
		arch=sparc ;;
	sparcv9)
		arch=sparc ;;
	sparc64)
		arch=sparc64 ;;
	*)
		echo "Unrecognized architecture:  $arch" 1>&2
		exit 1 ;;
esac
DATE=`date +%Y%m%d%H%M%S`

ant -DbuildArch=${arch} 2>&1 | tee build_${DATE}.log
echo "Build log is available in build_${DATE}.log"
