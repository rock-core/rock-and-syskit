---
layout: documentation
title: Designing and managing a build configuration
sort_info: 50
---

# Designing and managing a build configuration
{:.no_toc}


- TOC
{:toc}

This page will deal with the overall design patterns that involve a build
configuration, and will answer some common "How do I ?" questions.

Even though it would be ideal, it is rare that all systems can share **exactly**
the same build configuration. The prime example of this is embedded/developer's
systems (the former does requires neither the simulation environment nor the
GUIs). Moreover, one also sometimes needs to setup configuration in shared
package sets to account for variations in projects that share said package set.

There is a fine line to thread when it comes to making things optional. Build
configurations with too many options are really hard to maintain, and in my
experience do not actually provide major benefits (apart from the NMH-like
feeling that you can "tune your install exactly to your needs"). Be careful to
not over-design your build configurations, and try to stick to the few cases
where it really makes sense.
{: .important}

## On GUI code in embedded systems

Do not build GUI and simulation elements **in** the normal codeflow "just for
debugging purposes". This is a Really Bad Idea (tm) when it comes to autonomous
robots. Autonomous robots, by definition, will run headless, and these pieces
of code are basically time-bombs. Moreover, if anything wrong happens during a
mission, you will by definition not have access to this data.

Instead, build diagnostic and debugging data structures, and make sure they can
be exported out of your API. From there, one can put in on component ports and
log it when necessary.

## Package set structure

There is a cost in having too many package sets. Usually one should strive in
not separating too much, because their interactions can become hard to
understand (especially when it comes to [osdeps](os_dependencies.html) or
[version control overrides](add_packages.html#version_control_resolution).

Splitting package sets is most often not needed. Package sets only define
packages, not anything else, and as such one does not need to build
**everything** in the package set.  If subsets of the packages are often used,
one can easily group them using metapackages ([see below](#metapackages))

Generally speaking, start with one project for your organization and one for
projects - for big projects.

## Metapackages {#metapackages}

Autoproj allows you to group packages into subsets called _metapackages_.
Metapackages, when used, resolve to their list of packages. The main use-case
for this is to create sets of packages for different machine roles - such as
a developer's machine or the embedded systems.

They are declared in the `autobuild` files with:

~~~
metapackage 'name_of_metapackage',
  'pkg1', 'pkg2', 'pkg3', …
~~~

All packages defined in a package set are automatically added into two
metapackages: the `package_set_name` metapackage and the `package_set_name.all`
metapackage. We are using this when we recommend to [add the package set to the
manifest's `layout`](setup.html#add_package_set_in_layout). If a package should
not end up in this default metapackage, it can removed after it has been
defined with:

~~~
remove_from_default 'pkg1', 'pkg2'
~~~

**Tip**: packages from other package sets can also be added to the default package
set with `add_to_default 'pkg1', 'pkg2', …`. Use this to create a "default set of
packages.
{: .tip}

## Choosing what to build where

Now that we've built sets of packages from our roles, there is still the issue
of _avoiding_ building some packages in some roles, regardless of package
dependencies. One can force autoproj to _not_ build a package by listing its
name in the `exclude_packages` section of the manifest. So, you can usually
avoid building any GUI and simulation stuff by adding:

~~~yaml
exclude_packages:
- simulation/.*
- gui/.*
~~~

Exclusions are recursive, that is a package that would depend on a simulation
or GUI package will also be excluded. Also, the system is a
"exclude-then-include", so if you want to exclude all simulation packages _but_
e.g. `simulation/rock_gazebo`, you would do:

~~~yaml
layout:
- …
- simulation/rock_gazebo

exclude_packages:
- simulation/.*
~~~

By default, autoproj will fail to build if a package set depends on an excluded
package. This is the recommended default for the "terminal" package sets --
such as the metapackages you will have defined for your project. However,
shared package sets sometime require to be more lax. The default can be changed
after the metapackage is defined with:

~~~
metapackage('company.project').weak_dependencies = true
~~~

Because exclusions are done within the build configuration manifest, it
requires having one manifest per system role. The best way to handle this is to
actually have multiple manifest files with a `.role` suffix (e.g.
`autoproj/manifest.dev`). The "local" manifest file can then be selected with

~~~
autoproj manifest autoproj/manifest.dev`
~~~

**Tip**: keep the default manifest the 'developer' manifest and use this
mechanism for development roles.
{: .tip}

## Optional Dependencies

As we just saw, excluding a package auto-excludes packages that depends on it.
In the common exclusion cases (simulation and GUI), this is not a desired
outcome. One would like to put visualization and actual code in the same
packages, but avoid building GUI/simulation elements on systems that don't
need it.

Inside packages, this has to be done the "traditional" way, that is by checking
whether dependencies are present and avoiding building parts of the package if
they are not.

At the Autoproj level, it requires listing dependencies as "optional" by using
the `<depend_optional …>` tag instead of `<depend …>`. Optional dependencies
act as "normal" dependencies by default. Only when the depended-upon package is
excluded do they differ in behavior.

## Configuration Options {#configuration_options}

Autoproj also has an interface to ask the developer configuration questions,
that can then be used either in the version control information, or within the
autobuild files to build optional behavior.

You've already seen those when bootstrapping Rock

Configuration options can be declared in an `.autobuild` file, within the
`init.rb` file of the package set or in `autoproj/init.rb` with:

~~~ruby
Autoproj.config.define 'CONFIGURATION_OPTION_NAME',
  type: 'boolean', # 'boolean' or 'string'
  doc: ['first line',
        'second line',
        'third line'],
  default: true, # true or false for boolean, an arbitrary string otherwise
  possible_values: ['list', 'of', 'acceptable', 'values'],
  lowercase: false, # convert the user input to lowercase
  uppercase: false, # convert the user input to uppercase
~~~

Autoproj will ask the user for the option's value the first time the option is
used. Once the user answered a valid answer, Autoproj saves the value and will not
ask again until the user runs `autoproj reconfigure`.

Within `.autobuild` files, the configuration options are accessed with

~~~ruby
Autoproj.config.get 'CONFIGURATION_OPTION_NAME'
~~~

Within the version control information, it is expanded using the
`$CONFIGURATION_OPTION_NAME` syntax.

That's all for the Workspace documentation. Go back to the [documentation main
index](../index.html#how_to_read){: .btn-next-page} for more topics.

