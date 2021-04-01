# We basically just need a Linux with Flatpak >= 1.7.1
# So it can be based on any Fedora or CentOS/RHEL >= 8.4 when it is released

FROM eclipsecbi/fedora:33

# Install flatpak tools
RUN yum -y install flatpak flatpak-builder
RUN yum clean all

# Install java
RUN yum -y install java-11-openjdk-devel
RUN yum clean all

# Install maven
ENV MAVEN_VERSION 3.6.3
RUN curl -fsSL http://archive.apache.org/dist/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz | tar xzf - -C /usr/share \
  && mv /usr/share/apache-maven-$MAVEN_VERSION /usr/share/maven \
  && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn
ENV MAVEN_HOME /usr/share/maven

# Configure flathub remote
ENV FLATPAK_GL_DRIVERS=dummy
