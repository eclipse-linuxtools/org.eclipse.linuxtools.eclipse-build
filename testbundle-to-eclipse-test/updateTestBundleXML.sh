#! /bin/bash

# Copyright (C) 2013, Red Hat, Inc.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html

bsname=$1
classname=$2
product=$3
application=$4
useSWTBot=$5

sed -i "s/<property name=\"test-classname\" value=\".*\" \/>/<property name=\"test-classname\" value=\"${classname}\" \/>/" alltest.xml
sed -i "s/<property name=\"test-plugin-name\" value=\".*\" \/>/<property name=\"test-plugin-name\" value=\"${bsname}\" \/>/" alltest.xml
sed -i "s/<property name=\"test-product\" value=\".*\" \/>/<property name=\"test-product\" value=\"${product}\" \/>/" alltest.xml
sed -i "s/<property name=\"test-application\" value=\".*\" \/>/<property name=\"test-application\" value=\"${application}\" \/>/" alltest.xml
sed -i 's/<ant target=".*-test" antfile=".*"/<ant target="ui-test" antfile="\${library-file}"/' alltest.xml

if [ "${useSWTBot}" = 'true' ]; then
  sed -i 's/<ant target=".*-test" antfile=".*"/<ant target="swtbot-test" antfile="\${swtbot-library-file}"/' alltest.xml
fi

if [ -z "$product" ] ; then
  sed -i "/<property name=\"testProduct\"/d" alltest.xml
else
  sed -i "/<property name=\"plugin-name\"/i<property name=\"testProduct\" value=\"\${test-product}\" />" alltest.xml
fi
if [ -z "$application" ] ; then
  sed -i "/<property name=\"testApplication\"/d" alltest.xml
else
  sed -i "/<property name=\"plugin-name\"/i<property name=\"testApplication\" value=\"\${test-application}\" />" alltest.xml
fi
