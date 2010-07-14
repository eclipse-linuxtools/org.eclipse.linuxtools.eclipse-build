#!/bin/sh
#
# Extracts the libswt bundle from extracted org.eclipse.ogsi/bundles/ wasteland.
#
# usage: swt_bundle.sh <from> <to>
# Where <from> and <to> are the "root" of the "package dir".
#
#   swt_bundle.sh debian/eclipse-rcp debian/libswt-gtk-3.5-jni
#
# This would move
#      debian/eclipse-rcp/usr/lib/eclipse/configuration/org.eclipse.osgi/bundles/${swt_bundle}/
#  to
#      debian/libswt-gtk-3.5-jni/usr/lib/eclipse/configuration/org.eclipse.osgi/bundles/${swt_bundle}/
#

# Fail on first error.
set -e

FROM_PATH="$1"
TO_PATH="$2"
# allow special prefix and libdir.
# We just add a / to ensure it ends with a slash. 
# We also remove existing trailing slashes to "prettify" the path.
prefix=`echo "$3" | sed "s@/*\\$@@"`/
libdir=`echo "$4" | sed "s@/*\\$@@"`/

BUNDLES_PATH=`echo "${prefix}${libdir}eclipse/configuration/org.eclipse.osgi/bundles" | sed "s@^/*@@"`

# Check the variables and that the from path exists.
if [ "x$FROM_PATH" = x -o "x$TO_PATH" = x -o ! -d "$FROM_PATH" ] ; then
    echo "Missing from/to path or from is not a dir." >&2
    echo "FROM_PATH: ${FROM_PATH}" >&2
    echo "TO_PATH: ${TO_PATH}" >&2
    exit 1
fi

BUNDLE_ID=`ls "${FROM_PATH}/${BUNDLES_PATH}"/*/*/.cp/libswt-gtk-*.so | perl -ne 'print "$1\n" if(m@/bundles/(\d+)/@);'`

if [ "x$BUNDLE_ID" = x ] ; then
    echo "Cannot find swt's bundle ID please check the paths are correct." >&2
    echo "From: ${FROM_PATH}/${BUNDLES_PATH}" >&2
    echo "To: ${TO_PATH}/${BUNDLES_PATH}" >&2
    exit 1
fi

# Create the base path if it does not exists.
test -d "${TO_PATH}/${BUNDLES_PATH}" || mkdir -p "${TO_PATH}/${BUNDLES_PATH}"

mv "${FROM_PATH}/${BUNDLES_PATH}/${BUNDLE_ID}" "${TO_PATH}/${BUNDLES_PATH}/"
