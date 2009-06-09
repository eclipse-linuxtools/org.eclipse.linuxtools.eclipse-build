#!/bin/bash
NAME="sdk"
VERSION=3.5M4

echo "Exporting from CVS..."
rm -fr $NAME-$VERSION
mkdir $NAME-$VERSION
pushd $NAME-$VERSION >/dev/null

sed -i "s/fullmoon\.ottawa\.ibm\.com/download\.eclipse\.org/g" ../directory.txt

MAPFILE=../directory.txt
TEMPMAPFILE=temp.map
grep ^[a-z] $MAPFILE > $TEMPMAPFILE

gawk 'BEGIN {
	FS=","
}
{
if (NF <  4) {
	split($1, version, "=");
	split(version[1], directory, "@");
	cvsdir=split($2, dirName, ":");
	split($2, protocol, ",");
	split(protocol[1], realProto, "=")
	if (realProto[2] = "GET") {
		printf("%s\n", protocol[3]) 
	}
	#printf("%s %s %s%s %s %s %s %s %s %s %s\n", "cvs", "-d", ":pserver:anonymous@dev.eclipse.org:", dirName[cvsdir], "-q", "export", "-r", version[2], "-d", directory[2], directory[2]) ;
}
else {
	split($1, version, "=");
	total=split($4, directory, "/");
	cvsdir=split($2, dirName, ":");
	#printf("%s %s %s%s %s %s %s %s %s %s %s\n", "cvs", "-d", ":pserver:anonymous@dev.eclipse.org:", dirName[cvsdir], "-q", "export", "-r", version[2], "-d", directory[total], $4) ;
}

}' $TEMPMAPFILE

rm $TEMPMAPFILE 
popd >/dev/null

echo "Creating tarball '$NAME-$VERSION.tar.gz'..."
tar -czf $NAME-$VERSION.tar.gz $NAME-$VERSION
