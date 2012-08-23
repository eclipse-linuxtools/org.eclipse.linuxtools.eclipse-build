#!/bin/bash

# args:  [-f <feature>] [-d <dependencies (outside SDK)>] [-a <additional build args>] [-j <JVM args>] [-v] [-D] [-o <Orbit dependencies>]

function usage {
cat << _EOF_
usage: $0 [<options>]

Use PDE Build to build Eclipse features

Optional arguments:
   -h      Show this help message
   -f      Feature ID to build
   -d      Plugin dependencies in addition to Eclipse SDK
           (space-separated, names on which to glob features and plugins)
   -a      Additional build arguments (ex. -DjavacSource=1.5)
   -j      VM arguments (ex. -DJ2SE-1.5=%{_jvmdir}/java/jre/lib/rt.jar)
   -v      Be verbose
   -D      Debug platform itself (passes -consolelog -debug to Eclipse)
   -o      Directory containing Orbit-style dependencies
   -z      Comma-delimited list of dependency zips (not for use during RPM build)
_EOF_
}

function copyPlatform {
    # This seems silly but I was running into issues with empty strings
    # counting as arguments to copy-platform -- overholt, 2008-03
    if [ -z "$dependencies" ]; then
        if [ $verbose -eq 1 ]; then
            echo "/bin/sh -x $datadir/eclipse/buildscripts/copy-platform $SDK $datadir/eclipse"
            /bin/sh -x $datadir/eclipse/buildscripts/copy-platform $SDK $datadir/eclipse
        else
            echo "/bin/sh $datadir/eclipse/buildscripts/copy-platform $SDK $datadir/eclipse"
            /bin/sh $datadir/eclipse/buildscripts/copy-platform $SDK $datadir/eclipse
        fi
    else
        if [ $verbose -eq 1 ]; then
            echo "/bin/sh -x $datadir/eclipse/buildscripts/copy-platform $SDK $datadir/eclipse $dependencies"
            /bin/sh -x $datadir/eclipse/buildscripts/copy-platform $SDK $datadir/eclipse $dependencies
        else
            echo "/bin/sh $datadir/eclipse/buildscripts/copy-platform $SDK $datadir/eclipse $dependencies"
            /bin/sh $datadir/eclipse/buildscripts/copy-platform $SDK $datadir/eclipse $dependencies
        fi
    fi
}

function findFeatureId {
    # We can determine the feature ID if we have only one
    numFeatures=$(find $sourceDir -name feature.xml | wc -l)
    if [ $numFeatures -ne 1 ]; then
        #echo "# features found = $numFeatures"
        echo "Cannot determine feature ID.  Please specify with -f."
        usage
        exit 1
    fi
    
    featureXml=$(find $sourceDir -name feature.xml)
    
    # Taken from Ben Konrath's package-build
    # make an ant build files to extract the id from the feature.xml
    buildFile=$buildDir/findFeatureForRPM-tmp-build.xml
    
    echo "<project default=\"main\">
    	<target name=\"main\">
                   	<xmlproperty file=\"$featureXml\" collapseAttributes=\"true\"/>
    		<fail unless=\"feature.id\" message=\"feature.id not set\"/>
                   	<echo message=\"\${feature.id}\" />
            </target>
    </project>" > $buildFile
    
    featureId=$(ant -Dbasedir=$sourceDir -f $buildFile 2>&1 | grep echo | cut --delimiter=' ' -f 7)
    rm $buildFile
}

function findFeatureNameAndVersion {
    featureXml=$(find $sourceDir -name feature.xml | while read f; do grep -l id=\"$featureId\" $f; done)
    
    buildFile=$buildDir/findFeatureForRPM-tmp-build.xml
    
    echo "<project default=\"main\">
    	<target name=\"main\">
                   	<xmlproperty file=\"$featureXml\" collapseAttributes=\"true\"/>
    		<fail unless=\"feature.id\" message=\"feature.id not set\"/>
                   	<echo message=\"\${feature.label}\" />
            </target>
    </project>" > $buildFile
    
    featureName=$(ant -Dbasedir=$sourceDir -f $buildFile 2>&1 | grep echo | sed "s/.*\[echo\]\ //")
    rm $buildFile

    echo "<project default=\"main\">
    	<target name=\"main\">
                   	<xmlproperty file=\"$featureXml\" collapseAttributes=\"true\"/>
    		<fail unless=\"feature.id\" message=\"feature.id not set\"/>
                   	<echo message=\"\${feature.version}\" />
            </target>
    </project>" > $buildFile
    
    featureVersion=$(ant -Dbasedir=$sourceDir -f $buildFile 2>&1 | grep echo | sed "s/.*\[echo\]\ //")
    rm $buildFile
}

function findMaxBREE {
	manifests=$(find $sourceDir -name MANIFEST.MF)
	maxBree=1.4
	for i in $manifests; do
		breeLine=$(cat $i|grep RequiredExecutionEnvironment|cut -c37-|sed 's/^ *\(.*\) *$/\1/')
		case $breeLine in
         "J2SE-1.5")
         	 bree=1.5
             ;;
         "JavaSE-1.6")
         	 bree=1.6
             ;;
     	esac
     	if [ "$bree" \> "$maxBree" ]; then
     		maxBree=$bree
     	fi
    done
}

