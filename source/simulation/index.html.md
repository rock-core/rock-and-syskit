---
layout: documentation
title: Introduction
sort_info: 0
directory_title: Simulation with Gazebo
directory_sort_info: 55
---

# Simulating Syskit Systems with Gazebo
{:.no_toc}

- TOC
{:toc}

Gazebo is fully integrated in Rock&Syskit systems to support system development.
Syskit's support for Gazebo includes:

- control and status of any links
- control and status of any joints
- interface with Gazebo sensors
- support for recursive models
- using SDF as a representation of a system's kinematic configuration (i.e. as a
  source of configuration for the
  [transformer](../component_networks/geometric_transformations.html)). This
  support is also usable in live systems, without Gazebo, allowing to use the SDF
  representation as a common source of truth

This documentation chapter will cover first the link between the SDF model
kinematics (links and joints) and Syskit, that is how to control and/or get
information about a system that is running in Gazebo. We will then talk about
extending gazebo with plugins, and adding support for them at the boundary with Rock
and Syskit. We will then finally talk about the relationship between the SDF models
in your simulation and the transformer - that is, Rock's system to handle
[geometric transformations](../component_networks/geometric_transformations.html) system-wide

## File Organization

By convention, a Gazebo world named `foobar` is saved within the
`scenes/foobar/foobar.world` file in the bundles. SDF models are saved in the
`models/sdf/` subfolder of the bundles.

## First step: running Gazebo and linking it to Syskit {#first_steps}

The Gazebo-based workflow within Syskit assumes that gazebo is started externally.
This is to avoid "resetting" the world when Syskit itself is restarted, a workflow
that gets closer to the "real" development process.

To have gazebo and Syskit together, you have to:

- run your world using the `rock-gazebo` tool (instead of `gzserver` /
  `gazebo`). Apart from injecting our plugin, the tool also takes care of some
  preprocessing necessary to run oroGen task contexts within the gazebo context.
- add the following snippet at the beginning of your robot config's `init` block:

  ~~~ ruby
  require "rock_gazebo/syskit
  ~~~

- add the following snippet at the beginning of your robot config's `requires` block:

  ~~~ ruby
  Syskit.conf.use_gazebo_world(world_name)
  ~~~

  where `world_name` is the name of the world without the `.world`

Because `rock-gazebo` performs preprocessing, one may want to inspect the generated
world. This can be done with `--parse-sdf-only`

The world name passed to `use_gazebo_world` ends up being your "default world", i.e.
should be the world you use most of the time. If you want to switch to a different
world, you may pass `--set sdf.world_name=another_world` to `syskit ide` or `syskit run`

## Caveats

<div class="alert alert-info">
The world name passed to `rock-gazebo` and the world name configured in Syskit do not
match, Syskit will periodically display a message that says:

```
Syskit[WARN]: waiting for unmanaged task: cannot find naming context gazebo:empty
```

where `empty` in this case is the name of the default world.
</div>

The vizkit3d visualization does not support 100% of the same formats that Gazebo
supports. For instance, the collada (`.dae`) format is not supported by gazebo itself.
If you choose a 3D model that is not supported by both, either one or the other won't
be able to visualize the model properly.
{: .alert .alert-info}
