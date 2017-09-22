---
layout: documentation
title: Introduction
sort_info: 0
directory_title: The Type System
directory_sort_info: 35
---

# Type System
{:.no_toc}

One of the first thing that a system designer has to think about is defining
the data structures that will be used to exchange data between the system's
parts (in our case, between the components and Syskit).

These types are used for a few different things

* in the communication between components and Syskit (ports)
* in the configuration of the component (properties)
* in the control of the component (operations)
* to assess the component's state (diagnostics)

In Rock, the types are defined in C++ in the components themselves. They are
then exported into Rock's type system to allow for their **transport**
(communication between processes), but also for their manipulation in Syskit.

This section will detail [how types are defined](defining_types.html), how they are
[mapped into the Ruby layers](types_in_ruby.html), and how which types are
available can be discovered.

