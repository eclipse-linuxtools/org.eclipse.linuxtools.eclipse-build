#! /bin/bash

# Copyright (C) 2013, Red Hat, Inc.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html

mkdir target
pushd target

# Prepare testing environment
if [ ! -e /usr/share/java/eclipse-testing ]; then
  echo "/usr/share/java/eclipse-testing/ does not exist. Please install the package providing this location."
  exit 1
fi
cp -rp /usr/share/java/eclipse-testing/* ./

# Remove eclipse-tests p2 repo and generate for system
rm -rf features plugins content.jar artifacts.jar binary

# Create directory of all system OSGi bundles
# Do not create into p2 repo yet (we must make test bundles have dir shape)
../gatherBundles.sh $(pwd)

popd

# Prepare the test.xml file

sed -i 's/\${eclipse-home}\/plugins\/\${testPluginX}/\${testPluginX}/' target/test.xml
sed -i '/<fileset/,/<\/fileset>/ s/dir="\${eclipse-home}\/plugins"/dir="\${basedir}"/' target/test.xml
sed -i 's/refid="test.plugin.file" \/>/value="\${basedir}\/alltest.xml" \/>/' target/test.xml
sed -i 's/\${report}/\${testPlugin}/' target/test.xml

# Support multiple XML reports from same bundle but different test classes
sed -i '/<attribute name="testPlugin"/ a <attribute name="testClass" \/>'  target/test.xml
sed -i 's/@{testPlugin}\.xml/@{testPlugin}-@{testClass}\.xml/' target/test.xml
sed -i 's/\${testPlugin}\.xml/\${output-file}/' target/test.xml
sed -i 's/\${testPlugin}_\${platform}\.xml/\${output-file}/' target/test.xml

# Insert our test task
sed -i '/<antcall target="quickTests" \/>/ d' target/test.xml
sed -i '/<antcall target="longRunningTests" \/>/ d' target/test.xml
sed -i '/<target name="all">/ a <antcall target="linuxtoolsTests" \/>' target/test.xml

# A VERY dirty hack to mimic Tycho's improper usage of test bundle resources
sed -i '/<antcall target="configureTeamTest" \/>/ i \
<path id="testbundle.paths"> \
  <dirset \
  dir="\${eclipse-home}" \
  includes="plugins/\${testPlugin}_*" \/> \
<\/path> \
<property \
  name="testBundlePath" \
  refid="testbundle.paths" \/> \
<copy todir="\${eclipse-home}"> \
  <fileset dir="\${testBundlePath}" includes="**" \/> \
</copy>' target/test.xml


# Define our test task
sed -i '/<target name="quickTests">/ i \
<target name="linuxtoolsTests"> \
<!-- Copy over the XML to generate a top-level report for all of the tests --> \
    	    	<mkdir dir="\${results}\/origXml" \/> \
    			<xslt style="\${repoLocation}\/splitter.xsl" basedir="\${results}\/xml" includes="*.xml" destdir="\${results}\/origXml"\/> \
    	    	<!-- Aggregate XML report files --> \
    	    	<junitreport todir="\${results}\/xml" tofile="org.eclipse.sdk.tests.xml"> \
    	    		<fileset dir="\${results}/origXml" includes="*.xml" \/> \
    	    	<\/junitreport> \
    	    	<!-- Generate top-level HTML report --> \
    	    	<xslt style="\${repoLocation}\/JUNIT.XSL" basedir="\${results}\/xml" includes="org.eclipse.sdk.tests.xml" destdir="\${results}\/html" \/> \
<\/target>' target/test.xml

sed -i 's/"-installIUs \(.*\)"/"-installIUs \1,org.eclipse.swtbot.eclipse.junit.headless"/' target/test.xml

# Prepare the runtests.sh file
sed -i '/cp \${testslocation}\/\*\.properties/ a cp \${testslocation}\/{JUNIT.XSL,alltest.xml,updateTestBundleXML.sh,swtbot-library.xml} \.' target/runtests.sh
sed -i '/^properties=/ a testslocation=\$(pwd)' target/runtests.sh

# Do not print test properties (output is annoying)
sed -i '/echoproperties/d' target/library.xml

cp swtbot-library.xml alltest.xml updateTestBundleXML.sh target/
