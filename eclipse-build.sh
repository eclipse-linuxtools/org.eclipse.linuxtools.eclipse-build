#!/bin/sh

#########################################################################
#
# Copyright (c) 2007 Red Hat Incorporated.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
#
# Contributors:
#    Ben Konrath <bkonrath@redhat.com> - initial implementation
#
#########################################################################

ECLIPSE_VERSION=3.2.2
VERSION=$ECLIPSE_VERSION-1

prepare_build()
{
## Patches and features that every distro uses. These patches and features are candidates 
## for inclusion upstream.

# remove existing .sos
find -name \*.so | xargs rm

# delete included jars
# https://bugs.eclipse.org/bugs/show_bug.cgi?id=170662
rm plugins/org.eclipse.swt.win32.win32.x86/swt.jar \
   plugins/org.eclipse.swt/extra_jars/exceptions.jar \
   plugins/org.eclipse.swt.tools/swttools.jar \
   features/org.eclipse.platform.launchers/bin/startup.jar \
   plugins/org.eclipse.team.cvs.ssh2/com.jcraft.jsch_*.jar


# build liblocalfile and libupdate JNI libs in the main SDK build.xml
# https://bugs.eclipse.org/bugs/show_bug.cgi?id=178726
patch -p0 < $PATCHESDIR/eclipse-compile-liblocalfile-and-libupdate.patch

# all output should be directed to stdout
# https://bugs.eclipse.org/bugs/show_bug.cgi?id=144942
find -type f -name \*.xml -exec sed --in-place -r "s/output=\".*(txt|log).*\"//g" "{}" \;

# generic releng scripts that can be used to build plugins
# https://www.redhat.com/archives/fedora-devel-java-list/2006-April/msg00048.html
pushd plugins/org.eclipse.pde.build
patch -p0 < $PATCHESDIR/eclipse-pde.build-add-package-build.patch
popd

# Add GCJ driver to ecj
pushd plugins/org.eclipse.jdt.core
patch -p0 < $PATCHESDIR/eclipse-add-gcjmain-to-ecj.patch
popd

# Add patch to allow ecj to deal with the jpackage.org [] jar notation
# https://bugs.eclipse.org/bugs/show_bug.cgi?id=161996
pushd plugins/org.eclipse.jdt.core
patch -p0 < $PATCHESDIR/eclipse-ecj-square-bracket-classpath.patch
popd

# Use the system-installed javadocs instead of the javadocs on sun.com
sed --in-place "s|http://java.sun.com/j2se/1.4.2/docs/api|/usr/share/javadocs/java|" \
   plugins/org.eclipse.platform.doc.isv/platformOptions.txt
sed --in-place "s|http://java.sun.com/j2se/1.5/docs/api|/usr/share/javadocs/java|" \
   plugins/org.eclipse.jdt.doc.isv/jdtaptOptions.txt                    \
   plugins/org.eclipse.jdt.doc.isv/jdtOptions.txt
sed --in-place "s|http://java.sun.com/j2se/1.4/docs/api|/usr/share/javadocs/java|" \
   plugins/org.eclipse.pde.doc.user/pdeOptions.txt                      \
   plugins/org.eclipse.pde.doc.user/pdeOptions

# launcher patches
rm plugins/org.eclipse.platform/launchersrc.zip
pushd features/org.eclipse.platform.launchers
# This patch does two things:
# 1. allows the launcher to be in /usr/bin and
# FIXME can we use eclipse.conf to set the configuration directory? 
# 2. ensures that the OSGi configuration directory
#    (which contains the JNI .sos) is in %{_libdir}
# We should investigate whether or not this can go upstream
patch -p0 < $PATCHESDIR/eclipse-launcher-set-install-dir-and-shared-config.patch
patch -p0 < $PATCHESDIR/eclipse-launcher-add-ppc64-to-list-of-arches-with-gre64.patch
# put the configuration directory in an arch-specific location
sed --in-place "s:/usr/lib/eclipse/configuration:%{_libdir}/eclipse/configuration:" library/eclipse.c
zip -q -9 -r ../../plugins/org.eclipse.platform/launchersrc.zip library
popd

# Use launcher we built
patch -p0 < $PATCHESDIR/eclipse-use-built-launcher.patch

# libupdate.so patches
patch -p0 < $PATCHESDIR/eclipse-dont-build-libupdate-as-static-lib.patch
patch -p0 < $PATCHESDIR/eclipse-bulid-libupdate-on-all-archs.patch

# Build swttools.jar
# https://bugs.eclipse.org/bugs/show_bug.cgi?id=90364
pushd plugins/org.eclipse.swt.gtk.linux.x86_64
patch -p0 < $PATCHESDIR/eclipse-build-swttools.patch
popd

# Automattically create an update site in user's home dir when they try to install plugins
# https://bugs.eclipse.org/bugs/show_bug.cgi?id=90630
patch -p0 < $PATCHESDIR/eclipse-auto-update-site-in-homedir.patch

# the swt version is set to HEAD on ia64 but shouldn't be
# get swt version
SWT_MAJ_VER=$(grep maj_ver plugins/org.eclipse.swt/Eclipse\ SWT/common/library/make_common.mak | cut -f 2 -d =)
SWT_MIN_VER=$(grep min_ver plugins/org.eclipse.swt/Eclipse\ SWT/common/library/make_common.mak | cut -f 2 -d =)
SWT_VERSION=$SWT_MAJ_VER$SWT_MIN_VER
swt_frag_ver=$(grep v$SWT_VERSION plugins/org.eclipse.swt.gtk.linux.x86/build.xml | sed "s:.*<.*\"\(.*\)\"/>:\1:")
swt_frag_ver_ia64=$(grep "version\.suffix\" value=" plugins/org.eclipse.swt.gtk.linux.ia64/build.xml | sed "s:.*<.*\"\(.*\)\"/>:\1:")
sed --in-place "s/$swt_frag_ver_ia64/$swt_frag_ver/g" plugins/org.eclipse.swt.gtk.linux.ia64/build.xml \
                                                      assemble.org.eclipse.sdk.linux.gtk.ia64.xml \
                                                      features/org.eclipse.rcp/build.xml

## Optional features and patches.

# This tomcat stuff will change when they move to the equinox jetty provider
# https://bugs.eclipse.org/bugs/show_bug.cgi?id=98371
if [ $ENABLE_TOMCAT55_PATCHES  ]; then
  if [ -z $TOMCAT55_VERSION ]; then
    echo You must set TOMCAT55_VERSION in your conf file. 
    exit 1
  fi  
  pushd plugins/org.eclipse.tomcat
  patch -p0 < eclipse-tomcat55.patch
  patch -p0 < eclipse-tomcat55-build.patch
  popd
  sed --in-place "s/4.1.130/$TOMCAT55_VERSION/g"                      \
                features/org.eclipse.platform/build.xml \
                plugins/org.eclipse.tomcat/build.xml    \
                plugins/org.eclipse.tomcat/META-INF/MANIFEST.MF   \
                assemble.*.xml
  pushd plugins/org.eclipse.help.webapp
  patch -p0 < eclipse-webapp-tomcat55.patch
  popd
fi

# build with Java 5
if [ $HAVE_JAVA5  ]; then 
  sed --in-place "s/java5.home/java.home/" build.xml
else
  # FIXME implement
  echo "FIXME"
fi

# Suppport for ppc64, s390{,x} and sparc{,64}
if [ $ENABLE_PPC64_SPARC64_S390_S390X_SUPPORT  ]; then
  patch -p0 < $PATCHESDIR/eclipse-add-ppc64-sparc64-s390-s390x-support.patch
  # there is only partial support for ppc64 in 3.2 so we have to remove this 
  # partial support to get the replacemnt hack to work
  find -name \*ppc64\* | xargs rm -r
  # remove ppc64 support from features/org.eclipse.platform.source/feature.xml
  # replace ppc64 with a fake arch (ppc128) so we don't have duplicate ant targets
  find -type f -name \*.xml -exec sed --in-place "s/\(rootFileslinux_gtk_\)ppc64/\1ppc128/g" "{}" \;
  # remove org.eclipse.platform.source.linux.gtk.ppc64,3.2.0.v20060602-0010-gszCh-8eOaU1uKq
  sed --in-place "s/,.\{38\}ppc64.*macosx/,org.eclipse.platform.source.macosx/g" features/org.eclipse.platform.source/build.xml
  # replace final occurances with an existing arch
  sed --in-place "s/ppc64/x86_64/g" features/org.eclipse.platform.source/build.xml
  # Move all of the ia64 directories to ppc64 or s390{,x} or sparc{,64} dirs and replace 
  # the ia64 strings with ppc64 or s390(x)
  #FIXME use uname -p or -i or -m
  if [ $ARCH = "ppc64" -o $ARCH = "s390" -o  $ARCH = "s390x" -o $ARCH = "sparc" -o  $ARCH = "sparc64" ]; then 
    for f in $(find -name \*ia64\* | grep -v motif | grep -v ia64_32); do 
      mv $f $(echo $f | sed "s/ia64/$ARCH/")
    done
    find -type f ! -name \*.java -a ! -name feature.xml -exec sed --in-place "s/ia64_32/@eye-eh-64_32@/g" "{}" \;
    find -type f ! -name \*.java -a ! -name feature.xml -exec sed --in-place "s/ia64/%{_arch}/g" "{}" \;
    find -type f ! -name \*.java -a ! -name feature.xml -exec sed --in-place "s/@eye-eh-64_32@/ia64_32/g" "{}" \;
  fi 
fi

# Generate debuginfo during package builds
if [ $ENABLE_ECJ_DEBUGINFO_DURING_PACKAGE_BUILDS  ]; then
  patch -p0 < $PATCHESDIR/eclipse-ecj-rpmdebuginfo.patch
fi

# Build against firefox:
#  - fix swt profile include path
#  - don't compile the mozilla 1.7 / firefox profile library -- build it inline
#  - don't use symbols not in our firefox builds
# https://bugs.eclipse.org/bugs/show_bug.cgi?id=161310
# Note:  I made this patch from within Eclipse and then did the following to
#        it due to spaces in the paths:
#  sed --in-place "s/Eclipse\ SWT\ Mozilla/Eclipse_SWT_Mozilla/g" eclipse-swt-firefox.patch
#  sed --in-place "s/Eclipse\ SWT\ PI/Eclipse_SWT_PI/g" eclipse-swt-firefox.patch
if [ $ENABLE_SWT_FIREFOX  ]; then
  pushd plugins/org.eclipse.swt
  mv "Eclipse SWT Mozilla" Eclipse_SWT_Mozilla
  mv "Eclipse SWT PI" Eclipse_SWT_PI
  patch -p0 < $PATCHESDIR/eclipse-swt-firefox.patch
  mv Eclipse_SWT_Mozilla "Eclipse SWT Mozilla"
  mv Eclipse_SWT_PI "Eclipse SWT PI"
  popd
  pushd plugins/org.eclipse.swt.tools
  mv "JNI Generation" JNI_Generation 
  patch -p0 < $PATCHESDIR/eclipse-swt-firefox.2.patch
  mv JNI_Generation "JNI Generation"
  popd
fi

# Workaround GCJ bug #29853
# http://gcc.gnu.org/bugzilla/show_bug.cgi?id=29853
if [ $ENABLE_GCJ_BUG_29853_WORKAROUND  ]; then
  pushd plugins/org.eclipse.pde.core
  patch -p0 < $PATCHESDIR/eclipse-workaround-gcj-bug-29853.patch
  popd
fi

if [ $DISABLE_HELP_INDEX_GENERATION ]; then
  find plugins -type f -name \*.xml -exec sed --in-place "s/\(<antcall target=\"build.index\".*\/>\)/<\!-- \1 -->/" "{}" \;
fi

}

