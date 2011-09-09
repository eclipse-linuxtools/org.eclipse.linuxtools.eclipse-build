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
import java.util.jar.Attributes;
import java.util.jar.JarFile;
import java.util.jar.Manifest;

import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.Project;

public class SymlinkOSGiJars extends SymlinkJars {

	private String[] importantManifestEntries = { "Bundle-SymbolicName", "Bundle-Version", "Export-Package" };

	private Properties dependencies;
	private String manifestsDir;
	
	// Main method for ant task
    public void execute() throws BuildException {
    	Set<Object> jarLocations = dependencies.keySet();
    	for (Iterator<Object> jarIter = jarLocations.iterator(); jarIter.hasNext();) {
			
    		// Binary MANIFEST.MF
    		String origLocation = (String) jarIter.next();
    		String origManifestFile = manifestsDir + "/" + origLocation + "/META-INF/MANIFEST.MF";
    		Attributes origAttributes = getAttributesFromManifest(origManifestFile);
			
			String systemLocations = (String) dependencies.get(origLocation);
			String[] systemLocationList = systemLocations.split(":");
			String matchedJarBundleNameVersion = "";
			Attributes systemAttributes = null;
			File matchedJar = null;

			for (int i = 0; i < systemLocationList.length; i++) {
				File systemFile = new File(systemLocationList[i].trim());
				if (!systemFile.exists())
					continue;
				log("Seeing if " + systemFile + " is a suitable match for " + origLocation, Project.MSG_DEBUG);

				JarFile systemJarFile;
				Manifest systemManifest = null;
				try {
					systemJarFile = new JarFile(systemFile);
					// System MANIFEST.MF
					systemManifest = systemJarFile.getManifest();
				} catch (IOException e) {
					// not a JAR file or can't be read
				}
				if (systemManifest == null)
					break;
				
				systemAttributes = systemManifest.getMainAttributes();
				if (compareImportantAttributes(origAttributes, systemAttributes)) {
					matchedJar = systemFile;
					String matchedJarBundleName =
						systemAttributes.getValue("Bundle-SymbolicName");
					matchedJarBundleName =
						matchedJarBundleName.replace("; singleton:=true", "");
					matchedJarBundleNameVersion =
						matchedJarBundleName
						+ "_" + systemAttributes.getValue("Bundle-Version");
					break;
				}
			}
			
			if (matchedJar == null) {
				String noSystemJarMsg = buildNoSystemJarMsg(origLocation, systemLocationList);
				throw new BuildException(noSystemJarMsg);
			}
			
			symlinkJar (new File(topLevelDir + "/" + origLocation), topLevelDir + "/" + origLocation, matchedJar);
		}
    }

	private Attributes getAttributesFromManifest(String origManifestFile) {
		Manifest origManifest = new Manifest();
		try {
			FileInputStream origManifestStream = new FileInputStream(origManifestFile);
			origManifest.read(origManifestStream);
			origManifestStream.close();
		} catch (Exception e) {
			throw new BuildException("Couldn't read original MANIFEST.MF:  " + origManifestFile);
		}
		Attributes origAttributes = origManifest.getMainAttributes();
		return origAttributes;
	}
	
	private boolean compareImportantAttributes(Attributes origAttributes,
			Attributes systemAttributes) {
		boolean isAMatch = true;
		for (int j = 0; j < importantManifestEntries.length; j++) {
			String attributeToCheck = importantManifestEntries[j];
			String origAttribute = (String) origAttributes
					.getValue(attributeToCheck);
			String systemAttribute = (String) systemAttributes
					.getValue(attributeToCheck);
			if (attributeToCheck.equals("Bundle-Version")) {
				// System version should be higher; ignore qualifier
				String[] origVersionSegments = origAttribute.split("\\.");
				String[] systemVersionSegments = systemAttribute.split("\\.");
				// Orbit JARs always have major.minor.micro.qualifier
				Integer origInteger = new Integer(origVersionSegments[0]) * 100
						+ new Integer(origVersionSegments[1]) * 10
						+ new Integer(origVersionSegments[2]);
				// System JARs sometimes don't have 4 parts
				int maxSegments = systemVersionSegments.length;
				if (systemVersionSegments.length > 3)
					maxSegments = 3;
				Integer systemInteger = new Integer(0);
				for (int m = 0; m < maxSegments; m++) {
					systemInteger = systemInteger
							+ new Integer(systemVersionSegments[m])
							* (int) Math.pow(10, (2 - m));
				}
				if (systemInteger < origInteger) {
					isAMatch = false;
					break;
				}
			} else if (attributeToCheck.equals("Export-Package")) {
				if (origAttribute != null && systemAttribute != null) {
					if (!origAttribute.equals(systemAttribute)) {
						log("Export-Package attributes do not match for "
								+ origAttributes
										.getValue("Bundle-SymbolicName"),
								Project.MSG_WARN);
					}
				}
			} else {
				if (origAttribute != null && systemAttribute != null) {
					if (!origAttribute.equals(systemAttribute)) {
						isAMatch = false;
						break;
					}
				} else {
					isAMatch = false;
					break;
				}
			}
		}
		return isAMatch;
	}
	
	private String buildNoSystemJarMsg(String origLocation,
			String[] systemLocationList) {
		String attemptedLocations = "";
		for (int j = 0; j < systemLocationList.length; j++) {
			if (j == 0)
				attemptedLocations = systemLocationList[j];
			else
				attemptedLocations = attemptedLocations + ", "
						+ systemLocationList[j];
		}
		return "Could not find suitable system JAR for " + origLocation
				+ ".  Tried:  " + attemptedLocations;
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

	public void setManifests(String manifests) {
		this.manifestsDir = manifests;
	}
}
