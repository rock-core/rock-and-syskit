---
layout: documentation
title: Conventions
sort_info: 10
---

# Conventions

In order to keep a workspace set of packages "understandable", Rock has a few
conventions that govern how packages should be named. The first one is that
packages are sorted into [broad categories](#categories). Moreover, there is a
general naming scheme, as well as a naming scheme specific to drivers.

Finally, there are [some general guidelines](#guidelines)

## Package Categories

You probably already noticed [when you've done your first Rock
install](../basics/installation.html) that the Rock packages are sorted into
sub-directories. This list of directories is more-or-less standardized, to
allow for a broad understanding of each package's role.

So far, the following categories are in use:

* **base** base types, CMake script repositories, ...
* **bundles** bundles - integration packages
* **control** packages that are related to motion control
* **data_processing** packages that are related to general data processing (e.g.
  neural network, filtering, ...)
* **drivers** packages that are related to device drivers: drivers themselves,
  and common libraries that ease their development
* **gui** GUI and visualization packages
* **image_processing** packages that are related to image processing
* **multiagent** packages that are related to multiagent / multirobot
  coordination
* **perception** packages that are related to perception (image and data processing)
* **planning** packages that are related to path and task planning
* **simulation** packages that are related to simulation
* **slam** packages that are related to localization and mapping both separately
  and as SLAM
* **test** packages that are needed for other unit tests
* **tools** packages that are related to the toolchain and/or are general
  utility packages

Moreover, each category may have an `orogen` subfolder for oroGen (component)
packages.

For the packages coming from the Rock project itself, each category has its own
organization within GitHub (e.g. rock-planning for `planning/`). The exception
are the Rock Core packages that are all in the `rock-core` organization
{: .callout .callout-info}

## Naming Schemes

Package names are all `snake_case`

On platforms like gitlab or github, the repositories are named the way packages
are named, including categories. The separator is `-`  instead of folder.

For instance, `simulation/orogen/rock_gazebo` becomes
`simulation-orogen-rock_gazebo`. 

