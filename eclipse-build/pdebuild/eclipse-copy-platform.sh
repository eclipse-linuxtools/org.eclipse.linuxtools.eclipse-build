#! /bin/sh

# We need to make our own copy of the eclipse platform in order to
# build against it.  We do this since the build root might already
# contain a copy of the plugin we are building -- and the eclipse
# releng scripts fail in this situation.  We put this script in the
# eclipse core so that it is easy to use from other spec files.

# Arguments are:
# * directory where results should end up (script will make it)
# * base location of eclipse platform install
# * an optional string that is used to select non-platform
#   plugins and features.  At present if a plugin or feature has
#   this as a substring, it will be included.  You need only run
#   this script once, it will link both the platform and the other
#   optionally-selected parts in a single invocation.

# Test to see if the minimum arguments
# are specified

if [ $# -lt 2 ]; then
  echo "Usage: copy-platform where eclipse_base optional_directories"
  echo "For example: copy-plaform ~/SDK /usr/lib/eclipse cdt pydev jdt"
  exit 1
fi

where=$1; shift
eclipse=$1; shift

datadir=/usr/share/eclipse

mkdir -p $where/plugins $where/features
cd $where

# Are there any optional arguments left?
if [ $# -gt 0 ]; then
   for optional in "$@"; do
      (cd $eclipse; ls -d plugins/*"$optional"* features/*"$optional"*) |
      while read f; do
         [ ! -e $f ] && ln -s $eclipse/$f $f
      done
      (cd $eclipse/dropins; ls -d *"$optional"*) |
      while read f; do
	  if [ -e $eclipse/dropins/$f/eclipse ]; then
	      (cd $eclipse/dropins/$f/eclipse; ls -d plugins/* features/*) |
	      while read g; do
		  [ ! -e $g ] && \
		    ln -s $eclipse/dropins/$f/eclipse/$g $g
	      done
          else
	      (cd $eclipse/dropins/$f; ls -d plugins/* features/*) |
	      while read g; do
	          [ ! -e $g ] && \
		    ln -s $eclipse/dropins/$f/$g $g
	      done
          fi
      done
      (cd $datadir/dropins; ls -d *"$optional"*) |
      while read f; do
	  if [ -e $datadir/dropins/$f/eclipse ]; then
	      (cd $datadir/dropins/$f/eclipse; ls -d plugins/* features/*) |
	      while read g; do
		  [ ! -e $g ] && \
		    ln -s $datadir/dropins/$f/eclipse/$g $g
	      done
          else
	      (cd $datadir/dropins/$f; ls -d plugins/* features/*) |
	      while read g; do
	          [ ! -e $g ] && \
		    ln -s $datadir/dropins/$g $g
	      done
          fi
      done
   done
fi

# Code after this point is automatically created by eclipse.spec.
