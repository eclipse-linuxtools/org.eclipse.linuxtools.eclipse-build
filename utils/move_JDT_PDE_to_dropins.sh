# JDT and PDE are built as update sites.
# The procedure of moving them to dropins is following:
#
# Copy Eclipse installation
# Install JDT or PDE into it
# Copy the difference into dropins
#
# This must go this way to initialize all the plugins.
#
# There is one argument required : a path to a repo that contains JDT and PDE.
#
# Base Eclipse installation is required to not have JDT or PDE installed.



REPO=${1}

#make a backup 
cp -rf eclipse eclipse-backup-with-jdt
# go into backup
pushd eclipse-backup-with-jdt
        ./eclipse -application org.eclipse.equinox.p2.director \
        -repository file:/${REPO} \
        -installIU org.eclipse.jdt.feature.group
#exit backup
popd

mkdir -p jdt/plugins jdt/features


#get the difference and copy all files into jdt folder
for i in `ls eclipse-backup-with-jdt/features` ; do \
    if [ ! -e eclipse/features/$i ]; \
        then cp -r eclipse-backup-with-jdt/features/$i jdt/features ; \
    fi  \
done

for i in `ls eclipse-backup-with-jdt/plugins` ; do \
    if [ ! -e eclipse/plugins/$i ]; \
        then cp -r eclipse-backup-with-jdt/plugins/$i jdt/plugins ; \
    fi  \
done

cp -rf eclipse-backup-with-jdt eclipse-backup-with-jdt-pde

pushd eclipse-backup-with-jdt-pde
    ./eclipse -application org.eclipse.equinox.p2.director \
        -repository file:/${REPO} \
        -installIU org.eclipse.sdk.feature.group
popd

mkdir -p sdk/plugins sdk/features

#get the difference and copy all files into pde folder
for i in `ls eclipse-backup-with-jdt-pde/features` ; do \
    if [ ! -e eclipse-backup-with-jdt/features/$i ]; \
        then cp -r eclipse-backup-with-jdt-pde/features/$i sdk/features ; \
    fi  \
done

for i in `ls eclipse-backup-with-jdt-pde/plugins` ; do \
    if [ ! -e eclipse-backup-with-jdt/plugins/$i ]; \
        then cp -r eclipse-backup-with-jdt-pde/plugins/$i sdk/plugins ; \
    fi  \
done


cp -r jdt sdk eclipse/dropins 