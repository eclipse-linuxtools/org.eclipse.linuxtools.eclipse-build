# Eclipse Flatpak

## Installation

To install the Eclipse Flatpak via the command line:

* Add the Eclipse Nightly repo

    `flatpak remote-add --if-not-exists eclipse-nightly https://download.eclipse.org/linuxtools/flatpak-I-builds/eclipse.flatpakrepo`

- To check the available products and branches run:

    `flatpak remote-ls eclipse-nightly`
  
- Install your chosen product by running:

    `flatpak install eclipse-nightly org.eclipse.Platform` or
    `flatpak install eclipse-nightly org.eclipse.Sdk`

    This will prompt you to chose a branch or abort, to skip this you can specify a branch by adding it to the command:

    `flatpak install eclipse-nightly org.eclipse.Platform master` 

For more information on Flatpak commands you can reference the official [documentation](https://docs.flatpak.org/en/latest/using-flatpak.html#basic-commands).

## Jenkins Builds

 The flatpak is built by the [flatpak-nightly](https://ci.eclipse.org/linuxtools/job/flatpak-nightly/) job in the Eclipse Linux Tools Jenkins instance using the [eclipse-flatpak-packager](https://www.eclipse.org/cbi/sitedocs/eclipse-flatpak-packager/package-flatpak-mojo.html) maven plugin. 

 *Despite being called a nightly build it polls for new [Eclipse I-Builds](https://download.eclipse.org/eclipse/updates/4.24-I-builds/) every 4 hours and builds if there is a new one.*

## Source

Source code for the Flatpak build is in the Eclipse Linux Tools [eclipse.build](https://github.com/eclipse-linuxtools/org.eclipse.linuxtools.eclipse-build) GitHub repo.

Source code for the eclipse-flatpak-packager is in the [org.eclipse.cbi](https://github.com/eclipse-cbi/org.eclipse.cbi/tree/main/maven-plugins/eclipse-flatpak-packager) GitHub repo.

