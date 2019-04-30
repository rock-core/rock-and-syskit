---
layout: documentation
title: Introduction
sort_info: 0
directory_title: Libraries
directory_sort_info: 35
---

# Integrating Functionality

You should have at this stage read the Basics section of this documentation.
Where Basics was all about dealing with system integration, we are going to
discuss in this section how new functionality is presented in a form that
can be used in a system.
This part assumes that you've understood the notions of
[dataflow](../basics/composition.html) and [execution
lifecycle](../runtime_overview/event_loop.html)

We **strongly recommend** that you develop most of your system's functionality
in **libraries**, instead of doing within the framework itself. For C++, this
means creating C++ library packages that are then later integrated into Rock
components to expose that functionality to the system. For Ruby, this means
creating Ruby packages that are then used within the Ruby layers (e.g. Syskit)

**Why ?** Developing libraries is a matter of "general" software engineering
best practices. Robotics is a small field, software engineering is not. By
doing most of your work in a framework-independent manner, you ensure that you
can benefit from the much bigger ecosystem. Moreover, we haven't seen the end
of the robotic frameworks. By developing libraries that are
framework-independent, you ensure that you can integrate them elsewhere if needs
be, cutting the time and effort by **a lot**.

**How does Rock help the library/framework separation ?** Supporting this
separation during the development process is a main design driver for the
tooling. For instance, Rock's build system - `autoproj` - is not assumed to be
present by the rest of the packages. Second, `orogen` exposes C++ structures
directly into the type system. The widespread approach - using IDLs - usually
end up pushing the developers to integrate code-generated structures in their
libraries thus tying them to the framework itself.
{: .note}

While we do recommend a separation between framework and libraries, Rock does
have some guidelines and best practices on how to develop C++ and Ruby
libraries to ease their integration in a Rock system. The next pages of this
section will first deal with [C++ libraries](cpp_libraries.html) and then [Ruby
libraries](ruby_libraries.html).

The [next section](../components/index.html) will then deal with the no small
matter of integrating this functionality in a Rock system. If you feel so
inclined, Rock provides a C++ library template. This template solves some of
the common problems with setting up a C++ library (basic build system, ...)
and obviously integrate as-is with the rest of a Rock system.

**Next**: let's talk about the development of [C++ libraries](cpp_libraries.html)
{: .next-page}

