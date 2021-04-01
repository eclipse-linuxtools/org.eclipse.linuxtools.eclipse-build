#!/usr/bin/bash

podman build -t docker.io/mbooth101/fedora-flatpak-builder:latest .
podman login docker.io
podman push docker.io/mbooth101/fedora-flatpak-builder:latest

