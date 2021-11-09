---
layout: documentation
title: Introduction
sort_info: 0
directory_title: Error Handling
directory_sort_info: 56
---

# Error Handling

**This is a stub section, waiting for the actual documentation to be written**

Syskit's underlying design is meant to allow for rich runtime monitoring and
error handling.

- The goal of the main Syskit data structure is to track not
  only _what_ is running, but also _why_, that is the relationships between
  the different pieces of software and hardware, which then allows to encode
  how some parts of the system _influence_ other parts. When things "go wrong",
  it provides a rich context to understand what impact the error(s) have on the
  system.
- The ability of Syskit to "switch" between modes also provides a way to
  _react_ to errors by switching operational modes, in a way other coordination
  systems do not have.
- The integration of "execution agents", that is the underlying OS processes
  within the execution model allows Syskit to monitor them and integrate them
  in the error detection and handling scheme

To be written:

- errors
- default error handling behavior
- exceptions and exception handling
- fault detection tables
- fault handling tables

