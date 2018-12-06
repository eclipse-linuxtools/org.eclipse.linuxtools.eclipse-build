# This script replaces all plugins in platform that can be replaced with symlinks
# It goes into a folder that is first argument of the script
# Then into plugins, and then symlinks 

# SCL java dir is different from default

set -e

SCL_JAVA_DIRS=${@:2}

function _symlink {
	_f=$(ls | grep -e "^$1" || :)
	if [ -n "$_f" ] ; then
		rm -rf $_f
		for SCL_JAVA_DIR in ${SCL_JAVA_DIRS}; do
			if [ -f ${SCL_JAVA_DIR}/$2  ]; then
				echo "found ${SCL_JAVA_DIR}/$2"
				ln -s ${SCL_JAVA_DIR}/$2 ${_f%.jar}.jar
				return 0
			fi
		done
		echo "not found $2 in any of ${SCL_JAVA_DIRS}"
		exit 1
	fi
}

pushd $1
	# Remove and symlink all duplicate jars in the platform
	pushd plugins
		_symlink com.ibm.icu_ icu4j/icu4j.jar
		_symlink com.jcraft.jsch_ jsch.jar
		_symlink com.sun.el.javax.el_ glassfish-el.jar
		_symlink javax.annotation-api_ glassfish-annotation-api.jar
		_symlink javax.el-api_ glassfish-el-api.jar
		_symlink javax.inject_ atinject.jar
		_symlink javax.servlet.jsp_ glassfish-jsp-api/javax.servlet.jsp-api.jar
		_symlink javax.servlet-api_ glassfish-servlet-api.jar
		_symlink javax.xml_ xml-commons-apis.jar
		_symlink org.apache.batik.css_ batik/batik-css.jar
		_symlink org.apache.batik.util_ batik/batik-util.jar
		_symlink org.apache.batik.util.gui_ batik/batik-gui-util.jar
		_symlink org.apache.commons.codec_ commons-codec.jar
		_symlink org.apache.commons.jxpath_ commons-jxpath.jar
		_symlink org.apache.commons.logging_ commons-logging.jar
		_symlink org.apache.felix.gogo.command_ felix/org.apache.felix.gogo.command.jar
		_symlink org.apache.felix.gogo.runtime_ felix/org.apache.felix.gogo.runtime.jar
		_symlink org.apache.felix.gogo.shell_ felix/org.apache.felix.gogo.shell.jar
		_symlink org.apache.felix.scr_ felix/org.apache.felix.scr.jar
		_symlink org.apache.httpcomponents.httpcore_ httpcomponents/httpcore.jar
		_symlink org.apache.httpcomponents.httpclient_ httpcomponents/httpclient.jar
		_symlink org.apache.lucene.analyzers-common_ lucene/lucene-analyzers-common.jar
		_symlink org.apache.lucene.analyzers-smartcn_ lucene/lucene-analyzers-smartcn.jar
		_symlink org.apache.lucene.core_ lucene/lucene-core.jar
		_symlink org.apache.lucene.misc_ lucene/lucene-misc.jar
		_symlink org.eclipse.jetty.util_ jetty/jetty-util.jar
		_symlink org.eclipse.jetty.server_ jetty/jetty-server.jar
		_symlink org.eclipse.jetty.http_ jetty/jetty-http.jar
		_symlink org.eclipse.jetty.continuation_ jetty/jetty-continuation.jar
		_symlink org.eclipse.jetty.io_ jetty/jetty-io.jar
		_symlink org.eclipse.jetty.security_ jetty/jetty-security.jar
		_symlink org.eclipse.jetty.servlet_ jetty/jetty-servlet.jar
		_symlink org.glassfish.web.javax.servlet.jsp_ glassfish-jsp.jar
		_symlink org.kxml2_ kxml.jar
		_symlink org.sat4j.core_ org.sat4j.core.jar
		_symlink org.sat4j.pb_ org.sat4j.pb.jar
		_symlink org.tukaani.xz_ xz-java.jar
		_symlink org.w3c.css.sac_ sac.jar
		_symlink org.w3c.dom.svg_ xml-commons-apis-ext.jar
		_symlink org.xmlpull_ xpp3.jar
	popd
popd
