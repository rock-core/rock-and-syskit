---
layout: documentation
title: Introduction
sort_info: 0
directory_title: Coordination
directory_sort_info: 55
---

# Coordination

**This is a stub section, waiting for the actual documentation to be written**

So far, in the [Syskit basics tutorials](../basics) as well as in the
[network design](../component_networks) section, we have mainly seen _static_
networks. That is, we have learned how to create networks and only manually
transition between them.

Syskit defines rich tools to also combine these network _temporally_. That is,
define inside Syskit _events_ that should be reacted to, and what to do when
these events happen. Syskit's ability to seamlessly switch between network
configurations shines here, as the coordination models can simply define *what*
should run and let Syskit deal with the transitions.

To be written:

- action state machines
- structuring events to avoid leaky abstractions
- internal/external events
