---
layout: documentation
title: Creating & Updating an oroGen Package
sort_info: 3
---

# Components
{:.no_toc}

- TOC
{:toc}


## Creating and Adding a new oroGen Package to the Workspace

This is covered in the [Workspace and Packages section](../workspace/add_packages.html)

The workflow of the component scaffolding tool `rock-create-orogen` is a bit
different, though, so let's go through its workflow. Let's assume we want to
create a `planning/orogen/sbpl` package, the workflow would be to:

~~~
acd
cd planning/orogen/
rock-create-orogen sbpl
cd sbpl
# Edit sbpl.orogen
rock-create-orogen
# Fix potential mistakes and re-run rock-create-orogen until there are no errors
# …
~~~

**What does `rock-create-orogen` do ?** `orogen` does "private" code generation
in a `.orogen` subfolder of the package, and creates a `templates/` folder.
`rock-create-orogen` ensures that the initial repository commit does not
contain any of these. If you don't want to use `git`, or if you're confident
that you know which files and folder to commit and which to leave out, the second
run is not neeeded.
{: .note}

Once this is done, [add the package to your build configuration](../workspace/add_packages.html#orogen)

## Updating an oroGen package

Whenever you modify the orogen specification, just run the build once for that
package. It will update existing C++ definitions transparently, allowing the
code completion to update as well (if you use one)

Some changes in the orogen specification require manual changes to the C++ code,
but they are rare (and will be documented in the relevant sections). In this case, orogen always create a "clean" version of the C++ code in the `templates/`
folder, giving you a template of the signature(s) you need to add or update.

**Behind the scenes** the C++ definitions for the component interface are separated in a base class. This base class is saved in the hidden `.orogen/` folder. This is how the orogen code generation can update it without interfering
with your code.
{: .note}

## C++ Standard {#cxx_standard}

The C++ standard used to interpret the data type files and to build the component's C++
code is the latest standard that its dependencies require. There is currently no
way to explicitely tell orogen to use a different standard. For instance, if
your oroGen project uses a library that sets C++11 using [the Rock CMake
macros](../libraries/cpp_libraries.html#cxx_standard), the oroGen project will use C++11
too.

## Dealing with Dependencies

There really are three types of dependencies to oroGen packages, which have
different types of requirements. In all these cases, you **must** remember to
add the dependency's package in the orogen package's [`manifest.xml`](../workspace/add_packages.html#manifest_xml).

1. dependencies between orogen packages. They are required to refer to existing
task contexts and types.

2. dependencies to libraries that are required during code generation. This is
only the dependencies that are needed to define types used on the component's
interfaces (see [this section](./importing_types.html)).

3. dependencies that are required for the implementation of the component's code
and are present in the component's public interface (that is, its .hpp file)

4. dependencies that are required for the implementation of the component's code
itself, but are not part of its public interface.

## Dependencies between oroGen packages

These dependencies are used to either [re-use
types](./importing_types.html#from_orogen) from another oroGen package, or
[refer to other task contexts](./interface.html#inheritance) implemented in
another oroGen package.

## Dependencies for type definitions

It is mandatory that this type of dependency defines a pkg-config file. All Rock
packages do, but 3rd party libraries may not. If they do not, you will have to
follow [this step-by-step](../libraries/cpp_libraries.html#unconventional_dependencies) to
work around these.

Once the new pkg-config file is installed, you can refer to it with
`using_library` as described [here](./importing_types.html)

## Dependencies to libraries that are used in the public interface

It is mandatory that this type of dependency defines a pkg-config file. All Rock
packages do, but 3rd party libraries may not. If they do not, you will have to
follow [this step-by-step](../libraries/cpp_libraries.html#unconventional_dependencies) to
work around these.

Once the new pkg-config file is installed, you can refer to it with
`using_library` as described [here](./importing_types.html). If the project does
not use this library to import types, you may provide `typekit: false` to reduce
linking and startup times: `using_library 'pkg', typekit: false`

## Dependencies to libraries that are not used in the public interface

The simplest way to integrate these libraries, if they do provide a pkg-config file,
is to use `using_library` (see point above).

Now, since these libraries are not needed by orogen itself, nor do they need to be
exported to the orogen package's own pkg-config file, it is possible to manually
handle the dependency in the package's CMake code (in `tasks/CMakeLists.txt`), thus
avoiding the need to manually create a pkg-config file if there is none.