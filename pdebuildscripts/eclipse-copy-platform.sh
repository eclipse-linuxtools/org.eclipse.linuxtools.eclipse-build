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

function symlinkInternal () {
(cd $eclipse/$1; ls -d "$optional" 2>/dev/null) |
      while read f; do
	  if [ -e $eclipse/$1/$f/eclipse ]; then
	      (cd $eclipse/$1/$f/eclipse;
				ls -d plugins/* features/* 2>/dev/null) |
	      while read g; do
		  [ ! -e $g ] && \
		    ln -s $eclipse/$1/$f/eclipse/$g $g
	      done
          else
	      (cd $eclipse/$1/$f;
				ls -d plugins/* features/* 2>/dev/null) |
	      while read g; do
	          [ ! -e $g ] && \
		    ln -s $eclipse/$1/$f/$g $g
	      done
          fi
      done
      (cd $datadir/$1; ls -d "$optional" 2>/dev/null) |
      while read f; do
	  if [ -e $datadir/$1/$f/eclipse ]; then
	      (cd $datadir/$1/$f/eclipse;
				ls -d plugins/* features/* 2>/dev/null) |
	      while read g; do
		  [ ! -e $g ] && \
		    ln -s $datadir/$1/$f/eclipse/$g $g
	      done
          else
	      (cd $datadir/$1/$f;
				ls -d plugins/* features/* 2>/dev/null) |
	      while read g; do
	          [ ! -e $g ] && \
		    ln -s $datadir/$1/$g $g
	      done
          fi
      done
}

if [ $# -lt 2 ]; then
  echo "Usage: copy-platform where eclipse_base optional_directories"
  echo "For example: copy-plaform ~/SDK /usr/lib/eclipse cdt pydev jdt"
  exit 1
fi

where=$1; shift
eclipse=$1; shift

datadir=@DATADIR@/eclipse

mkdir -p $where/plugins $where/features
cd $where

# Are there any optional arguments left?
if [ $# -gt 0 ]; then
   for optional in "$@"; do
      (cd $eclipse;
	ls -d plugins/*"$optional"* features/*"$optional"* 2>/dev/null) |
      while read f; do
         [ ! -e $f ] && ln -s $eclipse/$f $f
      done
   symlinkInternal dropins
   symlinkInternal droplets
   done
fi
for p in $(ls -d $eclipse/dropins/jdt/plugins/*); do
    plugin=$(basename $p)
    [ ! -e plugins/$plugin ] && ln -s $eclipse/dropins/jdt/plugins/$plugin plugins/$plugin
done
for f in $(ls -d $eclipse/dropins/jdt/features/*); do
    feature=$(basename $f)
    [ ! -e features/$feature ] && ln -s $eclipse/dropins/jdt/features/$feature features/$feature
done
for p in $(ls -d $eclipse/dropins/sdk/plugins/*); do
    plugin=$(basename $p)
    [ ! -e plugins/$plugin ] && ln -s $eclipse/dropins/sdk/plugins/$plugin plugins/$plugin
done
for f in $(ls -d $eclipse/dropins/sdk/features/*); do
    feature=$(basename $f)
    [ ! -e features/$feature ] && ln -s $eclipse/dropins/sdk/features/$feature features/$feature
done
for p in $(ls -d $eclipse/plugins/*); do
    plugin=$(basename $p)
    [ ! -e plugins/$plugin ] && ln -s $eclipse/plugins/$plugin plugins/$plugin
done
for f in $(ls -d $eclipse/features/*); do
    feature=$(basename $f)
    [ ! -e features/$feature ] && ln -s $eclipse/features/$feature features/$feature
done
