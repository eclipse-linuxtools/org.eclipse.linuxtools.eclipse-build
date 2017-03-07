#! /bin/sh

# Copyright (C) 2013-2017, Red Hat, Inc.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html

set -e

sdk=$1
tests=$2

eclipse_archful=$(dirname $(readlink -f $(which eclipse) ))
eclipse_noarch=$(cd ${eclipse_archful}/../../share/eclipse && pwd)

mkdir -p $sdk/plugins $sdk/features
pushd $sdk >/dev/null

      (cd $tests;
	ls -d plugins/* features/* 2>/dev/null) |
      while read f; do
         [ ! -e $f ] && ln -s $tests/$f $f
      done
      (cd $eclipse_archful;
	ls -d plugins/* features/* 2>/dev/null) |
      while read f; do
         [ ! -e $f ] && ln -s $eclipse_archful/$f $f
      done
      (cd $eclipse_archful/droplets; ls -d * 2>/dev/null) |
      while read f; do
	  if [ -e $eclipse_archful/droplets/$f/eclipse ]; then
	      (cd $eclipse_archful/droplets/$f/eclipse;
				ls -d plugins/* features/* 2>/dev/null) |
	      while read g; do
		    ln -sf $eclipse_archful/droplets/$f/eclipse/$g $g
	      done
          else
	      (cd $eclipse_archful/droplets/$f;
				ls -d plugins/* features/* 2>/dev/null) |
	      while read g; do
		    ln -sf $eclipse_archful/droplets/$f/$g $g
	      done
          fi
      done
      (cd $eclipse_noarch/droplets; ls -d * 2>/dev/null) |
      while read f; do
	  if [ -e $eclipse_noarch/droplets/$f/eclipse ]; then
	      (cd $eclipse_noarch/droplets/$f/eclipse;
				ls -d plugins/* features/* 2>/dev/null) |
	      while read g; do
		    ln -sf $eclipse_noarch/droplets/$f/eclipse/$g $g
	      done
          else
	      (cd $eclipse_noarch/droplets/$f;
				ls -d plugins/* features/* 2>/dev/null) |
	      while read g; do
		    ln -sf $eclipse_noarch/droplets/$f/$g $g
	      done
          fi
      done

popd >/dev/null
