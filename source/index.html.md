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

A Rock newcomer should read this documentation sequentially. Tutorials and
examples are mixed with more detailed descriptions, with an aim at being progressive.

<div class="alert alert-warning" role="alert">
As of today (June 2017), not all the software used in this guide has reached
Rock mainline repositories. For this reason, one needs to start using the
buildconf repository on GitHub
[`rock-gazebo/buildconf`](https://github.com/rock-gazebo/buildconf) instead of
the default one at
[`rock-core/buildconf`](https://github.com/rock-core/buildconf). The [installation guide](basics/installation.html) already reflects this.
</div>

## How to read this documentation {#how_to_read}

The [Basics](#basics) section is meant to be read in its entirety. It covers
presents the fundamentals of how a robotic system is integrated and managed
at runtime within Rock and Syskit.

After the basics, the rest of the documentation is meant to be read on a
need-to-know basis. Pick the subjects that are of interest to you, or that you
need to know at a certain point in time.

## Basics

1. [Basics: Installing Rock and Building a simple system using Gazebo and Syskit](basics/index.html)
2. [Runtime Basics: Running the basic system](runtime_overview/index.html)

## Building Systems

3. [Workspace and Packages](workspace/index.html)
3. [The Type System](type_system/index.html)
4. [Integrating Functionality](integrating_functionality/index.html)
5. Reusable Syskit modelling
7. Advanced data processing in Components
8. System coordination
9. Error Handling

## Development Workflow

8. Tests
9. Logging, Data Visualization and Building GUIs
10. Inspecting coordination data
11. Debugging components
12. Advanced Deployment

### Join the force!
[Top](#top)

Bla bla bla.

### Getting to know Syskit
[Top](#top)

Bla bla bla.

### New Website
[Top](#top)

Welcome to rock's new website.
