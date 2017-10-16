#!/bin/bash

REPO=${REPO_LOC:-nightly}
mkdir -p $REPO

GPG_KEY=573CD528
GPG_HOME=~/.gnupg
GPG_OPTS="--gpg-sign=$GPG_KEY --gpg-homedir=$GPG_HOME"

flatpak-builder --force-clean --repo=$REPO/repo $GPG_OPTS eclipse-sdk org.eclipse.Sdk.json
flatpak build-update-repo --generate-static-deltas $GPG_OPTS $REPO/repo

gpg --export $GPG_KEY > $REPO/key.gpg
PUB_KEY=$(base64 --wrap=0 < $REPO/key.gpg)
URL="http://eclipse.matbooth.co.uk/flatpak/nightly/repo"

# Generate repo file
cat <<EOF > ${REPO}/eclipse-nightly.flatpakrepo
[Flatpak Repo]
Title=Eclipse SDK I-Builds
Comment=Eclipse SDK I-Builds
Homepage=https://www.eclipse.org/
Url=$URL
GPGKey=$PUB_KEY
EOF

# Generate ref file
cat <<EOF > ${REPO}/org.eclipse.Sdk.flatpakref
[Flatpak Ref]
Title=Eclipse SDK
Name=org.eclipse.Sdk
Branch=master
Url=$URL
IsRuntime=False
RuntimeRepo=https://flathub.org/repo/flathub.flatpakrepo
GPGKey=$PUB_KEY
EOF
