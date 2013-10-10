#! /bin/bash

# Copyright (C) 2013, Red Hat, Inc.
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

extraIUs=

for jar in `find ${testBundleFolder} -name "*.jar"`; do
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

    # Find Test class(es)
    includepatterns=
    testclasses=
    testclass=`unzip -p ${jar} ${jarPomPath} | grep '<testClass>' | sed 's/.*<testClass>\(.*\)<\/testClass>.*/\1/'`
    if [ "${testclass}" = '' ]; then
      # Check for custom includes
      includepatterns=`unzip -p ${jar} ${jarPomPath} | sed -n '/<includes>/,/<\/includes>/p' | sed -n 's/.*<include>\(.*\)<\/include>.*/\1/p' | sed 's/\*\*/\.\*/'`
      for pat in ${includepatterns}; do
        testclasses="${testclasses} `jar -tf ${jar} | grep -E "${pat}" | grep '.class' | grep -v '\\$' | tr '/' '.' | sed 's/\.class//'`"
      done
      if [ "${includepatterns}" = '' ]; then
        testclass=`jar -tf ${jar} | grep '/AllTests.class' | tr '/' '.' | sed 's/\.class//'`
      fi
    fi
    if [ "${testclass}" = '' ]; then
      if [ "${includepatterns}" = '' ]; then
        # Use default includes
        testclasses=`jar -tf ${jar} | grep -E '/(Test.*\.class|.*Test\.class)' | grep -vE '/(Abstract.*\.class|.*Abstract\.class)' | grep -v '\\$' | tr '/' '.' | sed 's/\.class//'`
      fi
    else
      testclasses="${testclass}"
    fi

    for testclass in ${testclasses} ; do
      sed -i "/<target name=\"linuxtoolsTests\">/ a \\
      <exec executable=\"\${basedir}/updateTestBundleXML.sh\"> \\
      <arg value=\"${bsname}\" /> \\
      <arg value=\"${testclass}\" /> \\
      <arg value=\"${useSWTBot}\" /> \\
      </exec> \\
      <runTests testPlugin=\"${bsname}\" testClass=\"${testclass}\" />" \
      target/test.xml
    done

    # Collect any extra IUs from each test bundle's tycho-surefire-plugin
    unzip -p ${jar} ${jarPomPath} | grep -q '<artifactId>tycho-surefire-plugin<\/artifactId>'
    if [ $? -eq 0 ]; then
      IUList=`unzip -p ${jar} ${jarPomPath} | sed -n '/<dependency>/,/<\/dependency>/ p' | grep -B 1 '<artifactId>'`
      isFeature=0
      for elem in ${IUList}; do
        echo ${elem} | grep -q '<type>eclipse-feature<\/type>'
        if [ $? -eq 0 ]; then
          isFeature=1
        fi
        echo ${elem} | grep -q '<artifactId>'
        if [ $? -eq 0 ]; then
          extraIU=`echo ${elem} | sed 's/.*<artifactId>\(.*\)<\/artifactId>.*/\1/'`
          if [ ${isFeature} -eq 1 ]; then
            extraIU=${extraIU}'.feature.group'
          fi
          extraIUs="${extraIUs} ${extraIU}"
          isFeature=0
        fi
      done
    fi
    
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

# Always install the extra IUs
# Not by choice but because this is easier to do
extraIUs=`echo -n ${extraIUs} | tr ' ' '\n' | sort | uniq | tr '\n' ','`
sed -i "s/\"-installIUs \(.*\)\"/\"-installIUs \1,${extraIUs}\"/" target/test.xml

rm ./MANIFEST.MF
pushd target
../genRepo.sh $(pwd)
