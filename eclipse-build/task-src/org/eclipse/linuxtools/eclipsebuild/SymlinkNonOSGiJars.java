/*******************************************************************************
 * Copyright (c) 2010 Red Hat Inc. and others.
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
import java.io.FileNotFoundException;
import java.io.IOException;
import java.util.Iterator;
import java.util.Properties;
import java.util.Set;

import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.taskdefs.Mkdir;

public class SymlinkNonOSGiJars extends SymlinkJars {

	private Properties dependencies;

	// Main method for ant task
    public void execute() throws BuildException {
    	Set<Object> jarLocations = dependencies.keySet();
    	for (Iterator<Object> jarIter = jarLocations.iterator(); jarIter.hasNext();) {
			
    		String origLocation = (String) jarIter.next();
			
			String systemLocations = (String) dependencies.get(origLocation);
			String[] systemLocationList = systemLocations.split(":");
			String attemptedLocations = "";
			for (int j = 0; j < systemLocationList.length; j++) {
				if (j == 0)
					attemptedLocations = systemLocationList[j];
				else
					attemptedLocations = attemptedLocations + ", "
							+ systemLocationList[j];
			}
			boolean matched = false;
			for (int i = 0; i < systemLocationList.length; i++) {
				File systemFile = new File(systemLocationList[i].trim());
				if (systemFile.exists()) {
					matched = true;
					// FIXME:  do symlinking
					log("Symlinking " + origLocation + " -> "
							+ systemFile.getAbsolutePath(), Project.MSG_DEBUG);
					
					Mkdir m = new Mkdir();
					m.setDir(new File(topLevelDir + "/" + origLocation).getParentFile());
					m.execute();
					
					symlinkJar (new File(topLevelDir + "/" + origLocation), topLevelDir + "/" + origLocation, systemFile);
				}
			}
			if (!matched) {
				throw new BuildException(
						"Could not find suitable system JAR for "
								+ origLocation + ".  Tried:  "
								+ attemptedLocations);
			}
		}
    }

	public void setDependencies(File dependencyProperties) {
		dependencies = new Properties();
		FileInputStream fis;
		try {
			fis = new FileInputStream(dependencyProperties);
			dependencies.load(fis);
			fis.close();
		} catch (FileNotFoundException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}

}
