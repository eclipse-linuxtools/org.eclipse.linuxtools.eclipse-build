#!/bin/sh

baseDir=$(pwd)
workDirectory=
eclipsebuildTag="master"

usage="usage:  <eclipse-build tag (ex. 0.7.0)> [-workdir <working directory>] [-eclipseBuildTag <eclipse-build tag to check out>]"

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

mkdir "${workDirectory}"
cd "${workDirectory}"
git clone git://git.eclipse.org/gitroot/linuxtools/org.eclipse.linuxtools.eclipse-build.git .
cd "${workDirectory}"
git archive --format=tar --prefix=eclipse-build-${eclipsebuildTag}/ ${eclipsebuildTag} | gzip >eclipse-build-${eclipsebuildTag}-tmp.tar.gz 
tar -xf eclipse-build-${eclipsebuildTag}-tmp.tar.gz
cd eclipse-build-${eclipsebuildTag}
mv eclipse-build eclipse-build-${eclipsebuildTag}
rm -rf .project .settings
mv -f eclipse-build-config eclipse-build-${eclipsebuildTag}
mv -f eclipse-build-feature eclipse-build-${eclipsebuildTag}
mv -f eclipse-build-${eclipsebuildTag}/* .
rm -fr eclipse-build-${eclipsebuildTag}
cd ..


tar caf eclipse-build-${eclipsebuildTag}.tar.xz eclipse-build-${eclipsebuildTag}
cd "${baseDir}"

echo "Built ${workDirectory}/eclipse-build-${eclipsebuildTag}.tar.xz"
