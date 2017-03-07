#! /bin/bash

# Copyright (C) 2013, Red Hat, Inc.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html

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
sed -i '/<antcall target="quickTests" \/>/ a <antcall target="linuxtoolsTests" \/>' target/test.xml
sed -i '/<antcall target="quickTests" \/>/ d' target/test.xml
sed -i '/<antcall target="longRunningTests" \/>/ d' target/test.xml

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


sed -i 's/"-installIUs \(.*\)"/"-installIUs \1,org.eclipse.swtbot.eclipse.junit.headless"/' target/test.xml

eclipse_testing_dir=$(cd $(dirname $(readlink -f $(which eclipse)))/../../share/java/eclipse-testing && pwd)
cp $eclipse_testing_dir/testbundle/{swtbot-library.xml,alltest.xml,updateTestBundleXML.sh} target/
