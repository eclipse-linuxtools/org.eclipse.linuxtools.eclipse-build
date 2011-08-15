/*******************************************************************************
 * Copyright (c) 2011 Red Hat Inc. and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors:
 *    Red Hat, Inc. - initial API and implementation
 *******************************************************************************/
package org.eclipse.linuxtools.eclipsebuild;

import java.io.File;
import java.io.FileInputStream;
import java.io.DataInputStream;
import java.io.FileOutputStream;
import java.io.DataOutputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.FileReader;
import java.io.BufferedReader;

import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.Task;

public class CorrectJarPaths extends Task {
    
    File[] files;

    // Main method for ant task
    public void execute() throws BuildException {
	FileInputStream inStream;
	DataInputStream input;

	FileOutputStream outStream;
	DataOutputStream output;

	File file;
	File outFile;

	for (int i = 0; i < files.length; i++){
	    try {
		file = new File(files[i], "build.xml");
		outFile = new File(files[i], "build.xml.out");

		inStream = new FileInputStream(file);
		input = new DataInputStream(inStream);

		outStream = new FileOutputStream(outFile);
		output = new DataOutputStream(outStream);

		String line = input.readLine();
		while (line != null) {
		    // We want to replace things like this: ../../../../../../../../../usr/lib/eclipse/plugins/
		    // with ../plugins
		    if (line.contains("../usr") && line.contains("/plugins/")){
			line = line.replaceAll("\\.\\./","");
			line = line.replaceAll("usr/lib/eclipse/plugins/","../plugins/");
			line = line.replaceAll("usr/lib64/eclipse/plugins/","../plugins/");
			line = line.replaceAll("usr/share/eclipse/plugins/","../plugins/");
		    }
		    output.writeBytes(line+"\n");
		    line = input.readLine();
		}
		outFile.renameTo(file);
	    } catch (FileNotFoundException e) {
		e.printStackTrace();
	    } catch (IOException e) {
		e.printStackTrace();
	    }
	}
    }

    public void setDir(File dir){
	this.files = dir.listFiles();
    }
}
