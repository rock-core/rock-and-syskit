---
layout: documentation
---

# Building robots with Rock and Syskit

Rock is a software framework for the development of robotic systems. Rock
provides all the tools required to set up and run high-performance and reliable
robotic systems for wide variety of applications in research and industry. It
contains a rich collection of ready to use drivers and modules for use in your
own system, and can easily be extended by adding new components.

This documentation's focus is on building robot systems based on Rock and
Syskit, Rock's system management layer. It will not cover issues related to
Rock's lower-level Ruby and C++ execution APIs, or only in cases where these
plug Syskit limitations.

The most important aspect of this documentation is to explain both the _how_
and the _why_, i.e. describe the parts of Syskit that are relevant to manage a
robot system, but also to explain the underlying design principles that allow
you to build a _manageable_ system. The documentation does not assume any prior
knowledge about Rock, but does assume that you have more than basic knowledge
on general software development practices. The tools being implemented in Ruby
and C++, it is best to know about these languages. However, documentation on
the basics and principles of a Rock-Syskit system can be followed with basic
programming knowledge.

<div class="alert alert-warning" role="alert">
If you are already familiar with Rock, note that this guide uses the buildconf
repository on GitHub
[`rock-gazebo/buildconf`](https://github.com/rock-gazebo/buildconf) instead of
the default one at
[`rock-core/buildconf`](https://github.com/rock-core/buildconf) to pull
gazebo-specific packages and configuration. The
[installation guide](basics/installation.html) already reflects this.
</div>

## How to read this documentation {#how_to_read}

The [Basics](#basics) section is meant to be read in its entirety. It covers
presents the fundamentals of how a robotic system is integrated and managed
at runtime within Rock and Syskit. A Rock newcomer should read this
part sequentially. Tutorials and examples are mixed with more detailed
descriptions, with an aim at being progressive.

After the basics, the rest of the documentation is meant to be read on a
need-to-know basis. Pick the subjects that are of interest to you, or that you
need to know at a certain point in time.

## Basics

1. [Basics: Integrating a system from scratch using Gazebo and Syskit](basics/index.html)
2. [Runtime: Details of running a Syskit system](runtime_overview/index.html)

## Building Systems

3. [Workspace and Packages](workspace/index.html)
4. [Libraries](libraries/index.html), or how to integrate functionality in C++ and Ruby
   with no dependency on the Rock framework itself.
6. [Components](components/index.html), or how to use the functionality developed
   in libraries in a Rock-based component layer, including a description of
   Rock's type system.
5. Working with SDF
6. [Designing Component Networks](component_networks/index.html)
7. Advanced Component Deployment
8. System coordination
9. Error Handling

## Development Workflow

10. [Testing and Debugging](testing/index.html)
11. Logging, Data Visualization and Building GUIs
12. Inspecting coordination data

