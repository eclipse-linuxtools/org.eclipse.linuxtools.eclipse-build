#! /bin/sh

# Copyright (C) 2017, Red Hat, Inc.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html

set -e

tests=$1

function collect_ius() {
  local ius=
  local dep=
  local dep_id=
  local dep_type=
  for dep in $(sed -n "/<$2>/,/<\/$2>/ p" $1 | grep "\(<$3>\|<type>\)") ; do
    if echo "$dep" | grep -q '<type>' ; then
      dep_type=$(echo "$dep" | sed -e 's/.*<type>\(.*\)<\/type>.*/\1/')
    fi
    if echo "$dep" | grep -q '<id>' ; then
      dep_id=$(echo "$dep" | sed -e "s/.*<$3>\(.*\)<\/$3>.*/\1/")
    fi
    if [ -n "$dep_id" -a -n "$dep_type" ] ; then
      if [ "$dep_type" = "eclipse-feature" ] ; then
        dep_id="${dep_id}.feature.group"
      fi
      if [ -z "$ius" ] ; then
        ius="$dep_id"
      else
        ius="$ius,$dep_id"
      fi
      dep_id=
      dep_type=
    fi
  done
  echo "$ius"
}

for plugin in $(ls $tests/plugins) ; do
  # Find location of the pom.xml inside the bundle, then extract from jar if necessary
  bundle=$tests/plugins/$plugin
  pomPath=
  if [ -d "$bundle" ] ; then
    pomPath="$(find $bundle/META-INF -name pom.xml)"
  else
    pomPathJar="$(jar -tf $bundle | grep 'pom.xml$' || :)"
    if [ -n "$pomPathJar" ] ; then
      unzip -p $bundle $pomPathJar > /tmp/temp-pom.xml
      pomPath="/tmp/temp-pom.xml"
    fi
  fi

  # If the bundle has no pom, we can't do anything
  if [ -z "$pomPath" ] ; then
    continue
  fi

  extraIUs=

  # Calulate extra IUs from "target-platform-configuration" plugin
  if grep -q '<packaging>eclipse-test-plugin</packaging>' $pomPath && grep -q '<artifactId>target-platform-configuration</artifactId>' $pomPath ; then
    extraReqs=$(collect_ius $pomPath requirement id)
    extraIUs=$extraReqs
  fi

  # Calulate extra IUs from "tycho-surefire-plugin" plugin
  if grep -q '<packaging>eclipse-test-plugin</packaging>' $pomPath && grep -q '<artifactId>tycho-surefire-plugin</artifactId>' $pomPath ; then
    extraDeps=$(collect_ius $pomPath dependency artifactId)
    if [ -z "$extraIUs" ] ; then
      extraIUs=$extraDeps
    else
      if [ -n "$extraDeps" ] ; then
        extraIUs="$extraIUs,$extraDeps"
      fi
    fi
  fi

  # Amend test.xml if additional IUs are needed for this test bundle
  if [ -n "$extraIUs" ] ; then
    bundleID=$(echo $(basename $bundle) | rev | cut -d_ -f1 --complement | rev)
    sed -i -e "/<antcall target=\"setupRepo\" \/>/ i\ \ \ \ <condition property=\"extraIU\" value=\"$extraIUs\">\n\ \ \ \ \ \ <equals arg1=\"\${testPlugin}\" arg2=\"$bundleID\" \/>\n\ \ \ \ <\/condition>" target/test.xml
  fi

  rm -f /tmp/temp-pom.xml
done

