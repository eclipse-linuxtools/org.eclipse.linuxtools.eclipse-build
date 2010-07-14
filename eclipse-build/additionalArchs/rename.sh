#!/bin/bash

newArch=$1

moves(){
for f in $(find -type d); do
      tofile=$(echo $f | sed "s/ppc/$newArch/")
      if [ $tofile != $f ]; then
        cp -pfr $f $tofile
      fi
    done
for f in $(find -type f); do
      tofile=$(echo $f | sed "s/ppc/$newArch/")
      if [ $tofile != $f ]; then
        cp -pfr $f $tofile
        rm -fr $f
      fi
    done
}

cd org.eclipse.equinox.launcher.gtk.linux.$newArch
    moves
cd ..
cd org.eclipse.core.filesystem.linux.$newArch
    moves
cd ..
cd org.eclipse.swt.gtk.linux.$newArch
    moves
cd ..