build_eclipse()
{

ORIGCLASSPATH=$CLASSPATH

# Bootstrap ecj in 3 parts:
# 1. Build ecj with gcj -C -- only necessary until gcjx/ecj lands in gcc
# 2. Build ecj with gcj-built ecj ("javac")
# 3. Re-build ecj with output of 2.

if [ $USE_GCJ ]; then
  # Unzip the "stable compiler" source into a temp dir and build it.
  # Note:  we don't want to build the CompilerAdapter.
  mkdir ecj-bootstrap-tmp
  unzip -qq -d ecj-bootstrap-tmp jdtcoresrc/src/ecj.zip
  rm -f ecj-bootstrap-tmp/org/eclipse/jdt/core/JDTCompilerAdapter.java

  # 1a. Build ecj with gcj -C
  pushd ecj-bootstrap-tmp
  for f in `find -name '*.java' | cut -c 3- | LC_ALL=C sort`; do
      gcj -Wno-deprecated -C $f
  done
  find -name '*.class' -or -name '*.properties' -or -name '*.rsc' |\
      xargs jar cf ../ecj-bootstrap.jar
  popd
  
  # Delete our modified ecj and restore the backup
  rm -rf ecj-bootstrap-tmp
  
  # 1b. Natively-compile it
  gcj -fPIC -fjni -findirect-dispatch -shared -Wl,-Bsymbolic \
    -o ecj-bootstrap.jar.so ecj-bootstrap.jar

  gcj-dbtool -n ecj-bootstrap.db 30000
  gcj-dbtool -a ecj-bootstrap.db ecj-bootstrap.jar{,.so}
  
  # 2a. Build ecj
  export CLASSPATH=ecj-bootstrap.jar:$ORIGCLASSPATH
  export ANT_OPTS="-Dgnu.gcj.precompiled.db.path=`pwd`/ecj-bootstrap.db"
fi
ant -buildfile jdtcoresrc/compilejdtcorewithjavac.xml

if [ $USE_GCJ ]; then
  # 2b. Natively-compile ecj
  gcj -fPIC -fjni -findirect-dispatch -shared -Wl,-Bsymbolic \
    -o jdtcoresrc/ecj.jar.so jdtcoresrc/ecj.jar
   
  gcj-dbtool -n jdtcoresrc/ecj.db 30000
  gcj-dbtool -a jdtcoresrc/ecj.db jdtcoresrc/ecj.jar{,.so}

  # Remove our gcj-built ecj
  rm ecj-bootstrap.db ecj-bootstrap.jar{,.so}

  # To enSURE we're not using any pre-compiled ecj on the build system, set this
  export ANT_OPTS="-Dgnu.gcj.precompiled.db.path=`pwd`/jdtcoresrc/ecj.db"
fi

# 3. Use this ecj to rebuild itself
export CLASSPATH=`pwd`/jdtcoresrc/ecj.jar:$ORIGCLASSPATH
ant -buildfile jdtcoresrc/compilejdtcore.xml

if [ $USE_GCJ ]; then
  # Natively-compile it
  gcj -fPIC -fjni -findirect-dispatch -shared -Wl,-Bsymbolic \
    -o ecj.jar.so ecj.jar
  gcj-dbtool -n ecj.db 30000
  gcj-dbtool -a ecj.db ecj.jar{,.so}
  export ANT_OPTS="-Dgnu.gcj.precompiled.db.path=`pwd`/ecj.db"
  
  # Remove old native bits
  rm jdtcoresrc/ecj.db jdtcoresrc/ecj.jar.so
fi

# Build the rest of Eclipse
export CLASSPATH=`pwd`/ecj.jar:$ORIGCLASSPATH
export JAVA_HOME=%{java_home}
ant \
  -Dnobootstrap=true \
  -DinstallOs=linux -DinstallWs=gtk -DinstallArch=$ARCH \
  -Dlibsconfig=true -DjavacSource=1.5 -DjavacTarget=1.5 

# Build the FileInitializer application
SDK=$(cd eclipse && pwd)
PDEPLUGINVERSION=$(ls $SDK/plugins | grep pde.build | sed 's/org.eclipse.pde.build_//')

pushd equinox-incubator
mkdir -p build
mkdir -p home
homedir=$(cd home && pwd)

# This can go away when package build handles plugins (not just features)
echo "<project default=\"main\"><target name=\"main\"></target></project>" > build/assemble.org.eclipse.equinox.initializer.all.xml
echo "<project default=\"main\"><target name=\"main\"></target></project>" > build/package.org.eclipse.equinox.initializer.all.xml

java -cp $SDK/startup.jar \
      org.eclipse.core.launcher.Main \
     -Duser.home=$homedir                              \
     -application org.eclipse.ant.core.antRunner       \
     -Dtype=plugin                                    \
     -Did=org.eclipse.equinox.initializer                   \
     -DsourceDirectory=$(pwd)                          \
     -DbaseLocation=$SDK \
     -Dbuilder=$SDK/plugins/org.eclipse.pde.build_$PDEPLUGINVERSION/templates/package-build  \
     -f $SDK/plugins/org.eclipse.pde.build_$PDEPLUGINVERSION/scripts/build.xml

pushd build/plugins/org.eclipse.equinox.initializer
java -cp $SDK/startup.jar \
      org.eclipse.core.launcher.Main \
     -Duser.home=$homedir                              \
     -application org.eclipse.ant.core.antRunner       \
     -f build.xml build.update.jar
popd

popd

}

