#!/bin/sh

if `uname -m > /dev/null 2>&1`; then
	arch=`uname -m`
else
	arch=`uname -p`
fi

# Massage arch for Eclipse-uname differences
case ${arch} in
	arm*)
		arch=arm ;;
	i[0-9]*86)
		arch=x86 ;;
	ia64)
		arch=ia64 ;;
	mips*)
		if which dpkg-architecture >/dev/null 2>&1; then
			arch=`dpkg-architecture -qDEB_HOST_ARCH`
		fi ;;
	parisc*)
		arch=PA_RISC ;;
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
EXIT_CODE=$?
echo "Build log is available in build_${DATE}.log"
exit $?
