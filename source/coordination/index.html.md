---
layout: documentation
title: Introduction
sort_info: 0
directory_title: Coordination
directory_sort_info: 55
---

# Coordination

So far, in the [Syskit basics tutorials](../basics) as well as in the
[network design section](../component_networks), we have mainly seen _static_
networks. That is, we have learned how to create networks and only manually
transition between them.

We have been using the **name** of the profile definitions to instruct the
Syskit controller to start a network, adding some arguments when needed.

This interface - defining "things to be executed" and telling Syskit to run
them using their names - is Syskit's _action interface_. Profile definitions,
that is component networks, are only one way to define them. They can be defined
in other ways, and can be combined to form more complex behaviors.

This section will cover all that you need to know about creating actions. You
should read the [runtime overview](../runtime_overview/index.html) section
first, as many concepts introduced there will be needed here. The section
will repeat them, but ...

The first parts in this section will be covering the basics of how to create
actions: actions, event, action methods and action state machines.

1. we will first [describe the actions in general](generalities.html) within
   how they can be used, what happens when they are activated and dropped.
   This will use the example of profile definitions (when used as actions) as
   an action example, but will be applicable to all.

2. at this point, it will become important to understand
   [**tasks and events**](tasks_and_events.html),
   which are the basic primitives used to coordinate actions with each other
   (and, also, track an action's progress). We will cover how tasks can emit
   events, and the primitives that are on offer to create "active" Syskit
   tasks that transform component-level information (e.g. data streams) into
   events, to make the information available for coordination.

4. a second way to create actions, after the profile-generated actions, is
   [**action methods**](action_methods.html). In action methods, the action
   calls code to create the task(s) and task structure that will be executed.
   This is thus more dynamic than profile definitions, and allows to combine pure
   tasks and definitions to dynamically generate arguments, inject different
   subnets or pick definitions based on the context. This part will also
   briefly cover the notion of task dependencies.

3. profile-based actions and method actions can be combined into more complex
   temporal structures through [**action state machines**](action_state_machines.html)

5. finally, we will explain how Syskit is architectured to allow for the integration
   of [a higher level of control](higher_level_control.html), and how this
   level of control can manage the Syskit system, either autonomously or in
   behalf of an operator. The main purpose of this section is to detail the
   tools and concepts needed for this. More details for specific use-cases
   will be detailed in [the cookbook](../cookbook)

We will get through [a first recap](first_recap.html) of what we've seen so
far, to then go on into a lot more details, covering:

1. [How events are propagated](event_scheduling.html), including how you can
   control how things are scheduled by Syskit

2. designing e.g. compositions to ensure that events are defined "at the
   proper level", thus creating [reusable abstractions](creating_abstractions.html).

3. how [rock-based component networks fit into all of this](component_networks.html),
   including a detailed presentation of how Syskit resolves multiple networks
   together and transitions temporally between a changing list of
   instanciated component-based actions.

We will finally have [a final recap](final_recap.html) of the whole section, including
links to pages in [the cookbook](../cookbook) that are relevant to
coordination of a Syskit system.
