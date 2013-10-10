#! /bin/bash

# Copyright (C) 2013, Red Hat, Inc.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html

bsname=$1
classname=$2
useSWTBot=$3

sed -i "s/<property name=\"test-classname\" value=\".*\" \/>/<property name=\"test-classname\" value=\"${classname}\" \/>/" alltest.xml
sed -i "s/<property name=\"test-plugin-name\" value=\".*\" \/>/<property name=\"test-plugin-name\" value=\"${bsname}\" \/>/" alltest.xml
sed -i 's/<ant target=".*-test" antfile=".*"/<ant target="ui-test" antfile="\${library-file}"/' alltest.xml

if [ "${useSWTBot}" = 'true' ]; then
  sed -i 's/<ant target=".*-test" antfile=".*"/<ant target="swtbot-test" antfile="\${swtbot-library-file}"/' alltest.xml
fi
