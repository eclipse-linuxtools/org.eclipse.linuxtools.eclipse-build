#! /bin/bash

# Copyright (C) 2013-2017, Red Hat, Inc.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html

# Prepare Eclipse Test Bundles

# The definiton of an Eclipse Test Bundle for our purposes is any packaged
# OSGi bundle containing a pom.xml with a packaging type of
# 'eclipse-test-plugin'

# Takes a single argument (absolute path of folder containing test bundles)

if [ ! $# -eq 1 ]; then
  echo "USAGE : $0 PATH/TO/BUNDLES/DIRECTORY"
  exit 1
fi

testBundleFolder=$1
echo 'Eclipse-BundleShape: dir' > MANIFEST.MF

for jar in `find ${testBundleFolder} -name "*.jar" | grep -v eclipse-tests`; do
  jarPomPath=`jar -tf ${jar} | grep 'pom.xml'`
  unzip -p ${jar} ${jarPomPath} | grep -q '<packaging>eclipse-test-plugin</packaging>'
  if [ $? -eq 0 ]; then
    jarPomPath=`jar -tf ${jar} | grep 'pom.xml'`
    bsname=`unzip -p ${jar} ${jarPomPath} | sed '/<parent>/,/<\/parent>/ d' | sed '/<build>/,/<\/build>/ d' | grep '<artifactId>' | sed 's/.*<artifactId>\(.*\)<\/artifactId>.*/\1/'`

    # Detect SWTBot Tests
    useSWTBot='false'
    unzip -p ${jar} META-INF/MANIFEST.MF | grep -q 'swtbot'
    if [ $? -eq 0 ]; then
       useSWTBot='true'
    fi

    # Find Test Product and Application
    testproduct=`unzip -p ${jar} ${jarPomPath} | grep '<product>' | sed 's/.*<product>\(.*\)<\/product>.*/\1/'`
    testapplication=`unzip -p ${jar} ${jarPomPath} | grep '<application>' | sed 's/.*<application>\(.*\)<\/application>.*/\1/'`

    # Check for explicit test class
    testclasses=$(unzip -p ${jar} ${jarPomPath} | grep '<testClass>' | sed 's/.*<testClass>\(.*\)<\/testClass>.*/\1/')
    if [ -z "$testclasses" ] ; then
      # Check for custom includes and excludes
      includepatterns=`unzip -p ${jar} ${jarPomPath} | sed -n '/<includes>/,/<\/includes>/p' | sed -n 's/.*<include>\(.*\)<\/include>.*/\1/p' | sed -e 's/\*\*/\*/' -e 's/\./\\\\./g' -e 's/\*/\.\*/g'`
      excludepatterns=`unzip -p ${jar} ${jarPomPath} | sed -n '/<excludes>/,/<\/excludes>/p' | sed -n 's/.*<exclude>\(.*\)<\/exclude>.*/\1/p' | sed -e 's/\*\*/\*/' -e 's/\./\\\\./g' -e 's/\*/\.\*/g'`
      # List of all non-inner classes
      allclasses="$(jar -tf ${jar} | grep '.class$' | grep -v '\$')"
      # Default includes, if custom includes are not specified
      if [ -z "$includepatterns" ] ; then
        includepatterns='.*/(Test.*\.class|.*Test\.class)'
        # Override and use the "all" classes instead, if one is detected and neither custom includes nor excludes are specified
        if [ -z "$excludepatterns" ] ; then
          allpattern='.*/AllTests\.class'
          all="$(echo "$allclasses" | grep -E "${allpattern}\$")"
          if [ -n "$all" ] ; then
            includepatterns='.*/AllTests\.class'
          fi
        fi
      fi
      # Trim list down using include and exclude patterns
      for pat in $includepatterns ; do
        testclasses="$testclasses $(echo "$allclasses" | grep -E "${pat}\$")"
      done
      for pat in $excludepatterns '.*/Abstract.*\.class' ; do
        testclasses="$(echo "$testclasses" | grep -vE "${pat}\$")"
      done
      # Convert to dotted class names
      testclasses="$(echo "$testclasses" | tr '/' '.' | sed 's/\.class//')"
    fi

    for testclass in ${testclasses} ; do
      sed -i "/<target name=\"linuxtoolsTests\">/ a \\
      <exec executable=\"\${basedir}/updateTestBundleXML.sh\"> \\
      <arg value=\"${bsname}\" /> \\
      <arg value=\"${testclass}\" /> \\
      <arg value=\"${testproduct}\" /> \\
      <arg value=\"${testapplication}\" /> \\
      <arg value=\"${useSWTBot}\" /> \\
      </exec> \\
      <runTests testPlugin=\"${bsname}\" testClass=\"${testclass}\" />" \
      target/test.xml
    done

    # Make 'Eclipse-BundleShape: dir'
    jarName=`basename ${jar}`
    symJarName=`ls target-sdk/plugins/ | grep ${jarName}`
    # Might be multiple symlinked jars providing same bundle (rare)
    for file in ${symJarName}; do
      rm target-sdk/plugins/${file}
    done
    cp ${jar} target-sdk/plugins/
    jar -umf ./MANIFEST.MF target-sdk/plugins/${jarName}

  fi
done

rm ./MANIFEST.MF

