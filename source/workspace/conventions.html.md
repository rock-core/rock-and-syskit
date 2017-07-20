---
layout: documentation
title: Conventions
sort_info: 10
---

# Conventions
{:.no_toc}

- TOC
{:toc}


In order to keep a workspace set of packages "understandable", Rock has a few
conventions that govern how packages should be named. The first one is that
packages are sorted into broad categories. Moreover, there is a general naming
scheme, as well as a naming scheme specific to drivers.

## Package Categories {#categories}

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

## Naming Schemes {#naming}

**How to pick a name**. As the joke goes, there are only two difficult things
in software engineering: naming things and cache invalidation. Picking a good
package name is _hard_. Beyond the few conventions listed below, the most
important is to avoid picking a too generic name. `planning` or
`trajectory_generation` or `vehicle_control` are all waaaaay to generic. One
cannot assume that there would ever be a single trajectory generation, planning
or vehicle control package out there, _ever_. Instead, try to identify what
makes _your_ planning, _your_ trajectory generation or _your_ vehicle control
different from others: what type of vehicle ? Which method(s) do you plan to
use ? If you do intend to develop a "completely generic" package that solves
The Underlying Problem(tm), then find a catchy name or acronym - OMPL, MoveIt!,
PCL are for instance all generic packages that are not polluting the package
namespace.
{: .tip}

Package names are all `snake_case`

On platforms like gitlab or github, the repositories are named the way packages
are named, including categories. The separator is `-`  instead of folder.

For instance, `simulation/orogen/rock_gazebo` becomes
`simulation-orogen-rock_gazebo`. When the orogen component is mainly tied to
one single library package, it is expected to have the same name than said
package (e.g. `simulation/rock_gazebo` and `simulation/orogen/rock_gazebo`)

The **drivers** category naming scheme is to explicitely list the device,
manufacturer and device type if the driver is valid only for one device,
following the scheme: `devicetype_manufacturer` or
`devicetype_manufacturerModel`. The `devicetype` is not standardized,
developers are expected to use their best judgment - and check what already
exists !

