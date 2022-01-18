# We basically just need a Linux with Flatpak >= 1.7.1
# So it can be based on any Fedora or CentOS/RHEL >= 8.4 when it is released

FROM eclipsecbi/fedora:35

# Install latest updates
RUN dnf -y update --setopt=install_weak_deps=False

# Install java
RUN dnf -y install --setopt=install_weak_deps=False java-11-openjdk-devel
# Install flatpak tools
RUN dnf -y install --setopt=install_weak_deps=False flatpak ostree openssh-clients

RUN dnf clean all

# Install maven
ENV MAVEN_VERSION 3.8.4
RUN curl -fsSL http://archive.apache.org/dist/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz | tar xzf - -C /usr/share \
  && mv /usr/share/apache-maven-$MAVEN_VERSION /usr/share/maven \
  && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn
ENV MAVEN_HOME /usr/share/maven
ENV MAVEN_OPTS -Xmx1024m

# Configure flathub remote
ENV FLATPAK_GL_DRIVERS=dummy
