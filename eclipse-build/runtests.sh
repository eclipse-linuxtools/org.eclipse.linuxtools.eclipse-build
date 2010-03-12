#!/bin/bash

#### Please post any and all results and analysis here:
#### http://wiki.eclipse.org/Linux_Tools_Project/Eclipse_Build/Tests

function usage() {
cat << _EOF_
usage: $0 [<options>]

Run Eclipse SDK tests

Optional arguments:
   -h      Show this help message
   -g      Don't run the tests headless
   -d      Allow remote connection to test runs' JVM
   -t      Timestamp string with which to tag the results
_EOF_
}

function init() {
	# Test suites to run
	testPluginsToRun="\
	org.eclipse.ant.tests.core \
	org.eclipse.ant.tests.ui \
	org.eclipse.compare.tests \
	org.eclipse.core.expressions.tests \
	org.eclipse.core.filebuffers.tests \
	org.eclipse.core.tests.net \
	org.eclipse.core.tests.resources \
	org.eclipse.core.tests.runtime \
	org.eclipse.equinox.security.tests \
	org.eclipse.jdt.core.tests.builder \
	org.eclipse.jdt.core.tests.compiler \
	org.eclipse.jdt.core.tests.model \
	org.eclipse.jdt.core.tests.performance \
	org.eclipse.jdt.debug.tests \
	org.eclipse.jdt.text.tests \
	org.eclipse.jdt.ui.tests \
	org.eclipse.jdt.ui.tests.refactoring \
	org.eclipse.jface.tests.databinding \
	org.eclipse.jface.text.tests \
	org.eclipse.ltk.core.refactoring.tests \
	org.eclipse.ltk.ui.refactoring.tests \
	org.eclipse.osgi.tests \
	org.eclipse.pde.api.tools.tests \
	org.eclipse.pde.build.tests \
	org.eclipse.pde.ds.tests \
	org.eclipse.pde.ui.tests \
	org.eclipse.search.tests \
	org.eclipse.swt.tests \
	org.eclipse.team.tests.core \
	org.eclipse.text.tests \
	org.eclipse.ua.tests \
	org.eclipse.ui.editors.tests \
	org.eclipse.ui.tests \
	org.eclipse.ui.tests.forms \
	org.eclipse.ui.tests.navigator \
	org.eclipse.ui.tests.rcp \
	org.eclipse.ui.tests.views.properties.tabbed \
	org.eclipse.ui.workbench.texteditor.tests \
	"

	# We're not ready to run these yet (setup, etc.)
	# 	org.eclipse.equinox.p2.tests \
	#	org.eclipse.equinox.p2.tests.ui \
	#	org.eclipse.update.tests.core \
	#	org.eclipse.ui.tests.performance \
	#	org.eclipse.team.tests.cvs.core \
	#	org.eclipse.releng.tests \
	#	org.eclipse.jdt.compiler.tool.tests \

	# Defaults
	debugTests=0
	headless=1
	testFramework=org.eclipse.test_3.2.0
	if [ -z ${timestamp} ]; then
		timestamp=$(date "+%Y%m%d%H%M%S")
	fi
	label=$(grep label build.properties | sed s/label=//)
	testsRepo=$(pwd)/testsBuild/eclipse-sdktests-${label}-src/buildRepo/

	testsParent=$(pwd)/tests_${timestamp}
        mkdir -p ${testsParent}
        cp -rp $(pwd)/build/eclipse-${label}-src/installation ${testsParent}/testsinstallation.clean
	cleanInstall=${testsParent}/testsinstallation.clean
        workspace=${testsParent}/workspace

	eclipseHome=${cleanInstall}
        installTestFramework

	eclipseHome=${testsParent}/installation

	results=${testsParent}/results
	datadir=${testsParent}/testDataDir
	homedir=${testsParent}/home
	testhome=${testsParent}/testhome

	rm -rf $datadir $homedir $testhome
	mkdir -p $datadir $homedir $testhome $results/{xml,logs,html}

	properties=$(pwd)/sdk-tests.properties
	rm -f $properties
	echo "data-dir=$datadir" >> $properties
	echo "useEclipseExe=true" >> $properties
	echo "junit-report-output=$results" >> $properties
	echo "results=$results" >> $properties
	echo "tmpresults=$tmpresults" >> $properties
	echo "testhome=$testhome" >> $properties

	if [ $debugTests -eq 1 ]; then
	    echo "extraVMargs=-Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=y,address=40000" >> $properties
	fi
}

function findXvncAndSetDisplay() {
	if [ ${headless} == 1 ]; then
		# Try to find Xvnc
		xvnc=
		if [ -a /usr/bin/Xvnc ]
		then
			xvnc=/usr/bin/Xvnc
			setupXvnc
		else
			if [ -a /usr/X11/bin/Xvnc ]
			then
				xvnc=/usr/X11/bin/Xvnc
				setupXvnc
			else
				echo "Couldn't find Xvnc (/usr/bin/Xvnc or /usr/X11/bin/Xvnc).  Using DISPLAY=0:0"
				DISPLAY=`$HOST`:0.0
			fi
		fi
		export DISPLAY
	fi
}

function setupXvnc() {
	# Pick a high display number.
	port=`expr '(' $RANDOM '*' 9 / 32767 ')' + 58`
	echo localhost > Xvnc.cfg
	echo "Setting up Xvnc on port ${port} with password VNCpassword1"
	$xvnc :$port -screen 1 1024x768x32 -auth Xvnc.cfg -localhost -PasswordFile eclipse-tests-vncpwd &> Xvnc.log &
	Xvncpid=$!
	DISPLAY=`$HOST`:$port
}

function setArch() {
	if [ "x$buildArch" = "x" ]
	then
	    if uname -m > /dev/null 2>&1; then
	    	arch=`uname -m`
	    else
	    	arch=`uname -p`
	    fi
	    # Massage arch for Eclipse-uname differences
	    case $arch in
	    	i[0-9]*86)
	    		arch=x86 ;;
	    	ia64)
	    		arch=ia64 ;;
	    	ppc)
	    		arch=ppc ;;
	    	x86_64)
	    		arch=x86_64 ;;
	    	*)
	    		echo "Unrecognized architecture:  $arch" 1>&2
	    		exit 1 ;;
	    esac
		echo >&2 "Architecture not specified.  Assuming host architecture: $arch"
	fi
}

