#!/bin/sh

java -cp @LAUNCHER@ org.eclipse.core.launcher.Main \
     -application org.eclipse.jdt.core.JavaCodeFormatter \
     ${1+"$@"}
