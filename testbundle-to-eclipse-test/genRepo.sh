#! /bin/sh

# Copyright (C) 2013, Red Hat, Inc.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html

prefix=$ROOT_PREFIX
sdk=$1'-sdk'
repo=$1

java -jar $prefix/usr/lib*/eclipse/plugins/org.eclipse.equinox.launcher_*.jar -nosplash -application org.eclipse.equinox.p2.publisher.FeaturesAndBundlesPublisher \
-metadataRepository file:$repo \
-artifactRepository file:$repo \
-source $sdk \
-compress -append -publishArtifacts

rm -rf $sdk
