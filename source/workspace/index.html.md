---
layout: documentation
title: Introduction
sort_info: 0
directory_title: Workspace and Packages
directory_sort_info: 30
---

# The Workspace

This part will deal with more advanced topics regarding workspace and package
management. We will go beyond the subject of importing existing packages,
[which we have already done in the Basics
part](../basics/composition.html#add_package).

The most important design driver, when building your workspace and build
configuration, is to ensure **repeatability**. The goal is to make sure one can
at any time rebuild a workspace from scratch, of course on developer's
machines, but also in continuous integration environments, or on embedded
systems.
{: .important}

We'll first have a presentation of [the conventions that govern the structure
of a workspace](conventions.html). We'll then see [how to setup a new project,
and how to create new package sets](setup.html).

One important aspect of Rock's build system is that none of the packages
should actually rely on it. C++ Rock packages for instance rely on common build
systems such as CMake or autotools to build, and pkg-config or CMake mechanisms
to handle cross-package dependencies. Autoproj, Rock's build system, is only
handling the scheduling of the configuration and build of each the packages, so
that build systems and environment variables are set up as required, and
dependencies are handled properly.

As such, autoproj mainly needs to know two things about a package:

- what build system it uses
- how to download it

These two things are what is needed to [add a package in an autoproj build
configuration](add_packages.html)

In order to leverage the underlying OS, autoproj also allows to use OS-provided
packages, or language-specific packages -- such as Python pip packages or
RubyGems in a workspace. This will be [covered as well](os_dependencies.html).

Finally, we will go through the more general subject of [designing and managing
a build configuration](managing.html)

Let's talk first about [conventions](conventions.html)
{: .next-page}