---
layout: documentation
title: Components
sort_info: 30
---

# Components
{:.no_toc}

- TOC
{:toc}

Within Rock, components are _implemented_ in C++. They are also _specified_ in a
Ruby domain-specific language that is processed by a code generation tool,
**oroGen**. This tool ensures that the component's interface matches its
specification. It also removes most of the crude boilerplate-writing code that
is the declaration in C++ of the component interfaces.

From a package point of view, components are defined in an orogen package. The
orogen packages are all placed in the `/orogen/` subdirectory of one of the
[package categories](../workspace/conventions.html)

**Important** an oroGen package and a library can share the same basename (e.g.
`drivers/hokuyo` and `drivers/orogen/hokuyo`). This is even a recommended
behavior when an orogen package is mainly tied to a certain library.
{: .note}

From this page on, the rest of this section will deal with the integration of
the functionality from C++ libraries into Rock components by means of orogen.
But let's first talk about how to create an orogen package.

## Creating an new oroGen package {#create}

Packages are created with the `rock-create-orogen` tool. Let's assume we want
to create a `planning/orogen/sbpl` package, the workflow would be to:

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

## Development Workflow

Developing a component involves doing mainly three things:

- [defining data types](../type_system/defining_types.html) for usage on
  its interface. Types do not necessarily have to be defined in standalone
  orogen packages as described in the Type System section, but can also
  be directly imported in an orogen package that defines tasks. When this
  is the case, the explicit `export_types` statement is not needed, as `orogen`
  will export all types that are used on the component's interface.
- defining the component(s) interface(s) in the orogen file
- implementing the processing parts of the component in C++

**Let's remember** we strongly recommend that you develop the bulk of your
component's functionality in **libraries**, instead of doing in the components
themselves.
{: .important}

Each time data types or the orogen specification are modified, one must run
orogen to re-generate code. After code generation, the package behaves like
a CMake package.

The best way to do the first code generation is to use
[`amake`](../basics/day_to_day.html). After this, one can run `make regen` to
do code generation and `make` to build from within the package's build
directory (which is usually located in `build/`). This is usually the best way
to integrate an orogen package in an IDE.

## Runtime Workflow

"Developing" a component in C++ within Rock is to write a C++ class that
interacts with its inputs/outputs. This class does not specify when the
processing is going to be called, and under which OS resource (threads,
processes). It is said that the _component implementation_ is separated
from the _system deployment_. The first one is really writing the C++ code that
interacts with the component's interface. The second one is part of system
integration.

What it means in practice is that a component implement is nothing more than a standalone
C++ class. This C++ class can be instantiated multiple times in a single
system, using different periods or triggering mechanisms, different threading
policies, …

When you define components in oroGen, you create a _task library_, which is a
shared library in which the task context classes are defined. Then, you need to
put these libraries in _deployments_ (which is also done by oroGen). Finally,
you can start these deployments, connect the tasks together, and monitor them
using Syskit.

![Runtime Workflow Diagram](media/deployment_process.svg){: .fullwidth}

**Next** Let's define the [component interface](interface.html)
