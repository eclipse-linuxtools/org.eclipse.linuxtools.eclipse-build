#!/bin/bash
BUILD_ID=test

MAPS_RELENG_GIT_URL=http://git.eclipse.org/gitroot/platform/eclipse.platform.releng.maps.git
MAPS_RELENG_TAG=R4_HEAD
# Small optimization: to do proper pull of existing repos
PULL_BRANCH=master


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
      type="tests"
    else
      # fragments go here, too
      type="eclipse"
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
      pushd $path >/dev/null
	git checkout $tag --force
      popd >/dev/null
      mkdir -p ../../temp/$type/"${target}s"/
      cp -r $path ../../temp/$type/"${target}s"/
      echo "${name},0.0.0=${tag}" >> ../../temp/$type/"${target}Versions.properties"
      echo "${name},0.0.0=scm:git:${repo};path=\"${path}\";tag=${tag}" >> ../../temp/$type/"sourceReferences.properties"
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

rm -rf temp/eclipse
rm -rf temp/tests
#rm -rf eclipse.platform.releng.maps

mkdir -p temp/eclipse
mkdir -p temp/tests

git clone ${MAPS_RELENG_GIT_URL}
pushd eclipse.platform.releng.maps
  git pull -f
  git checkout ${MAPS_RELENG_TAG}
popd

ls eclipse.platform.releng.maps/org.eclipse.releng/maps/*.map | while read mapFile; do
  dos2unix $mapFile
  processMapFile $mapFile
done

cat eclipse.platform.releng.maps/org.eclipse.releng/maps/*.map > temp/eclipse/directory.txt
cat eclipse.platform.releng.maps/org.eclipse.releng/maps/*.map > temp/tests/directory.txt