install_eclipse()
{

# Get swt version
SWT_MAJ_VER=$(grep maj_ver plugins/org.eclipse.swt/Eclipse\ SWT/common/library/make_common.mak | cut -f 2 -d =)
SWT_MIN_VER=$(grep min_ver plugins/org.eclipse.swt/Eclipse\ SWT/common/library/make_common.mak | cut -f 2 -d =)
SWT_VERSION=$SWT_MAJ_VER$SWT_MIN_VER

# Some directories we need
install -d -m 755 $RPM_BUILD_ROOT%{_datadir}/eclipse
install -d -m 755 $RPM_BUILD_ROOT%{_datadir}/eclipse/links
install -d -m 755 $RPM_BUILD_ROOT%{_libdir}/eclipse
install -d -m 755 $RPM_BUILD_ROOT%{_libdir}/eclipse/plugins
install -d -m 755 $RPM_BUILD_ROOT%{_libdir}/eclipse/features

# Explode the resulting SDK tarball
tar -C $RPM_BUILD_ROOT%{_datadir} -zxf result/linux-gtk-$ARCH-sdk.tar.gz

# The FileInitializer app isn't part of the SDK (yet?) but we want it to be
# around for other packages
cp equinox-incubator/org.eclipse.equinox.initializer/org.eclipse.equinox.initializer_*.jar \
  $RPM_BUILD_ROOT%{_datadir}/eclipse/plugins

# Set up an extension location and a link file for the arch-specific dir
echo "path:$RPM_BUILD_ROOT%{_libdir}" > $RPM_BUILD_ROOT%{_datadir}/eclipse/links/fragments.link
echo "name=Eclipse Platform" > $RPM_BUILD_ROOT%{_libdir}/eclipse/.eclipseextension
echo "id=org.eclipse.platform" >> $RPM_BUILD_ROOT%{_libdir}/eclipse/.eclipseextension
echo "version=%{eclipse_majmin}.%{eclipse_micro}" >> $RPM_BUILD_ROOT%{_libdir}/eclipse/.eclipseextension

# Install the platform-specific fragments in an arch-specific dir
mv $RPM_BUILD_ROOT%{_datadir}/eclipse/plugins/*$ARCH* $RPM_BUILD_ROOT%{_libdir}/eclipse/plugins

# platform.source has the launcher src zip which is platform-specific
PLATFORMSOURCEVERSION=$(ls $RPM_BUILD_ROOT%{_datadir}/eclipse/plugins | grep platform.source_ | sed 's/org.eclipse.platform.source_//')
mv $RPM_BUILD_ROOT%{_datadir}/eclipse/plugins/org.eclipse.platform.source_$PLATFORMSOURCEVERSION \
  $RPM_BUILD_ROOT%{_libdir}/eclipse/plugins

# help.webapp generates web.xml with Apache Jakarta Tomcat JspC. This file is
# generated differently for different arches. FIXME investigate this.
HELPWEBAPPVERSION=$(ls $RPM_BUILD_ROOT%{_datadir}/eclipse/plugins | grep help.webapp_ | sed 's/org.eclipse.help.webapp_//')
mv $RPM_BUILD_ROOT%{_datadir}/eclipse/plugins/org.eclipse.help.webapp_$HELPWEBAPPVERSION \
  $RPM_BUILD_ROOT%{_libdir}/eclipse/plugins

# update.core.linux is a fragment
# FIXME: make a patch for upstream to change to swt fragment notation
UPDATECORELINUXVERSION=$(ls $RPM_BUILD_ROOT%{_datadir}/eclipse/plugins | grep update.core.linux_ | sed 's/org.eclipse.update.core.linux_//')
mv $RPM_BUILD_ROOT%{_datadir}/eclipse/plugins/org.eclipse.update.core.linux_$UPDATECORELINUXVERSION \
  $RPM_BUILD_ROOT%{_libdir}/eclipse/plugins

# FIXME: icu4j generates res_index.txt differently on different arches - possible libgcj bug.
mv $RPM_BUILD_ROOT%{_datadir}/eclipse/plugins/com.ibm.icu_3.4.5.20061213.jar $RPM_BUILD_ROOT%{_libdir}/eclipse/plugins
mv $RPM_BUILD_ROOT%{_datadir}/eclipse/plugins/com.ibm.icu.source_3.4.5.20061213 $RPM_BUILD_ROOT%{_libdir}/eclipse/plugins

# FIXME: there is a problem with gjdoc generating different HTML on different
# architectures.
PLATFORMDOCISVVERSION=$(ls $RPM_BUILD_ROOT%{_datadir}/eclipse/plugins | grep platform.doc.isv_ | sed 's/org.eclipse.platform.doc.isv_//')
mv $RPM_BUILD_ROOT%{_datadir}/eclipse/plugins/org.eclipse.platform.doc.isv_$PLATFORMDOCISVVERSION \
  $RPM_BUILD_ROOT%{_libdir}/eclipse/plugins
# ppc64 is problematic with these two
JDTDOCISVVERSION=$(ls $RPM_BUILD_ROOT%{_datadir}/eclipse/plugins | grep jdt.doc.isv_ | sed 's/org.eclipse.jdt.doc.isv_//')
mv $RPM_BUILD_ROOT%{_datadir}/eclipse/plugins/org.eclipse.jdt.doc.isv_$JDTDOCISVVERSION \
  $RPM_BUILD_ROOT%{_libdir}/eclipse/plugins
PDEDOCUSERVERSION=$(ls $RPM_BUILD_ROOT%{_datadir}/eclipse/plugins | grep pde.doc.user_ | sed 's/org.eclipse.pde.doc.user_//')
mv $RPM_BUILD_ROOT%{_datadir}/eclipse/plugins/org.eclipse.pde.doc.user_$PDEDOCUSERVERSION \
  $RPM_BUILD_ROOT%{_libdir}/eclipse/plugins

# Adding support for ppc64, s390{x} and sparc{64} makes the rcp feature 
# have multilib conflicts
mv $RPM_BUILD_ROOT%{_datadir}/eclipse/features/org.eclipse.rcp_* \
  $RPM_BUILD_ROOT%{_libdir}/eclipse/features

# To ensure that the product is org.eclipse.sdk.ide when eclipse-sdk is
# installed, we must check for its presence at %%post{,un} time.  This does not
# work in the biarch case, though, if it is not in an arch-specific location.
# This results in complaints that the sdk plugin is found twice, but this is
# better than always appearing in the about dialog as the Eclipse Platform with
# the platform plugin version number instead of the actual SDK version number.
# -- overholt, 2006-11-03
mv $RPM_BUILD_ROOT%{_datadir}/eclipse/plugins/org.eclipse.sdk_* \
  $RPM_BUILD_ROOT%{_libdir}/eclipse/plugins
mv $RPM_BUILD_ROOT%{_datadir}/eclipse/features/org.eclipse.sdk_* \
  $RPM_BUILD_ROOT%{_libdir}/eclipse/features

# FIXME: investigate why it doesn't work to set this -- configuration data is
# always written to /usr/share/eclipse/configuration, even with
#     -Dosgi.sharedConfiguration.area=$RPM_BUILD_ROOT%{_libdir}/eclipse/configuration
# Note (2006-12-05):  upon looking at this again, we (bkonrath, overholt) don't
# know what we're doing with $libdir_path :)  It requires some investigation.
# 
# Extract .so files
# https://bugs.eclipse.org/bugs/show_bug.cgi?id=90535
pushd $RPM_BUILD_ROOT
datadir_path=$(echo %{_datadir}/eclipse | sed -e 's/^\///')
libdir_path=$(echo %{_libdir}/eclipse | sed -e 's/^\///')
java -Dosgi.sharedConfiguration.area=$libdir_path/configuration \
     -cp $datadir_path/startup.jar \
     org.eclipse.core.launcher.Main \
     -consolelog \
     -application org.eclipse.equinox.initializer.configInitializer \
     -fileInitializer %{SOURCE19}
popd

# Make proper links file
echo "path:/usr/lib" > $RPM_BUILD_ROOT%{_datadir}/eclipse/links/fragments.link
echo "path:/usr/lib64" > $RPM_BUILD_ROOT%{_datadir}/eclipse/links/fragments64.link

# Install config.ini to an arch dependent location and remove the unnecessary
# configuration data
mv $RPM_BUILD_ROOT%{_datadir}/eclipse/configuration $RPM_BUILD_ROOT%{_libdir}/eclipse
rm -r $RPM_BUILD_ROOT%{_libdir}/eclipse/configuration/org.eclipse.update
rm -r $RPM_BUILD_ROOT%{_libdir}/eclipse/configuration/org.eclipse.core.runtime

# Set config.ini for the platform; no benefit to having it be sdk
sed --in-place "s/eclipse.product=org.eclipse.sdk.ide/eclipse.product=org.eclipse.platform.ide/" \
  $RPM_BUILD_ROOT%{_libdir}/eclipse/configuration/config.ini

# Install the Eclipse binary
install -d -m 755 $RPM_BUILD_ROOT%{_bindir}
mv $RPM_BUILD_ROOT%{_datadir}/eclipse/eclipse $RPM_BUILD_ROOT%{_bindir}/eclipse

# Ensure the shared libraries have the correct permissions
pushd $RPM_BUILD_ROOT%{_libdir}/eclipse 
for lib in `find configuration -name \*.so`; do
   chmod 755 $lib
done

# Create file listings for the extracted shared libraries
echo -n "" > %{_builddir}/%{buildsubdir}/eclipse-platform.install;
for id in `ls configuration/org.eclipse.osgi/bundles`; do
  if [ "Xconfiguration" = $(echo X`find configuration/org.eclipse.osgi/bundles/$id -name libswt\*.so` | sed "s:/.*::") ]; then
    echo "%{_libdir}/eclipse/configuration/org.eclipse.osgi/bundles/$id" > %{_builddir}/%{buildsubdir}/%{libname}-gtk2.install;
  else
    echo "%{_libdir}/eclipse/configuration/org.eclipse.osgi/bundles/$id" >> %{_builddir}/%{buildsubdir}/eclipse-platform.install;
  fi
done 
popd

# Install symlinks to the SWT JNI shared libraries in /usr/lib/eclipse
pushd $RPM_BUILD_ROOT%{_libdir}/eclipse
for lib in $(find configuration -name libswt\*.so); do  
  ln -s %{_libdir}/eclipse/$lib `basename $lib`
done
popd

# Install the SWT jar symlinks in libdir
SWTJARVERSION=$(grep v$SWT_VERSION plugins/org.eclipse.swt.gtk.linux.$ARCH/build.xml | sed "s:.*<.*\"\(.*\)\"/>:\1:")
pushd $RPM_BUILD_ROOT%{_libdir}/eclipse
ln -s %{_libdir}/eclipse/plugins/org.eclipse.swt.gtk.linux.$ARCH_$SWTJARVERSION.jar swt-gtk-%{eclipse_majmin}.%{eclipse_micro}.jar
ln -s swt-gtk-%{eclipse_majmin}.%{eclipse_micro}.jar swt-gtk-%{eclipse_majmin}.jar
popd

# Install the eclipse-ecj.jar symlink for java-1.4.2-gcj-compat's "javac"
JDTCORESUFFIX=$(ls $RPM_BUILD_ROOT%{_datadir}/eclipse/plugins | grep jdt.core_ | sed "s/org.eclipse.jdt.core_//")
install -d -m 755 $RPM_BUILD_ROOT%{_javadir}
ln -s %{_datadir}/eclipse/plugins/org.eclipse.jdt.core_$JDTCORESUFFIX $RPM_BUILD_ROOT%{_javadir}/eclipse-ecj.jar
ln -s %{_javadir}/eclipse-ecj.jar $RPM_BUILD_ROOT%{_javadir}/jdtcore.jar

# FIXME: get rid of this by putting logic in package build to know what version
#        of pde.build it's using
# Install a versionless pde.build
pushd $RPM_BUILD_ROOT%{_datadir}/eclipse/plugins/
ln -s org.eclipse.pde.build_* org.eclipse.pde.build
popd

# Icons
PLATFORMSUFFIX=$(ls $RPM_BUILD_ROOT%{_datadir}/eclipse/plugins | grep eclipse.platform_ | sed "s/org.eclipse.platform_//")
install -d -m 755 $RPM_BUILD_ROOT%{_datadir}/icons/hicolor/48x48/apps
ln -s %{_datadir}/eclipse/plugins/org.eclipse.platform_$PLATFORMSUFFIX/eclipse48.png \
  $RPM_BUILD_ROOT%{_datadir}/icons/hicolor/48x48/apps/eclipse.png
install -d -m 755 $RPM_BUILD_ROOT%{_datadir}/icons/hicolor/32x32/apps
ln -s %{_datadir}/eclipse/plugins/org.eclipse.platform_$PLATFORMSUFFIX/eclipse32.png \
  $RPM_BUILD_ROOT%{_datadir}/icons/hicolor/32x32/apps/eclipse.png
install -d -m 755 $RPM_BUILD_ROOT%{_datadir}/icons/hicolor/16x16/apps
ln -s ../../../../eclipse/plugins/org.eclipse.platform_$PLATFORMSUFFIX/eclipse.png \
  $RPM_BUILD_ROOT%{_datadir}/icons/hicolor/16x16/apps/eclipse.png
install -d -m 755 $RPM_BUILD_ROOT%{_datadir}/pixmaps
ln -s %{_datadir}/icons/hicolor/48x48/apps/eclipse.png \
  $RPM_BUILD_ROOT%{_datadir}/pixmaps
%ifarch %{ix86} x86_64
# Remove unused icon.xpm
# This should be fixed in 3.3.
# see https://bugs.eclipse.org/bugs/show_bug.cgi?id=86848
rm $RPM_BUILD_ROOT%{_datadir}/eclipse/icon.xpm
%endif

# Install the efj wrapper script 
install -p -D -m0755 %{SOURCE17} $RPM_BUILD_ROOT%{_bindir}/efj
sed --in-place "s:startup.jar:%{_datadir}/eclipse/startup.jar:" \
  $RPM_BUILD_ROOT%{_bindir}/efj 

# Install the ecj wrapper script
install -p -D -m0755 %{SOURCE18} $RPM_BUILD_ROOT%{_bindir}/ecj
sed --in-place "s:@JAVADIR@:%{_javadir}:" $RPM_BUILD_ROOT%{_bindir}/ecj 

# A sanity check.
desktop-file-validate %{SOURCE2}

# freedesktop.org menu entry
install -p -D -m 644 %{SOURCE2} $RPM_BUILD_ROOT%{_datadir}/applications/eclipse.desktop

SDKPLUGINVERSION=$(ls $RPM_BUILD_ROOT%{_libdir}/eclipse/plugins | grep eclipse.sdk_ | sed "s/org.eclipse.sdk_//")
# Put Fedora Core version into about.mappings of org.eclipse.sdk and
# org.eclipse.platform to show it in # Eclipse about dialog.  (courtesy Debian
# Eclipse packagers)
# FIXME use the third id
pushd $RPM_BUILD_ROOT%{_libdir}/eclipse/plugins/org.eclipse.sdk_$SDKPLUGINVERSION
OS_VERSION=$(cat /etc/*-release | head -n 1)
sed -e "s/\(0=.*\)/\1 ($OS_VERSION)/" < about.mappings > about.mappings.tmp
mv about.mappings.tmp about.mappings
popd
PLATFORMPLUGINVERSION=$(ls $RPM_BUILD_ROOT%{_datadir}/eclipse/plugins | grep eclipse.platform_ | sed "s/org.eclipse.platform_//")
pushd $RPM_BUILD_ROOT%{_datadir}/eclipse/plugins/org.eclipse.platform_$PLATFORMPLUGINVERSION
sed -e "s/\(0=.*\)/\1 ($OS_VERSION)/" < about.mappings > about.mappings.tmp
mv about.mappings.tmp about.mappings
popd

# Create a script that can be used to make a symlink tree of the
# eclipse platform.
cp %{SOURCE16} copy-platform
(
  cd $RPM_BUILD_ROOT%{_datadir}/eclipse
  ls -d * | egrep -v '^(plugins|features|links|about_files)$'
  ls -d plugins/* features/* links/*
) |
sed -e's/^\(.*\)$/\1 \1/' -e's,^,ln -s $eclipse/,' >> copy-platform

mkdir -p $RPM_BUILD_ROOT%{_datadir}/eclipse/buildscripts
cp copy-platform $RPM_BUILD_ROOT%{_datadir}/eclipse/buildscripts

# remove this python script so that it is not aot compiled, thus avoiding a
# multilib conflict
ANTPLUGINVERSION=$(ls plugins | grep org.apache.ant_ | sed 's/org.apache.ant_//')
rm $RPM_BUILD_ROOT%{_datadir}/eclipse/plugins/org.apache.ant_$ANTPLUGINVERSION/bin/runant.py

if [ $USE_GCJ  ]; then
# exclude org.eclipse.ui.ide to work around
# https://bugzilla.redhat.com/bugzilla/show_bug.cgi?id=175547
UIIDEPLUGINVERSION=$(ls plugins | grep ui.ide_ | sed 's/org.eclipse.ui.ide_//')
%ifnarch ia64
aot-compile-rpm --exclude %{_datadir}/eclipse/plugins/org.eclipse.ui.ide_$UIIDEPLUGINVERSION
%else
OSGIPLUGINVERSION=$(ls plugins | grep osgi_ | sed 's/org.eclipse.osgi_//')
aot-compile-rpm --exclude %{_datadir}/eclipse/plugins/org.eclipse.ui.ide_$UIIDEPLUGINVERSION \
                --exclude %{_datadir}/eclipse/plugins/com.jcraft.jsch_0.1.28.jar \
                --exclude %{_datadir}/eclipse/plugins/org.eclipse.osgi_$OSGIPLUGINVERSION
%endif
fi

}

display_help ()
{
echo "eclipse-build.sh $VERSION"
echo "Usage: eclipse-build.sh -c <config file> -a <arch> [other options]"
echo "Options:"
echo "-a <arch>"
echo "       Specify the arch we are building on (Required)"
echo "-c <file>"
echo "       Specify a configuration file (Required)"
echo "-h     Display this help"
echo "-p     Prepare the Eclipse SDK for build - apply patches and such" 
echo ""
}

###########################################
# start of execution
###########################################
ARCH=""
while getopts a:bc:hip opt; do
    case "$opt" in
        a) ARCH=$OPTARG ;;
        b) BUILD=1 ;;
        c) CONFIG=$OPTARG ;;
	h) display_help; exit ;;
	h) INSTALL=1 ;;
	p) PREPARE=1 ;;
        ?) display_help; exit ;;
    esac
done

if [ ! -z $CONFIG ]; then
  if [ -r $CONFIG ]; then
    . $CONFIG
  else
    echo "ERROR: cannot read $CONFIG"
    exit 1
  fi
else
  echo "ERROR: you must specify a congfig file using the '-c' option"
  display_help
  exit 1
fi

if [ -z $ARCH ]; then
  echo "ERROR: you must specify an arch using the '-a' option"
  display_help
  exit 1
fi

# FIXME deal with mutually exclusive options -- case??.
if [ $PREPARE ]; then
  if [ $BUILD -o $INSTALL ]; then
    echo "ERROR: you can't use -p with -b or -i"
    display_help
    exit 1
  fi
  PATCHESDIR=$(echo `pwd``find -type d -name patches` | sed "s|\./|/|")
  prepare_build 
  exit
elif [ $BUILD ]; then
  if [ $PREPARE -o $INSTALL ]; then
    echo "ERROR: you can't use -b with -p or -i"
    display_help
    exit 1
  fi
  build_eclipse
  exit
elif [ $INSTALL ]; then 
  if [ $PREPARE -o $BUILD ]; then
    echo "ERROR: you can't use -i with -p or -b"
    display_help
    exit 1
  fi
  install_eclipse
  exit
fi
