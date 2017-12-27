---
layout: documentation
title: Day-to-day Workspace Commands
sort_info: 7
---

# Day-to-day workspace commands
{:.no_toc}

- TOC
{:toc}

This page covers the autoproj commands and behavior that make most of the days
within a Rock workspace. More advanced topics are covered later in the
documentation.

### CLI help

At any point, the autoproj CLI is documented through the --help option.

~~~
autoproj --help
~~~

### Folder Structure {#layout}

<dl markdown="0">
<dt>Workspace root</dt>
<dd>Where your ran <a href="index.html">the bootstrap</a>, and where the <code>env.sh</code> script is located</dd>
<dt>The autoproj/ folder</dt>
<dd>Located at the root of the workspace, it contains all the build configuration</dd>
<dt>Remotes</dt>
<dd>The package build configuration downloaded by Autoproj, they are made available in autoproj/remotes/</dd>
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
<dt id="build_directory">Build folders</dt>
<dd>When packages have build byproducts, they are saved within the package
build folder. This is by default the <code>build/</code> directory under the packages.</dd>
<dt id="prefix_directory">Prefix folder</dt>
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
$ acd d/g
# Now in drivers/gps_base
$ acd c/k
multiple packages match 'c/k' in the current autoproj installation: control/kdl, control/kdl_parser
$ acd c/kdl
# Now in control/kdl
$ acd c/kdl_par
# Now in control/kdl_parser
~~~

`acd` expects package names or package directories. A few packages -- mainly
orogen, typelib and rtt -- do not include the package's category in them (they
are named e.g. 'orogen' but are installed in `tools/`). `autoproj show
path/to/directory` will allow you to find this out.
{: .callout .callout-info}

The `-b` and `-p` options allow to move to a package's [build](#build_directory) and [prefix](#prefix_directory) directories.

~~~
$ acd -b d/gps
# Now in drivers/gps_base/build
$ acd -p c/kdl
# Now in install/
~~~

### Logs {#alog}

During build, and less often during updates, the tools autoproj calls will
error out. However, to keep the output of autoproj manageable, it redirects the
command output - where the error details usually are - to separate files.

When one error does happen, autoproj displays the last 10 lines of that
command. The intent is that these 10 lines may contain the error. If it does
not, the easiest way to display the output of the failed command is to run
`alog` with either the name of the failed package or its path

~~~
alog name/of/package
alog path/to/package
~~~

Or, if your shell is already within a folder of said package,

~~~
alog .
~~~

**Note** that the logs are ordered by last modified date (the most recently
modified being first). The first entry is therefore most likely the one you're
looking for after an update or build failure.
{: .tip}

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

If given the path to a directory (as opposed to an actual package), it will
update all packages under this directory

~~~
# Update all drivers libraries and orogen packages
aup drivers/
~~~

Without arguments, it will update the package within the current directory

~~~
aup
# Which is basically equivalent to
aup .
~~~

If you want to update a package but not its dependencies, use `-n`, e.g.

~~~
aup -n
aup -n simulation/rock_gazebo
cd simulation
aup -n rock_gazebo
~~~

Finally, if you want to checkout missing packages, but without updating already
checked out packages, use `--checkout-only`. This is useful if you want to
install new packages, but not modify the already-installed ones.

~~~
# Checkout all missing packages in the dependency chain of drivers/orogen/iodrivers_base
aup --checkout-only drivers/orogen/iodrivers_base
~~~

All `aup` commands that concern specific package(s) will __not__ update the
workspace configuration. To update everything __including the configuration__,
either run `aup` from within the workspace root, or `aup --all` from any
directory. If you want to only update the configuration, do `aup --config`
{: .callout .callout-info}

In some situations, or if you're trying to keep track of all the changes that
are happening to your system, you want want to check what will be pulled by
`aup`. `autoproj status` allows to compare the status of the workspace w.r.t.
the repositories. In case the changes would modify the configuration, it's a
good idea to first update the configuration and re-run `autoproj status` to
include possible changes in the package source information:

~~~
aup --config
autoproj status
~~~

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

To restrict the build to the package, excluding its dependencies, add `-n`.

`amake` without arguments is equivalent to `amake .`: update the package
located in the current directory. If called outside of a package, it means
"update all packages under this directory". `amake` in the root of the workspace
is therefore equivalent to `amake --all`.
{: .callout .callout-info}

### Configuration

Build configurations may have some configuration options. These options are
asked during the first build. If you need to change the answers after the first
run, execute

~~~
autoproj reconfigure
~~~

### Running Tests {#test}

Test suites are expensive to build, and one does not want every test suite from
every package to be available at all time. For this reason, test suite building
is by default disabled for all packages. If you do want to use/develop the test
suite of a package (great idea !), you need first to enable it, update and
rebuild. The 'update' step is needed as some dependencies are only installed
for the purpose of testing.

From within the package's directory,

~~~
autoproj test enable .
aup --no-deps
amake
~~~

`autoproj disable path/to/package` does the reverse.

Use `autoproj test list` to see which packages do have a test suite and for
which packages it is enabled.

Running the tests can either be done using the package's test method, or through
autoproj by running

~~~
autoproj test .
~~~

If you do want to enable all unit tests for all packages, run `enable` without
arguments. `disable` without arguments disables all test suites.

**Next**: let's get to [create our first system integration](getting_started.html)
{: .next-page}

