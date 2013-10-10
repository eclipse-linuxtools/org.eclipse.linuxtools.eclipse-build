#! /bin/sh

# Copyright (C) 2013, Red Hat, Inc.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html

prefix=$ROOT_PREFIX
sdk=$1'-sdk'
repo=$1

eclipse=$prefix$(rpm --eval '%{_libdir}')/eclipse

datadir=$prefix/usr/share/eclipse
javadir=$prefix/usr/share/java
jnidir=$prefix/usr/lib/java

mkdir -p $sdk/plugins $sdk/features
pushd $sdk

      (cd $eclipse;
	ls -d plugins/* features/* 2>/dev/null) |
      while read f; do
         [ ! -e $f ] && ln -s $eclipse/$f $f
      done
      (cd $eclipse/dropins; ls -d * 2>/dev/null) |
      while read f; do
	  if [ -e $eclipse/dropins/$f/eclipse ]; then
	      (cd $eclipse/dropins/$f/eclipse;
				ls -d plugins/* features/* 2>/dev/null) |
	      while read g; do
		  [ ! -e $g ] && \
		    ln -s $eclipse/dropins/$f/eclipse/$g $g
	      done
          else
	      (cd $eclipse/dropins/$f;
				ls -d plugins/* features/* 2>/dev/null) |
	      while read g; do
	          [ ! -e $g ] && \
		    ln -s $eclipse/dropins/$f/$g $g
	      done
          fi
      done
      (cd $datadir/dropins; ls -d * 2>/dev/null) |
      while read f; do
	  if [ -e $datadir/dropins/$f/eclipse ]; then
	      (cd $datadir/dropins/$f/eclipse;
				ls -d plugins/* features/* 2>/dev/null) |
	      while read g; do
		  [ ! -e $g ] && \
		    ln -s $datadir/dropins/$f/eclipse/$g $g
	      done
          else
	      (cd $datadir/dropins/$f;
				ls -d plugins/* features/* 2>/dev/null) |
	      while read g; do
	          [ ! -e $g ] && \
		    ln -s $datadir/dropins/$f/$g $g
	      done
          fi
      done

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

# jars in %%{_javadir} may not be uniquely named
id=1
for p in $(find $javadir -name "*.jar"); do
    unzip -p $p 'META-INF/MANIFEST.MF' | grep -q 'Bundle-SymbolicName'
    if [ $? = 0 ]; then
        plugin=${id}-$(basename $p)
        [ ! -e plugins/$plugin ] && ln -s $p plugins/$plugin
        id=$((${id} + 1))
    fi
done
id=1
for p in $(find $jnidir -name "*.jar"); do
    unzip -p $p 'META-INF/MANIFEST.MF' | grep -q 'Bundle-SymbolicName'
    if [ $? = 0 ]; then
        plugin=${id}-$(basename $p)
        [ ! -e plugins/$plugin ] && ln -s $p plugins/$plugin
        id=$((${id} + 1))
    fi
done

popd