sourceDir=$PWD
buildDir=$PWD/build
SDK=$buildDir/SDK
homeDir=$buildDir/home
workspaceDir=$homeDir/workspace
datadir=`rpm --eval "%{_libdir}"`
pdeBuildDir=$datadir/eclipse/dropins/sdk/plugins/org.eclipse.pde.build_@PDEBUILDVERSION@

featureId=
dependencies=
additionalArgs=
vmArgs=
verbose=0
dryRun=0
debugPlatform=0
orbitDepsDir=
p2Generate=
testing=false
zipDeps=

# See above.  r = dry run (used for testing)
while getopts “hf:d:z:a:j:tvrDo:” OPTION
do
     case $OPTION in
         h)
             usage
             exit
             ;;
         f)
             featureId=$OPTARG
             ;;
         d)
             dependencies=$OPTARG
             ;;
         a)
             additionalArgs=$OPTARG
             ;;
         j)
             vmArgs=$OPTARG
             ;;
         t)
             testing=true
             ;;
         v)
             verbose=1
             ;;
         r)
             dryRun=1
             ;;
         D)
             debugPlatform=1
             ;;
         o)
             orbitDepsDir=$OPTARG
             ;;
         z)
             zipDeps=$OPTARG
             ;;
         ?)
             usage
             exit 1
             ;;
     esac
done

echo "mkdir -p $buildDir"
if [ $dryRun -ne 1 ]; then
    mkdir -p $buildDir
fi

# Eclipse may try to write to the building user's home directory so we create a
# temporary one for use by the build.
echo "mkdir -p $homeDir"
if [ $dryRun -ne 1 ]; then
    mkdir -p $homeDir
fi

echo "mkdir -p $workspaceDir"
if [ $dryRun -ne 1 ]; then
    mkdir -p $workspaceDir
fi

if [ -z $featureId ]; then
    findFeatureId
fi

if [ -z $featureId ]; then
    echo "Cannot determine feature ID.  Please specify with -f."
    usage
    exit 1
fi

findFeatureNameAndVersion

echo "Building feature = $featureId."

if [ -z "$dependencies" ]; then
    if [ $verbose -eq 1 ]; then
        echo "Assuming no dependencies except Eclipse SDK."
    fi
fi

# Symlink the SDK and dependencies for build
if [ -z "$dependencies" ]; then
    echo "Symlinking SDK into $SDK directory."
else
    echo "Symlinking SDK and \"$dependencies\" into $SDK directory."
fi
if [ $dryRun -ne 1 ]; then
    copyPlatform
fi

if [ $debugPlatform -eq 1 ]; then
    debugPlatformArgs="-debug -consolelog"
fi

if [ "x$orbitDepsDir" != "x" ]; then
    orbitDeps="-DorbitDepsDir=$orbitDepsDir"
fi

if [ "x$zipDeps" != "x" ]; then
    OLD_IFS="$IFS"
    IFS=","
    zipDepsArray=($zipDeps)
    IFS="$OLD_IFS"
    numZips=${#zipDepsArray[@]}
    for (( i=0; i< $numZips; i++ )); do
        thisZip=${zipDepsArray[$i]}
        thisFile=$(basename $thisZip)
        thisURL=$(echo $thisZip | sed s/$thisFile//)
        if [ ! -e $thisFile ]; then
            wget -q $thisZip
        fi
        mkdir -p tmp
        unzip -q -o $thisFile -d tmp
        cp -raf tmp/eclipse/features/* $SDK/features
        cp -raf tmp/eclipse/plugins/* $SDK/plugins
        rm -rf tmp
        thisZip=
        thisFile=
        thisURL=
    done
fi
if [ -z "$additionalArgs" ]; then
	findMaxBREE
	additionalArgs="-DjavacSource=$maxBree -DjavacTarget=$maxBree"
fi

echo "Starting build:"

launcherJar=$(ls $SDK/plugins | grep "org.eclipse.equinox.launcher_")

if [ $testing != true ]; then
  java -cp $SDK/plugins/${launcherJar} \
    -Duser.home=$homeDir \
    $vmArgs \
    org.eclipse.core.launcher.Main \
    -data $workspaceDir \
    -application org.eclipse.ant.core.antRunner \
    $debugPlatformArgs \
    -Dtype=feature \
    -Did=$featureId \
    -DbaseLocation=$SDK \
    -DsourceDirectory=$sourceDir \
    -DbuildDirectory=$buildDir \
    -Dbuilder=$datadir/eclipse/dropins/sdk/plugins/org.eclipse.pde.build_@PDEBUILDVERSION@/templates/package-build \
    $orbitDeps \
    -Dtesting="$testing" \
    $additionalArgs \
    -f $pdeBuildDir/scripts/build.xml
else
  echo "\
  java -cp $SDK/plugins/${launcherJar} \
    -Duser.home=$homeDir \
    $vmArgs \
    org.eclipse.core.launcher.Main \
    -data $workspaceDir \
    -application org.eclipse.ant.core.antRunner \
    $debugPlatformArgs \
    -Dtype=feature \
    -Did=$featureId \
    -DbaseLocation=$SDK \
    -DsourceDirectory=$sourceDir \
    -DbuildDirectory=$buildDir \
    -Dbuilder=$datadir/eclipse/dropins/sdk/plugins/org.eclipse.pde.build_@PDEBUILDVERSION@/templates/package-build \
    $orbitDeps \
    -Dtesting=\"$testing\" \
    $additionalArgs \
    -f $pdeBuildDir/scripts/build.xml
  "
fi

exit $?
