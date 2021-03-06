---
layout: documentation
title: Starting a New Project
sort_info: 20
---

# Starting a new project
{:.no_toc}

- TOC
{:toc}


## Main build configuration

One never starts a project from scratch. One usually instead starts off using
either [the Rock bootstrap](../basics/installation.html) or a project's main
build configuration.

After having bootstrapped, the "source" build configuration is checked out in
the `autoproj/` folder at the root of the workspace. Commit the folder's current
state, push it to a repository you would have created to hold your own
project's build configuration. You can then change Autoproj's configuration
to track it instead of the Rock build with

~~~
autoproj switch-config git URL
~~~

**Tip** if you're using Git and GitHub under Linux or MacOSX, using SSH keys
for authentication still proves to be the most practical option. Use the
`git@github.com...` URL instead of the `https://` one.
{: .tip}

**Tip** when working in a company organization on github, a good naming scheme
for build configurations is `company.project-buildconf` where `company` is your
organization's name and `project` the name of the project you're setting up.
{: .tip}

## Package sets

Package sets are a way in Rock's build system to share build information. It is
customary start with an organization-wide (i.e.  company-wide) package set.
One often also ends up with one package set per project.

The only thing that autoproj requires to successfully import a package set is
to have a `source.yml` YAML file in it with a `name:` field. A common
convention is to use `company.project` for a project-specific package set or
just `company` for the organization one. For example purposes, the rest of this
page will use `company.project` as the package set name.

Assuming you're using git and github, create a new repository on github,
following the `company.project-package_set` pattern.

In the context of the [Basics section](../basics/publishing.html), a good
name for the package set would be `rock.rock_and_syskit` (i.e. `rock`
organization, the `rock_and_syskit` project). The buildconf would be saved
in a repository named `rock.rock_and_syskit-buildconf` and the package set
in `rock.rock_and_syskit-package_set`.

To create a minimal package set, create an empty directory (the name does not
matter) and do (replacing the name by your actual package set name and the
URL by your repository's URL):

~~~
git init
echo "name: company.project" > source.yml
echo "version_control:" >> source.yml
echo "overrides:" >> source.yml
touch packages.autobuild packages.osdeps init.rb overrides.rb
git add .
git commit -m "Initial commit"
git push URL master
~~~

At this point, the package set can be added to the buildconf's manifest. Add it
at the end of the `package_sets` section. For a github package this would be:

~~~yaml
package_sets:
- ...
- github: organization/company.project-package_set
~~~

For a general git URL:

~~~yaml
package_sets:
- ...
- type: git
  url: URL
~~~

In addition, one usually would want to build all packages defined in the package
set (i.e. all packages from the project). This is done by adding the package set
name in the `layout` section:
{: #add_package_set_in_layout}

~~~yaml
layout:
- company.project
~~~

E.g. for the Basics tutorial, assuming it is stored on the `rock-core` organization,
the whole manifest would look like:

~~~yaml
package_sets:
   - github: rock-core/package_set
   - github: rock-core/rock-package_set
   - github: rock-tutorials/tutorials-package_set
   - github: rock-gazebo/package_set
   - github: rock-core/rock.rock_and_syskit-package_set

layout:
   - rock.core
   - rock.gazebo
   - rock.rock_and_syskit
~~~

There are other import possibilities, listed in the [adding new
packages](add_packages.html#version_control) section.

After having added the package, check it out with:

~~~
aup --config
~~~

The package set is now in `autoproj/remotes/company.project`.  You can go
straight to it with

~~~
acd company.project
~~~

**Next**: let's learn how to [add new packages](add_packages.html)
{: .next-page}

