#!/bin/sh

baseDir=$(pwd)
workDirectory=
eclipsebuildTag="0.5.0"

usage="usage:  <eclipse-build tag (ex. 0.5.0)> [-workdir <working directory>] [-eclipseBuildTag <eclipse-build tag to check out>]"

while [ $# -gt 0 ]
do
        case "$1" in
                -workdir) workDirectory="$2"; shift;;
                -workDir) workDirectory="$2"; shift;;
                -eclipseBuildTag) eclipsebuildTag="$2"; shift;;
                -eclipsebuildtag) eclipsebuildTag="$2"; shift;;
                -eclipsebuildTag) eclipsebuildTag="$2"; shift;;
                -help) echo $usage; exit 0;;
                --help) echo $usage; exit 0;;
                -h) echo $usage; exit 0;;
                *) eclipsebuildTag="$1";
        esac
        shift
done

if [ "x${workDirectory}x" = "xx" ]; then
  workDirectory=/tmp/eclipse-build
  echo "Working directory not set; using /tmp/eclipse-build."
fi

echo "Going to create source tarball for eclipse-build ${eclipsebuildTag}."

mkdir -p "${workDirectory}"
cd "${workDirectory}"
svn export svn://dev.eclipse.org/svnroot/technology/org.eclipse.linuxtools/eclipse-build/tags/${eclipsebuildTag}/eclipse-build
mv eclipse-build eclipse-build-${eclipsebuildTag}
cd eclipse-build-${eclipsebuildTag}
rm -rf .project .settings
svn export svn://dev.eclipse.org/svnroot/technology/org.eclipse.linuxtools/eclipse-build/tags/${eclipsebuildTag}/eclipse-build-config
svn export svn://dev.eclipse.org/svnroot/technology/org.eclipse.linuxtools/eclipse-build/tags/${eclipsebuildTag}/eclipse-build-feature
cd ..
tar caf eclipse-build-${eclipsebuildTag}.tar.bz2 eclipse-build-${eclipsebuildTag}
cd "${baseDir}"

echo "Built ${workDirectory}/eclipse-build-${eclipsebuildTag}.tar.bz2"
