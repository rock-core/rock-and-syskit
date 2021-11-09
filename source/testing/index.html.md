---
layout: documentation
title: Introduction
sort_info: 0
directory_title: Testing and Debugging
directory_sort_info: 58
---

# Testing and Debugging

Once can write tests at different levels within a Rock-Syskit system. The
goal of writing tests being, as with all software testing, a reasonable level
of assurance that the system will behave as expected in the real world. Each
levels of tests play their part in this.

A close subject to testing is the one of _debugging_, that is how to diagnose
and understand a bug, either in the live system or - ideally - because of a
failed test. This section will also cover how to run or attach debuggers,
both to inspect unit tests, and live or simulated systems.

The various levels of testing follow the development "strata", and their
roles: library, component, system. Rock has support for all these levels. At
the library level, it integrates existing testing libraries. On higher
levels, it has testing harnesses suitable for these particular purposes,
always building on top of existing testing tools and frameworks when
possible. This section will base its examples on the [Basics tutorial](../basics/index.html).

* **Library unit tests** The roles of writing unit tests for the libraries
  is obviously to check that their implementation match their declared
  contract. All major programming languages nowadays have support for unit
  testing, either within their standard library or as third-party libraries.
* **Component unit tests** Since libraries are expected to be unit tested
  already, the component unit tests are meant to verify the dynamic behavior,
  as encoded in the component: configuration, detection of error cases, ...
  Testing components is already described in the
  [component section](https://www.rock-robotics.org/rock-and-syskit/components/testing.html)
* **Syskit unit tests** Syskit's coordination often require writing code
  that is evaluated at runtime. This code must be tested, and that is one
  role of the Syskit unit tests. Their other role is to provide a way
  to run expensive model checking algorithms offline.
* [**Syskit integration tests**](integration.html) These are meant to run
  actions or missions fed to a Syskit app _seen as a blackbox_, in
  simulation. The tests then verify the action's expected results - for
  instance, that the system reaches a given position, timely goes through
  waypoints, gathered valid data, displaced objects ...

When related to testing, debugging support is presented on the same page
than the testing support. Debugging for live systems is presented separately.