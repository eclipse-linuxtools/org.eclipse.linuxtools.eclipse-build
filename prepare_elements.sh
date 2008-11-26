#! /bin/sh
plugins=""
first="true"
for i in $(ls -d */); do 
	if $first == "true"; then
		first=false
	else
		plugins=$plugins", "
	fi
	plugins=$plugins"plugin@"${i%%/}; 
done
echo $plugins