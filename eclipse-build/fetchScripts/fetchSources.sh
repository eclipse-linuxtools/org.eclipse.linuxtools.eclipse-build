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
BUILD_ID=4.2.0-I20120608-1400
MAPS_RELENG_TAG=R4_2

MAPS_RELENG_GIT_URL=http://git.eclipse.org/gitroot/platform/eclipse.platform.releng.maps.git

ECLIPSE_ARCHIVE_NAME=eclipse-${BUILD_ID}-src
TESTS_ARCHIVE_NAME=eclipse-sdktests-${BUILD_ID}-src


# Orbit or other pre-built software
function processBinaryInstallableUnit {
    echo "$processedLine" >> temp/$ECLIPSE_ARCHIVE_NAME/could-not-download.txt
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
      type=${ECLIPSE_ARCHIVE_NAME}
   fi
  local name=${processedLine[0]//=GIT/}
  name=${name//feature@/}
  name=${name//plugin@/}
  name=${name//fragment@/}
  name=${name//bundle@/}

  local tag=${processedLine[1]//tag=/}
  local repo=${processedLine[2]//repo=/}
  
  local clonedFolder=${repo//*\//}
  clonedFolder=${clonedFolder//.git/}
  local path=${processedLine[3]//path=/}

  echo "REPO = ${repo}"
  echo "clonedFolder = ${clonedFolder}"
  echo "path = ${path}"
  echo "Tag = ${tag}"

  cd temp/
    if [ ! -d $clonedFolder ]
      then
	git clone $repo
    fi 
    cd $clonedFolder
	git checkout --force $tag 
	mkdir -p ../../temp/$type/"${target}s"/${name}
	echo "Copying $path/* or ${path//-feature/}/* into temp/$type/"${target}s"/${name}"
	cp -r $path/* ../../temp/$type/"${target}s"/${name} || cp -r ${path//-feature/}/* ../../temp/$type/"${target}s"/${name}
	echo "${name//_3.0.0/},0.0.0=${tag}" >> ../../temp/$type/"${target}Versions.properties"
	echo "${name},0.0.0=scm:git:${repo};path=\"${path}\";tag=${tag}" >> ../../temp/$type/"sourceReferences.properties"
    cd ..
  cd ..
}


function downloadCVS {
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
      type=${ECLIPSE_ARCHIVE_NAME}
  fi

  local name=${processedLine[0]//=CVS/}
  name=${name//feature@/}
  name=${name//plugin@/}
  name=${name//fragment@/}
  name=${name//bundle@/}

  local tag=${processedLine[1]//*=/}
  local version=${processedLine[1]//=*/}
  local repo=${processedLine[2]//repo=/}
  
  local clonedFolder=${repo}
  local path=${processedLine[3]}

  echo "REPO = ${repo}"
  echo "path = ${path}"

  cd temp/
      cvs -d $repo checkout -r $tag $path
      mkdir -p ${type}/${target}s/${name}_${version}.${tag}
      cp -rf $path/* ${type}/${target}s/${name}_${version}.${tag}
      if [ ${name} != org.junit ]; then
	echo "${name},${version}=${tag}" >> $type/"${target}Versions.properties"
      fi
  cd ..
}

function processSingleMapLine {
  local -a processedLine
  processedLine=( `echo "$mapLine" | tr "," " "` )
  if [[ "${processedLine[0]}" ==  *=GIT ]]
  then
    if ( [[ "${processedLine[0]}" != fragment@org.eclipse.core.resources.win32=GIT ]] \
      && [[ "${processedLine[0]}" != plugin@org.eclipse.test.dispatcher=GIT ]]  \
      && [[ "${processedLine[0]}" != fragment@org.eclipse.ui.cocoa=GIT ]] )
      then
	#regular plugin@org.eclipse.equinox.event=GIT,tag=v20111010-1614,repo=git://git.eclipse.org/gitroot/equinox/rt.equinox.bundles.git,path=bundles/org.eclipse.equinox.event
	download $processedLine
      else
	echo "Skipping ${processedLine[0]}".
    fi
  elif [[ "${processedLine[1]}" == *=GIT ]]; then
	#special case where plugin@org.eclipse.equinox.http.jetty,3.0.0=GIT,tag=v20120216-2249,repo=git://git.eclipse.org/gitroot/equinox/rt.equinox.bundles.git,path=bundles/org.eclipse.equinox.http.jetty8
	processedLine=( "${processedLine[0]}_${processedLine[1]//=GIT/}" "${processedLine[2]}" "${processedLine[3]}" "${processedLine[4]}" )
	download $processedLine
  elif [[ "${processedLine[0]}" ==  *=CVS ]]; then
	downloadCVS $processedLine
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
git clone ${MAPS_RELENG_GIT_URL} || echo "Maps already checked out"
pushd eclipse.platform.releng.maps
  git checkout ${MAPS_RELENG_TAG}
popd

# add fedora specific maps
cp additionalBundles.map eclipse.platform.releng.maps/org.eclipse.releng/maps/

# process map files (download what should be downloaded)
ls eclipse.platform.releng.maps/org.eclipse.releng/maps/*.map | while read mapFile; do
  processMapFile $mapFile
done

# create some listings (they may be unnecessary, but Kim's script created them)
cat eclipse.platform.releng.maps/org.eclipse.releng/maps/*.map > temp/${ECLIPSE_ARCHIVE_NAME}/directory.txt
cat eclipse.platform.releng.maps/org.eclipse.releng/maps/*.map > temp/${TESTS_ARCHIVE_NAME}/directory.txt

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

#Cleanup source code
pushd temp/${ECLIPSE_ARCHIVE_NAME}
  # Extract osgi.util src for rebuilding
  pushd plugins/org.eclipse.osgi.util
  if [ -e src.zip ]; then
    unzip -q -d src src.zip
    # Remove pre-compiled class files and the source.zip
    rm -r org/ src.zip
  fi
  popd

  # Extract osgi.services src for rebuilding
  pushd plugins/org.eclipse.osgi.services
    if [ -e src.zip ]; then
      unzip -q -d src src.zip
      # Remove pre-compiled class files and the source.zip
      rm -r org/ src.zip
    fi
  popd

  # Remove sources for service.io
  pushd plugins
    rm -rf org.eclipse.equinox.io
    rm -rf org.eclipse.osgi.services/src/org/osgi/service/io/
  popd

  # Remove files from the version control system
  find -depth -name CVS -exec rm -rf {} \;  
  
  # Remove prebuilt binaries
  find \( -name '*.exe' -o -name '*.dll' \) -delete
  find -type f \( -name '*.so' -o -name '*.so.2' -o -name '*.a' \) -delete
  find \( -name '*.sl' -o -name '*.jnilib' \) -delete
  find features/org.eclipse.equinox.executable -name eclipse -delete
  find \( -name '*.cvsignore' \) -delete

  # Remove unnecessary feature and plugins
  #rm -rf features/org.eclipse.sdk.examples
  #rm -rf plugins/*.examples*

  # Remove binary JARs and classes
  find -type f -name '*.class' -delete
  find -type f -name '*.jar' -delete

  # Remove temporary files
  find -name '*.orig' -delete

  # Remove empty directories
  find -type d -empty -delete
popd

# Add maps
mkdir -p temp/${ECLIPSE_ARCHIVE_NAME}/maps
pushd temp/${ECLIPSE_ARCHIVE_NAME}/maps
tar cf maps.tar ../../../eclipse.platform.releng.maps/org.eclipse.releng
popd

cd temp/
tar cjf ${ECLIPSE_ARCHIVE_NAME}.tar.bz2 ${ECLIPSE_ARCHIVE_NAME}
tar cjf ${TESTS_ARCHIVE_NAME}.tar.bz2 ${TESTS_ARCHIVE_NAME}
mv -f ${ECLIPSE_ARCHIVE_NAME}.tar.bz2 ${TESTS_ARCHIVE_NAME}.tar.bz2 ../
cd ..


rm -rf temp/${ECLIPSE_ARCHIVE_NAME} temp/${TESTS_ARCHIVE_NAME}
