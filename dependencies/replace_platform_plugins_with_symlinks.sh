# This script replaces all plugins in platform that can be replaced with symlinks
# It goes into a folder that is first argument of the script
# Then into plugins, and then symlinks 

# SCL java dir is different from default

set -e

SCL_JAVA_DIRS=${@:2}

function _symlink {
	_f=`ls | grep -e "^$1"`
	rm -rf $_f
	for SCL_JAVA_DIR in ${SCL_JAVA_DIRS}; do
		if [ -f ${SCL_JAVA_DIR}/$2  ]; then
			echo "found ${SCL_JAVA_DIR}/$2"
			ln -s ${SCL_JAVA_DIR}/$2 ${_f%.jar}.jar
			return 0
		fi
	done
	echo "not found $2 in any of ${SCL_JAVADIRS}"
	exit 1
}

pushd $1
	# Remove and symlink all duplicate jars in the platform
	pushd plugins
		_symlink com.ibm.icu_ icu4j/icu4j.jar
		_symlink com.jcraft.jsch_ jsch.jar 
		_symlink com.sun.el.javax.el_ glassfish-el.jar
		_symlink javax.xml_ xml-commons-apis.jar
		_symlink javax.inject_ atinject.jar
		_symlink javax.servlet.jsp_ glassfish-jsp-api/javax.servlet.jsp-api.jar
		_symlink javax.servlet-api_ glassfish-servlet-api.jar
		_symlink org.apache.batik.css_ batik/batik-css.jar
		_symlink org.apache.batik.util_ batik/batik-util.jar
		_symlink org.apache.batik.util.gui_ batik/batik-gui-util.jar
		_symlink org.apache.httpcomponents.httpcore_ httpcomponents/httpcore.jar
		_symlink org.apache.httpcomponents.httpclient_ httpcomponents/httpclient.jar
		_symlink org.apache.commons.codec_ commons-codec.jar
		_symlink org.apache.commons.jxpath_ commons-jxpath.jar
		_symlink org.apache.commons.logging_ commons-logging.jar
		_symlink org.apache.felix.gogo.command_ felix-gogo-command/org.apache.felix.gogo.command.jar
		_symlink org.apache.felix.gogo.runtime_ felix/felix-gogo-runtime.jar
		_symlink org.apache.felix.gogo.shell_ felix-gogo-shell/org.apache.felix.gogo.shell.jar
		_symlink javax.annotation-api_ glassfish-annotation-api.jar
		_symlink org.apache.lucene.core_ lucene/lucene-core.jar
		_symlink org.apache.lucene.analyzers-common_ lucene/lucene-analyzers-common.jar
		_symlink org.apache.lucene.analyzers-smartcn_ lucene/lucene-analyzers-smartcn.jar
		_symlink org.apache.lucene.queries lucene/lucene-queries.jar
		_symlink org.apache.lucene.queryparser lucene/lucene-queryparser.jar
		_symlink org.apache.lucene.sandbox lucene/lucene-sandbox.jar
		_symlink org.apache.xalan xalan-j2.jar
		_symlink org.apache.xerces xerces-j2.jar
		_symlink org.apache.xml.resolver xml-commons-resolver.jar
		_symlink org.apache.xml.serializer xalan-j2-serializer.jar
		_symlink org.eclipse.jetty.util_ jetty/jetty-util.jar
		_symlink org.eclipse.jetty.server_ jetty/jetty-server.jar
		_symlink org.eclipse.jetty.http_ jetty/jetty-http.jar
		_symlink org.eclipse.jetty.continuation_ jetty/jetty-continuation.jar
		_symlink org.eclipse.jetty.io_ jetty/jetty-io.jar
		_symlink org.eclipse.jetty.security_ jetty/jetty-security.jar
		_symlink org.eclipse.jetty.servlet_ jetty/jetty-servlet.jar
		_symlink org.glassfish.web.javax.servlet.jsp_ glassfish-jsp.jar
		_symlink org.sat4j.core_ org.sat4j.core.jar
		_symlink org.sat4j.pb_ org.sat4j.pb.jar
		_symlink org.tukaani.xz_ xz-java.jar
		_symlink org.w3c.css.sac_ sac.jar
		_symlink org.w3c.dom.svg_ xml-commons-apis-ext.jar
	popd

	# Remove and symlink all duplicate jars in the jdt feature
	pushd dropins/jdt/plugins
		_symlink org.hamcrest.core_ hamcrest/core.jar
		_symlink org.junit_4 junit.jar
	popd

	# Remove and symlink all duplicate jars in the pde feature
	pushd dropins/sdk/plugins
		_symlink org.objectweb.asm_ objectweb-asm/asm.jar
		_symlink org.objectweb.asm.tree_ objectweb-asm/asm-tree.jar
	popd
popd
