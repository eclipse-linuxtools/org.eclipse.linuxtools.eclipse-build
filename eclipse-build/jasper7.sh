#! /bin/bash
label=$1

for f in `find ./build/eclipse-${label}-src/plugins -name build.xml`; do
        sed -i 's/javax\.servlet_2\.5\.0\.v[0-9]\{12\}/javax\.servlet_3\.0\.0/g' ${f}
        sed -i 's/javax\.servlet\.jsp_2\.0\.0\.v[0-9]\{12\}/javax\.servlet\.jsp_2\.2\.0/g' ${f}
        sed -i 's/org\.apache\.jasper_5\.5\.17\.v[0-9]\{12\}/org\.apache\.jasper_7\.0\.21/g' ${f}
done
