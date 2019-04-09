---
layout: documentation
title: OS Dependencies
sort_info: 40
---

# Using OS Package Managers
{:.no_toc}

- TOC
{:toc}


While the main purpose of Autoproj is to build packages from source, it would
be silly to not rely on prebuilt packages offered by the underlying operating
system. Autoproj does it by integrating with other package managers. One may
also automatically fall back to source-based packages on platforms where the
prebuilt package is either not suitable (e.g. too old or too new), or not
available.

The main purpose of the osdeps system is to provide a mapping from a package
name (which is arbitrary) to a set of packages that should be installed by
external means. We will see examples of this in follow-up sections.

There are mainly two types of "os dependencies" (a.k.a. osdeps) in autoproj.
First is the package system offered by the platform itself (e.g. APT on Ubuntu).
Second is external package managers that can be installed on top of a platform,
such as RubyGems for Ruby.

## osdeps files

OS dependencies ("osdeps") are listed in a YAML file with the `.osdeps`
extension. One usually creates a single `packages.osdeps` file in new package
sets for this purpose. `.osdeps` files can also be added in the main build
configuration.

The general format of the YAML file is that of:

~~~yaml
package_name:
  … osdep definition …
~~~

Unlike with [the version control
entries](add_packages.html#version_control_resolution), osdep files both define
which packages are available and what is the definition of these packages.
**Like** the version control entries, Autoproj resolves the package in all
osdep files it can find (first in package sets as ordered by the `package_set`
entry in `autoproj/manifest` and then in the build configuration). Entries
override each other, and the last entry wins.

One can always inspect the state of an osdep package with `autoproj show`:

~~~
$ autoproj show thor
the osdep 'thor'
  apt-dpkg: ruby-thor
  1 matching entries:
    in /home/doudou/dev/vanilla/rock-website/autoproj/remotes/rock.core/rock.osdeps:
        debian: ruby-thor
      ubuntu:
        precise: gem
        default: ruby-thor
      default: gem
~~~

This section will be all about the OS dependencies: first how to declare them
and then general "cookbook-style" patterns that offer fine-grained setup of the
osdeps usage.

## The Platform's Package Manager

When using the platform package manager, one does not list the package
manager's name, but resolves packages by the platform name and (optionally)
version. Autoproj auto-detects the platform, and knows which package manager
should be used. For instance, Ubuntu 16.04 would be listed as:

~~~
package_name:
  ubuntu:
    '16.04': # The quotes are needed, or YAML interprets 16.04 as a number.
    - name_of_apt_package
    - name_of_another_apt_package
~~~

Autoproj supports the following platforms. The first word is the codename for
the platform, that should be used in the osdeps files. The rest gives details
about which package manager is being used.

<dl>
<dt>`ubuntu` and `debian`
</dt>
<dd>Respectively Ubuntu and Debian, using APT. In addition to the package
name, a package version constraint can appended to a package name, e.g.
`package_name=1:2.0.3`.
</dd>
<dt>`gentoo`
</dt>
<dd>Gentoo using emerge
</dd>
<dt>`macos-brew`
</dt>
<dd>MacOSX HomeBrew, used by default when running on MacOSX.
</dd>
<dt>`macos-port`
</dt>
<dd>MacPorts can be used instead of HomeBrew on MacOSX by setting
`AUTOPROJ_MACOSX_PACKAGE_MANAGER` to `macos-port`.
</dd>
<dt>`arch`
</dt>
<dd>Arch, using pacman
</dd>
<dt>`rhel` and `fedora`
</dt>
<dd>RedHat Entreprise Linux and Fedora, using `yum`
</dd>
<dt>`opensuse`
</dt>
<dd>OpenSUSE using zipper
</dd>
<dt>`freebsd`
</dt>
<dd>FreeBSD using pkg
</dd>
</dl>

How Autoproj detects your system, and which package manager it will attempt to
use can be found with

~~~
$ autoproj osdeps --system-info
OS Names:    ubuntu, debian
OS Versions: 16.04, 16.04.2, lts, xenial, xerus
OS Package Manager: apt-dpkg
Available Package Managers: gem, pip
~~~

Because some platforms share an underlying system (and a lot of packages) with
others, there are also some fallbacks. In the example above, the Ubuntu system
will use the `debian` entries if there are no `ubuntu` entries. Additionally,
most Debian derivatives will attempt to install the `debian` packages even if
they have no specific detection logic for them. A RHEL system will use a
`fedora` entry if no `rhel` entry is present

Finally, the `default` entry allows to match "any version not explicitely
listed". For instance, the following `default` entry would match any Ubuntu
version that is not 15.10:

~~~
package_name:
  ubuntu:
    '15.10':
    - name_of_apt_package
    - name_of_another_apt_package
    default:
    - name_of_apt_package
~~~

Multiple platform names and versions can be listed in the keys, separated by
commas. The following will in effect provide both a "neither 15.04 nor 15.10"
entry for Ubuntu and share that entry with all Debian-based, non-Ubuntu,
systems.

~~~
package_name:
  ubuntu,debian:
    '15.04,15.10':
    - name_of_apt_package
    - name_of_another_apt_package
    default:
    - name_of_apt_package
~~~

## OS Independent Package Managers

Autoproj supports a few package managers that are not tied to a specific
platform. These package managers have codenames that are used within the osdep
files to refer to them:

- `gem`: RubyGems (Ruby packages)
- `pip`: PIP (Python packages)

The most common usage for them is to simply install a package:

~~~
package_name:
  manager_name:
  - manager_package_name
  - another_manager_package_name
~~~

However, one sometimes wants to also scope the os-independent packages by the
platform or platform+version on which autoproj runs. This is supported simply
by putting the os-independent package definition in the relevant part of the
tree:

~~~
package_name:
  ubuntu:
    '16.04:
    - gem: a_gem_package # Installed only on Ubuntu 16.04
    gem: another_gem_package # Installed on all Ubuntus
  gem: yagp # Installed on all operating systems
~~~

## The RubyGem Package Manager

This package manager allows to install RubyGems, the Ruby programming
language's mainstream package manager. Autoproj delegates the management
of these packages to [Bundler](http://bundler.io).

The installed gems are shared across all your workspaces, in the
`$HOME/.autoproj/gems` folder. Bundler ensures that the right versions are
enabled for a given workspace, regardless of gems that might have been
installed by other workspaces. This speeds up bootstrapping quite a bit, as the
common gem install location ensures that they have to be installed only once.

The Gemfile and the bundler binstubs are installed in [the workspace's
prefix](../basics/day_to_day.html#layout) under `gems/`. `gems/bin/` is
automatically added to the PATH.

The package manager supports explicit version constraints within the osdeps
files, using [RubyGems version constraints](https://guides.rubygems.org/patterns/#declaring-dependencies).
Only one constraint can be specified. For instance:

~~~
package_name:
  gem: "package_name~>2.0"
~~~

Because Bundler sets up the environment so that it is completely isolated from
the other workspace's, gems that are not part of the osdeps system - installed
for instance for debugging purposes -- need to be added in a separate
[Gemfile](http://bundler.io/v1.15/man/gemfile.5.html), in `autoproj/Gemfile`.
You **must** run `autoproj osdeps` after changing this file.

Unlike the osdeps files, `autoproj/Gemfile` follows [Bundler's Gemfile
syntax](https://bundler.io/gemfile.html). You do not need to add the `source
"https://rubygems.org"` command, which is already set by Autoproj.

`autoproj/Gemfile` is usually not checked in the version control system - if
you need a permanent dependency installed, define an osdep for it and depend on
the osdep.
{: .callout .callout-warning}

## The PIP Package Manager

This package manager allows to install Python packages using pip. The packages
are installed in the workspace's prefix under `pip/`. `pip/bin/` is
automatically added to the PATH.

## Interactions Between Source and OSDep Packages {#source_osdep_interactions}

The most common source/osdep package interaction is that any source package can
depend on an osdep package, listed in a `<depend …>` tag in [the package
`manifest.xml`](add_packages.html#manifest_xml).

Autoproj also allows you to define an osdep package with the
_same name_ as a source package. When this happens autoproj will:

- install the osdep package on platforms where it is available
- use the source package otherwise.

If the osdep and source packages are already defined and don't have the same
name (for any reason), one can [alias the osdep package](#alias) to match the source
package name. If the behavior is undesired (i.e. if one wants to force the installation
of the source package), it [can also be done](#force_source_package) (but with
caveats ! Read that part well !)

## Reusing other osdeps entries {#reusing_entries}

The `osdep` keyword can be used at any place an os-independent package managers
can be used. The package named under this keyword are other osdep entries, that
are recursively resolved by autoproj.

See the cookbook below for examples

## The `osdeps` system cookbook

### Aliases {#alias}

Using [the `osdep` special keyword](#reusing_entries), one can alias a name to another:

~~~yaml
old_name:
  ubuntu:
  ...
new_name:
  osdep: old_name
~~~

This is commonly used to ensure that an osdep entry matches a source package's
name to use [the source/osdep fallback mechanism](#source_osdep_interactions).

### Installing platform packages to support an OS-independent package

Some OS-independent package sometime depend on other platform-dependent
software to be installed. The [`nokogiri` gem](https://rubygems.org/gems/nokogiri)
for instance requires the ruby-dev packages to be installed as well as `libxml`.

This should be done using [the `osdep` special keyword](#reusing_entries) as
well:

~~~yaml
libxml:
  ubuntu:
    - libxml2-dev
libxslt:
  ubuntu:
    - libxslt1-dev
nokogiri:
  gem: nokogiri
  osdep:
  - libxml
  - libxslt
~~~

### Forcing usage of a source package even if a corresponding osdep package exists {#force_source_package}

One can use 'nonexistent' instead of a list of packages to force the osdep system
to assume that the package is not available. This can be used to force using a
source package instead of an osdep package. The best place to do so is by
adding an `overrides.osdeps` file in your main build configuration and add an
entry for the package:

~~~yaml
simulation/gazebo: nonexistent
~~~

It is important to note at this point that all the package installation is
delegated to the underlying package system. When forcing usage of a source
package instead of an osdep, Autoproj will not require the installation
of said package. However, if other OS packages depend on it, it will still
get installed.
{: .important}

### Future-proof OS version entries

The best way to format OS version entries in order to have them as future-proof
as possible is to explicitly list old versions and then use the current version
as `default`. This works best because the package names rarely change.

For instance, the gdal package was, starting on Ubuntu 14.04, named
`libgdal1-dev`. Assuming it was added at the time, its osdep entry would be:

~~~yaml
gdal:
  ubuntu:
    default:
    - libgdal1-dev
~~~

However, from 16.04 onwards, the package got renamed into `libgdal-dev`. One
should update the osdep entry to match:

~~~yaml
gdal:
  ubuntu:
    '14.04,14.10,15.04,15.10':
    - libgdal1-dev
    default:
    - libgdal-dev
~~~

This way, from 14.04 up to 15.10, one did not have to change the entry. When
16.04 got out, we needed to update the entry, but won't have to do it until the
package name changes again.

Combined with the `nonexistent` keyword, this also allows to fall back to the source
package for older OS versions:

~~~yaml
control/visp:
  ubuntu:
    '14.04,14.10,15.04,15.10': nonexistent
    default:
    - libvisp-core3.0-dev
~~~

## osrepos files

In addition to installing OS packages, Autoproj may also automatically setup os-specific
package repositories. In order to do that, you will have to create a YAML file with the
.osrepos extension either in a package set or in the main configuration. Similarly to an
.osdeps file, the .osrepos should have the format:

~~~yaml
- distribution:
  - version:
    … repository definition …
~~~

Just like with OS packages, Autoproj will automatically detect your operating system
and only setup the relevant repositories. Currently, the only supported system is ubuntu/debian.

### Apt repository definition

The format of an Apt repository definition is as follows:

~~~yaml
- ubuntu:
  - xenial:
    - type: repo
      repo: 'deb http://packages.ros.org/ros/ubuntu xenial main'
    - type: repo
      repo: 'deb http://packages.osrfoundation.org/gazebo/ubuntu-stable xenial main'
    - type: key
      keyserver: 'hkp://ha.pool.sks-keyservers.net:80'
      id: 421C365BD9FF1F717815A3895523BAEEB01FA116
    - type: key
      url: 'http://packages.osrfoundation.org/gazebo.key'
      id: D2486D2DD83DB69272AFE98867170598AF249743
~~~

As you can see from the snippet above, Autoproj is capable of adding both the repository
itself and the required keys. If you want to use the same entry for different OS releases you
may use the `default` keyword or a comma-separated list of release names/versions:

~~~yaml
- ubuntu:
  - xenial,'14.04',saucy:
    - type: repo
      repo: 'deb http://packages.microsoft.com/repos/vscode stable main'
  - default:
    - type: repo
      repo: 'deb http://dl.google.com/linux/chrome/deb/ stable main'
~~~

By default, Autoproj will add new entries to `/etc/apt/sources.list.d/autoproj.list`. This
may be changed with the addition of a `file` option in the entry. So, to have Autoproj add
new definitions to a `/etc/apt/sources.list.d/package_set.list` file:

~~~yaml
- ubuntu:
  - xenial:
    - type: repo
      repo: 'deb http://packages.ros.org/ros/ubuntu xenial main'
      file: package_set.list
~~~

Existing entries will be left unchanged in the files they are currently defined in and
commented out entries will be uncommented in the files they are currently defined in.

**Next**: now that you have a deeper understanding of what are packages and how they
are integrated in an autoproj build [let's discuss how to organize the overall build
configuration itself](managing.html)
{: .next-page}
