---
layout: documentation
title: Introduction
sort_info: 0
directory_title: Designing Component Networks
directory_sort_info: 50
---

# Building Component Networks
{:.no_toc}

This chapter will give you a complete view on the different aspects of how
components are composed within a Rock/Syskit system. This touches a lot of
different subjects, but we're going to start with the basics, that is how
component networks are modelled and integrated in Syskit. The first few
sections will thus go into more details about what we've seen [in the basics
chapter](../basics/index.html). The one major addition being the aspects
of the modelling that allow to reuse networks and models across systems
(most importantly, between the real and simulated systems).

After that, we will broach more complex subject related to the component
network:
- how the system designer can influence how data flows between the components
- time-ordered data processing
- modelling and integration of transformations

## Component Networks in a Syskit Application

A Syskit application can be understood, or "read" in two different ways.

The _functional_ structure. These are the separate functions - sometimes also
called _behaviors_ that are offered by the application, as well as how these
functions are related to each other. One way to build these functions is to use
Rock components. This will be the subject of this chapter. Other ways to build
and compose functions will be presented in the [coordination
chapter](../coordination).

The _temporal_ structure. This is the main subject of the [coordination
chapter](../coordination). It deals with how one can make a Syskit application
represents what happens in the real world, and how the system can evolve in
response to these events.

On the subject of component networks, the main concepts are _compositions_ and
_profiles_. The former allows to combine components together, the aim being the
building of a library of generic functions. The latter allows to fine-tune
these functions to adapt them to a specific robot configuration and/or to a
specific situation. The networks are exposed on a profile are what is actually
exposed to the coordination layer.

## Structure of this Chapter

In this chapter, we will start by detailing and expanding what we have already
seen in the [basics](../basics) chapter. We are assuming that you have read the
[Runtime section](../components/runtime.html) of the
Integrating Functionality chapter, so we're going to jump straight at
[compositions](composition.html) and [profiles](profiles.html). We will then go
into the mechanisms that allow to build [reusable
models](reusable_networks.html), a.k.a.  how to make most of the models
robot-independent, to then fine-tune the models for each system.

The rest of the chapter will details more advanced aspects of the design of the
component network(s). For now, you can find more about the system handling of
[geometric transformations](./geometric_transformations.html), a critical
tool to build components that are (mostly) system-independent, promoting
reuse.

Let's now get into the first item of business, the [compositions](composition.html)
{: .next-page}

