---
layout: documentation
title: Global Configuration
sort_info: 45
---

# Global Configuration
{:.no_toc}

- TOC
{:toc}

An Autoproj workspace configuration may have an `init.rb` file, that can be used
to set configuration parameters for the whole workspace. This file is loaded
first, before anything else in the workspace. In addition, if an `.autoprojrc`
file is present in `$HOME`, it will also set default configuration parameters
for all workspaces in a given system. A workspace's `init.rb` supersedes
`.autoprojrc`. Both files are Ruby files in which one has full access to the
Autoproj APIs.

This section is an exhaustive list of all configurations that may be set in
these files. When applicable, the corresponding configuration entry in
`config.yml` is listed. For parameters that are stored in the configuration
file, one can also set them during bootstrap by giving a YAML file to the
`autoproj_bootstrap` file using the `--seed-config` option.

## Directory layout

### Separated prefix root {#separate_prefixes}

By default, artifacts installed by packages are all stored in a common `install/` folder
that sits at the root of the workspace.

This prefix folder can also be set to a global path by setting either
`Autoproj.config.prefix` or the `prefix` entry in `config.yml`.

In addition, Autoproj can configure packages to have each installed in a
separate folder. **We recommend either migrating to this setting, or using it
for new projects**.  This requires stricter dependencies between packages, which
allows to have a more robust development process.

~~~ ruby
Autoproj.config.separate_prefixes = true
~~~

This setting is available as the `separate_prefixes` key in `config.yml`

The `-p` option of `acd` and `alocate` allow to navigate to a package's prefix dir
regardless of `separate_prefixes` is enabled or not.

### Separated build tree

By default, Autoproj packages will be configured to store their build byproducts
in a `build/` subfolder under the source package. An alternative is to create
a separate build tree by setting `Autoproj.config.build_dir` to an absolute
path, e.g.

~~~ ruby
Autoproj.config.build_dir = File.join(Dir.home, "build_area", "rock-core")
~~~

The setting is stored in `config.yml` under the `build` key.

Each package in will have its own build dir by concatenating the path in
`build_dir` and the package name. Build directories can't be shared amongst
workspaces.

When navigating a workspace with a separated build directory, one can jump
between the source and build dir of a given package using respectively `acd` and
`acd -b .`

### Auto-configuration of a separated build and prefix tree in .autoprojrc

The following snippet will automatically configure the build and prefix settings
to map a folder structure under a root (e.g. `$HOME/dev`) in a common build root
(e.g. `$HOME/dev/build_area`)

~~~ ruby
dev_dir = File.join(Dir.home, "dev")
build_root_dir = File.join(Dir.home, "dev", "build_area")
if Autoproj.workspace.root_dir.start_with?(dev_dir + "/")
    workspace_name = Pathname.new(Autoproj.workspace.root_dir).
        relative_path_from(Pathname.new(dev_dir)).to_s
    Autoproj.config.prefix_dir = File.join(dev_dir, 'build_area', workspace_name, 'install')
    Autoproj.config.build_dir = File.join(dev_dir, 'build_area', workspace_name)
end
~~~

For instance, the workspace `$HOME/dev/vanilla/rock-core` will use
`$HOME/dev/build_area/vanilla/rock-core` as its build folder and
`$HOME/dev/build_area/vanilla/rock-core/install` as its prefix folder.

## Parallelism

By default, Autoproj will run up to 10 import processes in parallel, and up to
the number of cores the machine has build processes. The build parallelism can
be overriden for specific runs using the `-p` option (e.g. `amake -p2`).
Alternatively, the `parallel_import_level` and `parallel_build_level` configuration
options can be used:

~~~ ruby
Autoproj.config.parallel_import_level = 5
Autoproj.config.parallel_build_level = 2
~~~

These options are available under the same name in `config.yml`.

## Interactivity

By default, Autoproj will ask for any configuration option that has never been
asked - regardless of whether it has a default value or not.

This can be disabled (in which case Autoproj will use the default when possible)
by using the `--no-interactive` command line option or the `AUTOPROJ_NONINTERACTIVE`
environment variable to 1. Both settings are not permanent.

To make the setting permanent, set the `interactive` configuration option to false

~~~ ruby
Autoproj.config.interactive = false
~~~

This option is available under the same name in `config.yml`

## OS Packages vs Source Packages

When both an OS package and a source package are available under the same name,
Autoproj will prefer using the OS package when available, using the source package
only as a fallback. This behavior can be inverted (using the source package by
default, using the OS package only if the source package is not available) by
setting the `prefer_indep_over_os_packages` configuration option:

