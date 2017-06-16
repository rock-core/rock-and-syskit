---
layout: documentation
title: Introduction
sort_info: 0
directory_title: The Workspace
directory_sort_info: 0
---

# Managing a Rock installation

A system can base itself on different "flavors" of Rock. One can basically
choose one out of three:

- **the latest release** version of the Rock Core software. Once released, it
  will not change, but may see subsequent point releases that would only differ
  by (important) bugfixes. The only way a release-based install will get modifications
  is if the developer changes the base release.
- **the stable flavor** is the last release plus bugfixes. Unlike the releases,
  updating a 'stable' system will always land you on the latest release, and
  in-between releases will get patched with bugfixes. This **does** include being
  updated automatically to new major releases.
- **the master flavor** is the development branch, and may break.

Rock's primary platform is Ubuntu. The only guarantee made by the Rock team is
that Rock's current release and master branches work on the current Ubuntu LTS
version and often works on the latest Ubuntu version.

Rock has no option to install from binary, the only currently supported method
of install is from source.

Other linux-based platforms (Debian, Arch, …) are known to work, but since they
don't see regular use, installation may not be as streamlined as on Ubuntu.
MacOS X also has seen some Rock usage, but is seldom used and therefore can
cause problems. Windows has seen some preliminary usage.

What will be covered here:

- [Rock installation on a Linux system](install.html)
- [day-to-day management of a Rock installation](day_to_day.html)
- debugging common problems

