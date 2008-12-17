#! /bin/sh
plugins=""
first="true"
for i in $(ls -d */); do 
	if $first == "true"; then
		first=false
	else
		plugins=$plugins", "
	fi
	if [ "${i%%/}" = "org.eclipse.equinox.http.jetty_2.0.0" ]; then
		continue
	fi
	plugins=$plugins"plugin@"${i%%/}; 
done
echo $plugins