~~~ ruby
Autoproj.config.prefer_indep_over_os_packages = true
~~~

This option is available under the same name in `config.yml`

## CMake-related options

### Make messages

By default, the CMake package handler will redirect all messages to the package's
log file, only showing a digest of the number of warnings at the end of a package's
build.

Alternatively, one can instruct the package handler to let messages that are recognized
as warnings through and display them during the build:

~~~ ruby
Autobuild::CMake.show_make_messages = true
~~~

### Clean prefix

When using the {#separate_prefixes} mode, Autoproj can use information generated by
CMake to remove obsolete files from the prefix. This ensures for instance that a
file that was installed but is not is removed, making sure that nothing else depends
on it during the build.

**This mode should only be enabled if the separate_prefixes option is set (or if
you have implemented an equivalent scheme)**. Otherwise, Autoproj will delete most
of the workspace's prefix.

~~~ ruby
Autobuild::CMake.delete_obsolete_files_in_prefix = Autoproj.config.separate_prefixes?
~~~

## Python support

Multiple Python versions can now coexist in a system, although not in a single
Autoproj workspace.  For this purpose Autoproj users can now be explicitly asked
for any needed Python support during a bootstrap, by adding the following to the
`init.rb`:

    require 'autoproj/python'
    Autoproj::Python.setup_python_configuration_options()

In case Python support is requested or implicitly needed, e.g., following a pip
dependency in a layout, the user is asked to provide the path to the Python
executable to use. By default the Python executable is searched/guessed
automatically. Corresponding shims are installed for an active workspace:
`install/bin/python` and `install/bin/pip`, to ensure that the right versions
are called when a workspace's `env.sh` has been loaded.

To ensure a consistent setup for the generation of language bindings, package
definitions in `*.autobuild` file can be extended as follows:

~~~ ruby
cmake_package 'custom/pkg_with_python_bindings' do |pkg|
    bin, version, sitelib_path = Autoproj::Python.activate_python_path(pkg)
    pkg.define 'PYTHON_EXECUTABLE', bin if bin
    pkg.define 'PYTHON_VERSION', version if version
end
~~~

`activate_python_path` above will return `nil` if the user disabled Python support.
Either guard for it (if possible for the package)), or raise an error if Python
is required for said package.


## Clang-format support

To enforce a standard C++ coding style, one can enable `clang-format` as a test target.
This can be done by extending a package definition in the `*.autobuild` file as follows:
~~~ ruby
cmake_package 'custom/pkg_with_style_enforced' do |pkg|
    pkg.define "ROCK_STYLING_CHECK_ENABLED", true
    pkg.define "ROCK_CLANG_FORMAT_EXECUTABLE", "path-to-clang-format-executable"
    pkg.define "ROCK_CLANG_FORMAT_CONFIG_PATH", "path-to-clang-format-config-file"
    pkg.define "ROCK_CLANG_FORMAT_OPTIONS", "any-option-one-wishes-to-add"
end
~~~
Keep in mind that this check is non-intrusive, meaning that it will only report what
is not conforming to the defined standard as warnings (by default) and won't actively
change any code. The command will run for all the C++ files in the `src/` and `test/`
folders. Please refer to the
[clang-format documentation](https://clang.llvm.org/docs/ClangFormat.html) for more
information.

## Clang-tidy support
If one wishes to have some coverage against well known bugs and not-so-well designed code,
it's possible to add `clang-tidy` checks as a test target. Similarly to
`clang-format` support, one should extend a package definition in the `*.autobuild` file
as follows:
~~~ ruby
cmake_package 'custom/pkg_with_linting' do |pkg|
    pkg.define "ROCK_LINTING_CHECK_ENABLED", true
    pkg.define "ROCK_CLANG_TIDY_EXECUTABLE", "path-to-clang-tidy-executable"
    pkg.define "ROCK_CLANG_TIDY_CONFIG_PATH", "path-to-clang-tidy-config-file"
    pkg.define "ROCK_CLANG_TIDY_OPTIONS", "any-option-one-wishes-to-add"
end
~~~
By default, this checks will only output the linting errors. If one wants `clang-tidy` to
actually fix the errors it encountered, one can do so by adding the proper argument as an option.
Like `clang-format`, this command will run for all the C++ files in the `src/` and `test/`
folders. Prefer refer to the
[clang-tidy documentation](https://clang.llvm.org/extra/clang-tidy/index.html) for more
information.