function runTestSuite() {
	libraryXml=${eclipseHome}/plugins/${testFramework}/library.xml

	${eclipseHome}/eclipse \
	-application org.eclipse.ant.core.antRunner \
	-file $testDriver \
	-Declipse-home=${eclipseHome} \
	-Dos=linux \
	-Dws=gtk \
	-Darch=${arch} \
	-Dlibrary-file=$libraryXml \
	-propertyfile $properties \
	-logger org.apache.tools.ant.DefaultLogger \
	-vmargs \
	-Duser.home=${homedir} \
	-Dosgi.os=linux \
	-Dosgi.ws=gtk \
	-Dosgi.arch=${arch}
}

function cleanAfterTestSuite() {
	rm -rf ${datadir} ${homedir} ${testhome}
	mkdir -p ${datadir} ${homedir} ${testhome}
}

#function setupForP2Tests() {
#	# Set up for p2 tests
#	platformZip=$(grep platform.archive /usr/lib/eclipse/dropins/eclipse/rpm.properties | sed s/.*=//g)
#	platformZipDir=$(dirname $platformZip)_eclipse
#	if [ ! -f $platformZip ]; then
#	  mkdir -p $(dirname $platformZip)
#	  mkdir -p $platformZipDir/eclipse
#	  sh /usr/lib/eclipse/buildscripts/copy-platform $platformZipDir/eclipse /usr/lib/eclipse
#	  pushd $platformZipDir
#	  tar hczf $platformZip *
#	  popd
#	  rm -rf $platformZipDir
#	fi
#}

function cleanupXvnc() {
	# Clean up if we used Xvnc
	if [ -e Xvnc.cfg ]
	then
		kill $Xvncpid
		rm Xvnc.cfg
	fi
}

function runTestPlugins() {
	for plugin in $testPluginsToRun; do
		cleanAndSetup
		installTestPlugin
		rm -rf ${workspace}
		mkdir -p ${workspace}
		runTestPlugin
	done
}

function cleanAndSetup() {
  rm -rf ${eclipseHome}
  rm -rf ${workspace}

  cp -rp ${cleanInstall} ${eclipseHome}
  workspace=${testsParent}/workspace
}

function installTestPlugin() {
  IUtoInstall=${plugin}
  installIU
}

function installIU() {
  pushd ${eclipseHome} > /dev/null
    ./eclipse \
      -nosplash \
      -application org.eclipse.equinox.p2.director \
      -data ${workspace} \
      -consoleLog \
      -flavor tooling \
      -installIU ${IUtoInstall} \
      -profileProperties org.eclipse.update.install.features=true \
      -metadatarepository file:${testsRepo} \
      -artifactrepository file:${testsRepo}
  popd > /dev/null
}

function installTestFramework() {
  IUtoInstall=org.eclipse.test.feature.group
  installIU
}

function runTestPlugin() {
	pluginVersion=$(ls ${eclipseHome}/plugins | grep ${plugin}_ | sed s/${plugin}_//)
	echo "Running ${plugin} (${pluginVersion})"
	testDriver="${eclipseHome}/plugins/${plugin}_${pluginVersion}/test.xml"
	if [ ${plugin} == "org.eclipse.swt.tests" ]; then
		echo "plugin-path=${eclipseHome}/plugins/${plugin}_${pluginVersion}" >> ${properties}
	fi
	runTestSuite
	cleanAfterTestSuite
	mv ${results}/*.txt ${results}/logs
	xmlDir=${results}/tmpXml
	mkdir -p ${xmlDir}
	mv ${results}/*.xml ${xmlDir}
	genHtml
	mv ${xmlDir}/* ${results}/xml
	rm -rf ${xmlDir}
	if [ ${plugin} == "org.eclipse.swt.tests" ]; then
		sed -i "/plugin-path/d" ${properties}
	fi
}

function genHtml() {
	ant -Declipse-home=${eclipseHome} -Dresults=${results} -DxmlDir=${xmlDir} -f junitHelper.xml
}

# Command-line arguments
while getopts "de:gt:h" OPTION
do
     case $OPTION in
         d)
             debugTests=1
             ;;
         g)
             headless=0
             ;;
         t)
             timestamp=$OPTARG
             ;;
         h)
             usage
             exit 1
             ;;
     esac
done

init
findXvncAndSetDisplay
setArch
runTestPlugins
cleanupXvnc
