<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	version="1.0" xmlns:lxslt="http://xml.apache.org/xslt" xmlns:redirect="http://xml.apache.org/xalan/redirect"
	xmlns:stringutils="xalan://org.apache.tools.ant.util.StringUtils"
	extension-element-prefixes="redirect">
	<xsl:output method="xml" indent="yes" encoding="UTF-8" />

	<xsl:template match="/">
		<xsl:apply-templates />
	</xsl:template>

	<xsl:template match="testsuites">
		<xsl:apply-templates />
	</xsl:template>

	<xsl:template match="testsuite">
		<xsl:variable name="filename"
			select="concat('origXml/',@package,@name,'.xml')" />
		<redirect:write file="{$filename}">
			<xsl:copy-of select="." />
		</redirect:write>
	</xsl:template>
</xsl:stylesheet>