---
layout: documentation
title: Introduction of the `update_properties` method
sort_info: 20
---

# Introduction of the `update_properties` method
{:.no_toc}

- TOC
{:toc}

## Old Behavior

Historically, Syskit offered a single hook in oroGen component models to allow the
Syskit app to interact with the configuration logic. This was the `def configure` method.

Initially, the only Syskit-sanctioned way to write configurations was the
configuration files. Back then, Syskit was looking at the names of the
configuration sections to determine whether a component should be reconfigured
through the expensive cleanup/configure cycle.

At some point, however, this method was given the ability to write properties
through the `properties` accessor. The predicate that was checking whether
the component needed to be reconfigured got modified too to check whether
the `properties` accessor had been written to.

However, it was expected that the user-provided `#configure` hook would not
necessarily be idempotent. It was to be called _after_ the component was cleaned
up. We therefore ended up with:

1. create component instance
1. initialize properties from **default** values
1. check whether properties have been modified w.r.t. the **current** values
1. if modified, clean component up, **call #configure hook** and configure the component

Therefore, the components started to be reconfigured every time their
configuration deviated from the component's default configuration.

## New Behavior

The `update_properties` hook was introduced. This hook is called between point 2
and 3 above, and must restrict itself to updating properties. Most importantly:
it must be idempotent.

## New/old behavior: control and migration

The new behavior is used when:

- a component model does not define a `configure` method
- a component model explicitely defines `update_properties`, even if it is only
  to call the default implementation, i.e.

  ```
  def update_properties
      super # Applies configuration from file
  end
  ```
- The `syskit_task_context_uses_update_properties` configuration is set to true,
  usually in either the Robot.init block of a robot configuration or directly
  in `config/init.rb`

  ```
  Roby.app.syskit_task_context_uses_update_properties = true
  ```

The best way to migrate component models is by editing the `models/orogen/`
files and defining a correct `update_properties` method.

A warning is issued at configuration time if:
- `Roby.app.syskit_task_context_uses_update_properties` is false
- the component has a configure method explicitly defined
- the component does not have a update_properties method explicitly defined
