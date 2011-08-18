package org.eclipse.linuxtools.eclipsebuild;

import java.io.File;

import org.apache.tools.ant.Task;
import org.apache.tools.ant.taskdefs.Copy;
import org.apache.tools.ant.taskdefs.Delete;
import org.apache.tools.ant.taskdefs.optional.unix.Symlink;

public class SymlinkJars extends Task {

	protected String topLevelDir;
	private boolean copyFiles;

	protected void symlinkJar(File fileToDelete, String fileToSymlink,
			File matchedJar) {

		// First, delete any existing symlink
		Delete d = new Delete();
		d.init();
		d.setFile(fileToDelete);
		d.execute();

		if (copyFiles) {
			// copy file over
			Copy c = new Copy();
			c.init();
			c.setFile(matchedJar);
			c.setTofile(new File(fileToSymlink));
			c.execute();
		} else {
			// Then make the actual symlink
			Symlink s = new Symlink();
			s.init();
			s.setLink(fileToSymlink);
			s.setResource(matchedJar.getAbsolutePath());
			s.execute();
		}
	}

	public void setTopleveldir(String topLevelDir) {
		this.topLevelDir = topLevelDir;
	}

	public void setCopyFiles(boolean copyFiles) {
		this.copyFiles = copyFiles;
	}

}
