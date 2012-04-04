#!/bin/bash
BUILD_ID=test

MAPS_RELENG_GIT_URL=http://git.eclipse.org/gitroot/platform/eclipse.platform.releng.maps.git
MAPS_RELENG_TAG=R4_HEAD


# Orbit or other pre-built software
function processBinaryInstallableUnit {
    echo "Unit $processedLine will not be downloaded, and I cannot do anything with it yet"
}


function download {
   echo "================ downloading ${processedLine[0]}"
   local target;
   if [[ "${processedLine[0]}" == feature* ]]
    then
      target="features"
    else
      # fragments go here, too
      target="plugins"
   fi

  local type;
  if [[ "${processedLine[0]}" == *test* ]]
    then
      type="tests"
    else
      # fragments go here, too
      type="eclipse"
   fi

  local tag=${processedLine[1]//tag=/}
  local repo=${processedLine[2]//repo=/}
  local clonedFolder=${repo//*\//}
  clonedFolder=${clonedFolder//.git/}
  local path=${processedLine[3]//path=/}

  pushd temp
    if [ ! -d $clonedFolder ]
      then
	git clone $repo
      else
	cd $clonedFolder
	git pull
	cd ..
    fi 
    pushd $clonedFolder
      pushd $path
	git checkout $tag
      popd
      mkdir -p ../../temp/$type/$target/
      cp -r $path ../../temp/$type/$target/
    popd
  popd
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

rm -rf temp
#rm -rf eclipse.platform.releng.maps

mkdir -p temp/eclipse
mkdir -p temp/tests

git clone ${MAPS_RELENG_GIT_URL}
pushd eclipse.platform.releng.maps
  git pull
  git checkout ${MAPS_RELENG_TAG}
popd

ls eclipse.platform.releng.maps/org.eclipse.releng/maps/*.map | while read mapFile; do
  dos2unix $mapFile
  processMapFile $mapFile
done
