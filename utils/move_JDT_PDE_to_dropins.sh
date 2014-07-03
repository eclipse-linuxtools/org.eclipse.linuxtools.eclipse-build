#!/bin/bash -x

# JDT and PDE are built as update sites.
# The procedure of moving them to dropins is following:
#
# Copy Eclipse installation
# Install JDT or PDE into it
# Copy the difference into dropins
#
# This must go this way to initialize all the plugins.
#
# Arguments:
#  1: path to the location of the materialised IDE product
#  2: path to a repository that contains the plug-ins
#  3: the IDs of the plug-ins that should be moved to dropins
#
# Base Eclipse installation is required to not have plug-ins installed.

LOCATION="${1}"
REPO="${2}"
PLUGINS="${3}"

pushd ${LOCATION}

backup_dir=eclipse

for p in $PLUGINS ; do

  # Take a backup of the installation
  old_dir="$backup_dir"
  backup_dir="$backup_dir-$p"
  cp -rf $old_dir $backup_dir

  # Install plug-in into backup dir
  pushd $backup_dir
    ./eclipse -application org.eclipse.equinox.p2.director -noSplash \
        -repository file:/${REPO} \
        -installIU org.eclipse.${p}.feature.group
  popd

  # Get the difference and copy all files into plug-in directory
  mkdir -p $p/plugins $p/features
  for i in $(ls $backup_dir/features) ; do
    if [ ! -e $old_dir/features/$i ] ; then
      cp -pr $backup_dir/features/$i $p/features
    fi
  done
  for i in $(ls $backup_dir/plugins) ; do
    if [ ! -e $old_dir/plugins/$i ] ; then
      cp -pr $backup_dir/plugins/$i $p/plugins
    fi
  done
done

# Move all plug-ins into dropins
cp -pr $PLUGINS eclipse/dropins
popd