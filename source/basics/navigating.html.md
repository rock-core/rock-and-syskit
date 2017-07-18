---
layout: documentation
title: Navigating in a Workspace
sort_info: 7
---

# Day-to-day interaction with a Rock installation

This page covers the autoproj commands and behavior that make most of the days
within a Rock workspace. More advanced topics are covered later in the
documentation.

### CLI help

At any point, the autoproj CLI is documented through the --help option.

~~~
autoproj --help
~~~

### Folder Structure

<dl>
<dt>Workspace root</dt>
<dd>Where your ran <a href="index.html">the bootstrap</a>, and where the <code>env.sh</code> script is located</dd>
<dt>The autoproj/ folder</dt>
<dd>Located at the root of the workspace, it contains all the build configuration</dd>
<dt>Package</dt>
<dd>Packages are the unit that autoproj deals with. The Rock software is split
into separate types of packages that are defined in the build configuration.
The configuration tells Autoproj both the package type (how to install the
package) and where the package's source code is located (e.g. the github
repository).</dd>
<dt>OS Depedency or osdep</dt>
<dd>Packages in autoproj can either be checked out and built from source.
Alternatively, autoproj allows to interact with the host OS package system
(e.g. APT on Ubuntu). The osdep system is what makes this possible.</dd>
<dt>Build folders</dt>
<dd>When packages have build byproducts, they are saved within the package
build folder. This is by default the <code>build/</code> directory under the packages.</dd>
<dt>Prefix folder</dt>
<dd>Packages that require an install step will install under this folder. By
default the <code>install/</code> folder under the workspace root</dd>
<dt>Logs</dt>
<dd>The output of all commands ran by autoproj are redirected to separate files under <code>install/log/</code></dd>
</dl>

### Moving around {#acd}

`acd` allows to move from package to package within the workspace. Because it
is a very common operation, `acd` accepts that each part of the package name be
shortened as long as the result is unambiguous.

For instance, in the default Rock installation:

~~~
$ acd s/gaz
# Now in simulation/gazebo
$ acd c/k
multiple packages match 'c/k' in the current autoproj installation: control/kdl, control/kdl_parser
$ acd c/kdl
# Now in control/kdl
$ acd c/kdl_par
# Now in control/kdl_parser
~~~

`acd` expects package names. A few packages -- mainly orogen, typelib and rtt
-- do not include the package's category in them (they are named e.g. 'orogen'
but are installed in `tools/`)
{: .callout .callout-info}

The `-b` and `-p` options allow to move to a package's build and prefix directories. 

~~~
$ acd -b s/gaz
# Now in simulation/gazebo/build
$ acd -p c/kdl
# Now in install/
~~~

### Updating

Most of the time, you will want to update the whole workspace (the `-k` option
continues updating even if errors occur). This will also update OS
dependencies.

~~~
aup --all -k
~~~

If you want to restrict the update to a package and its dependencies, give its
name or path on the command line

~~~
aup simulation/rock_gazebo
~~~

To restrict the update to the package, excluding its dependencies, add `--deps=f`.

`--checkout-only` will not update already checked out packages, but
only check out not currently present in the system.

`aup` without arguments is equivalent to `aup .`, i.e. update the package
located in the current directory
{: .callout .callout-info}

In some situations, or if you're trying to keep track of all the changes that
are happening to your system, you want want to check what will be pulled by
`aup`. `autoproj status` allows to compare the status of the workspace w.r.t.
the repositories.

### Building

To ensure that all changes have been built, run

~~~
amake --all
~~~

As with `aup`, `-k` can be added to continue even under error. This is less
common for `amake`, though,  as a build error will usually cascade to its
dependencies.

If you want to restrict the build to a package and its dependencies, give its
name or path on the command line

~~~
amake simulation/rock_gazebo
~~~

To restrict the build to the package, excluding its dependencies, add `--deps=f`.

`amake` without arguments is equivalent to `amake .`, i.e. build the package
located in the current directory
{: .callout .callout-info}

