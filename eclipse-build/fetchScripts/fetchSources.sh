###############################################################################
# Copyright (c) 2012 Red Hat, Inc. and others.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
#
# Contributors:
#     Red Hat, Inc. - initial API and implementation
###############################################################################


#!/bin/bash
set -e

#eg 3.8.0-I20320
BUILD_ID=4.2.0-20120404-byChris

MAPS_RELENG_GIT_URL=http://git.eclipse.org/gitroot/platform/eclipse.platform.releng.maps.git
MAPS_RELENG_TAG=R4_HEAD

# Small optimization: to do proper pull of existing repos.
# This branch should match the branch which will be pulled if repo already exists. 

PULL_BRANCH=master

ECLIPSE_ARCHIVE_NAME=eclipse-${BUILD_ID}-src
TESTS_ARCHIVE_NAME=eclipse-sdktests-${BUILD_ID}-src


# Orbit or other pre-built software
function processBinaryInstallableUnit {
    echo "Unit $processedLine will not be downloaded, and I cannot do anything with it yet"
}


function download {
   local target;
   if [[ "${processedLine[0]}" == feature* ]]
    then
      target="feature"
    else
      # fragments go here, too
      target="plugin"
   fi

  local type;
  if [[ "${processedLine[0]}" == *test* ]]
    then
      type=${TESTS_ARCHIVE_NAME}
    else
      # fragments go here, too
      type=${ECLIPSE_ARCHIVE_NAME}
   fi
  local name=${processedLine[0]//=GIT/}
  name=${name//feature@/}
  name=${name//plugin@/}
  name=${name//fragment@/}

  local tag=${processedLine[1]//tag=/}
  local repo=${processedLine[2]//repo=/}
  local clonedFolder=${repo//*\//}
  clonedFolder=${clonedFolder//.git/}
  local path=${processedLine[3]//path=/}

  cd temp/
    if [ ! -d $clonedFolder ]
      then
	git clone $repo
      else
	cd $clonedFolder
	git checkout $PULL_BRANCH --force
	git pull -f
	cd ..
    fi 
    cd $clonedFolder
      if [ -d $path ]; 
      then
	pushd $path 
	  git checkout $tag --force
	popd 
	mkdir -p ../../temp/$type/"${target}s"/
	cp -r $path ../../temp/$type/"${target}s"/
	echo "${name},0.0.0=${tag}" >> ../../temp/$type/"${target}Versions.properties"
	echo "${name},0.0.0=scm:git:${repo};path=\"${path}\";tag=${tag}" >> ../../temp/$type/"sourceReferences.properties"
      else
	echo "${path} not found!"
      fi
    cd ..
  cd ..
}

function processSingleMapLine {
  local -a processedLine
  processedLine=( `echo "$mapLine" | tr "," " "` )
  if [[ "${processedLine[0]}" ==  *=GIT ]]
  then
     download $processedLine
  else 
    processBinaryInstallableUnit $processedLine
  fi
}


function processMapFile {
    local _done=false
    sed '/^$\|^#.*\|^!.*/d' $mapFile | until $_done; do
      read || _done=true
      mapLine=$REPLY
      processSingleMapLine $mapLine;
    done
}



# Main

#clean up old source folders if they exist
rm -rf temp/${ECLIPSE_ARCHIVE_NAME}
rm -rf temp/${TESTS_ARCHIVE_NAME}

mkdir -p temp/${ECLIPSE_ARCHIVE_NAME}
mkdir -p temp/${TESTS_ARCHIVE_NAME}

# clone and update maps
git clone ${MAPS_RELENG_GIT_URL} || echo "Maps checked out, attempting to pull"
pushd eclipse.platform.releng.maps
  git pull -f
  git reset --hard
  git checkout ${MAPS_RELENG_TAG}
popd

# add fedora specific maps
cp fedora.map eclipse.platform.releng.maps/org.eclipse.releng/maps/

# process map files (download what should be downloaded)
ls eclipse.platform.releng.maps/org.eclipse.releng/maps/*.map | while read mapFile; do
  dos2unix $mapFile
  processMapFile $mapFile
done

# create some listings (they may be unnecessary, but Kim's script created them)
cat eclipse.platform.releng.maps/org.eclipse.releng/maps/*.map > temp/eclipse/directory.txt
cat eclipse.platform.releng.maps/org.eclipse.releng/maps/*.map > temp/tests/directory.txt

# create environments sources (for Fedora build)
pushd temp/${ECLIPSE_ARCHIVE_NAME}
  for f in \
        ee.foundation \
        ee.minimum-1.2.0 \
        ee.minimum \
        osgi.cmpn \
        osgi.core \
  ; do
    mkdir -p environments/$f/
    mkdir -p environments/temp
    cp plugins/org.eclipse.osgi/osgi/"$f.jar" environments/temp/
    pushd environments/temp/
      unzip "$f.jar"
    popd
    cp -rf environments/temp/{OSGI-OPT/src/,META-INF/,LICENSE,about.html} environments/$f/
    rm -rf environments/temp
  done
popd

# Remove files from the version control system
find -depth -name CVS -exec rm -rf {} \;


#Cleanup source code
pushd temp/${ECLIPSE_ARCHIVE_NAME}
  # Remove prebuilt binaries
  find \( -name '*.exe' -o -name '*.dll' \) -delete
  find -type f \( -name '*.so' -o -name '*.so.2' -o -name '*.a' \) -delete
  find \( -name '*.sl' -o -name '*.jnilib' \) -delete
  find features/org.eclipse.equinox.executable -name eclipse -delete
  find \( -name '*.cvsignore' \) -delete

  # Remove unnecessary feature and plugins
  rm -rf features/org.eclipse.sdk.examples
  rm -rf plugins/*.examples*

  # Remove binary JARs
  find -type f -name '*.jar' -delete

  # Remove temporary files
  find -name '*.orig' -delete

  # Remove empty directories
  find -type d -empty -delete
popd

tar cjf ${ECLIPSE_ARCHIVE_NAME}.tar.bz2 temp/${ECLIPSE_ARCHIVE_NAME}
tar cjf ${TESTS_ARCHIVE_NAME}.tar.bz2 temp/${TESTS_ARCHIVE_NAME}

rm -rf temp/${ECLIPSE_ARCHIVE_NAME} temp/${TESTS_ARCHIVE_NAME}