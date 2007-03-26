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
  echo "For example: copy-plaform ~/SDK /usr/share/eclipse cdt pydev jdt"
  exit 1
fi

where=$1; shift
eclipse=$1; shift

mkdir $where
cd $where
mkdir plugins features links 

# Are there any optional arguments left?
if [ $# -gt 0 ]; then
   for optional in "$@"; do
      (cd $eclipse; ls -d plugins/*"$optional"* features/*"$optional"*) |
      while read f; do
         ln -s $eclipse/$f $f
      done
   done
fi

# Code after this point is automatically created by eclipse.spec.
