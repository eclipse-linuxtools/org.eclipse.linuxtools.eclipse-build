cat pluginVersions.properties | grep $1.$2, | sed "s/$2,/$3,/"
cat pluginVersions.properties | grep $1.$2, | sed "s/$2,/$3,/" >> pluginVersions.properties
