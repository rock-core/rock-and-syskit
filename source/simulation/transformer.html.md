---
layout: documentation
title: Transformer
sort_info: 30
---

# Transformer
{:.no_toc}

- TOC
{:toc}

At its heart, it is not hard to see that a SDF model is a file that describes
the kinematics of a system. It indeed contains all the information (and some more)
needed to configure Rock's transformation handling system.

And that is what happens when one uses `use_gazebo_model`. The profile's
transformer is automatically configured, using all the model's links as frames
and the information from within the SDF file to configure static transforms.
Additionally, all the link transformation devices generated with
`sdf_export_link` are properly [annotated with frames](../component_networks/geometric_transformations.html#component_annotations).

And all is good.

But then what happens in other profiles ? How can we make the same information
available since
[it is not recommended](./models_links_and_joints.html#reusing-gazebo-related-devices-across-profiles)
to `use_gazebo_model` the same model in different profiles ?

Also, how do we reuse the same information to configure the transformer in our live
systems, while avoiding the dependency on gazebo ?

Without further ado

## Using SDF-Derived Transformer Configuration Across Profiles

The Syskit integration for the transformer provides the `use_profile_transformer`
stanza, which allows to configure a profile's transformer using the data from another.
Just use this at the top of any profile that requires the information that your `Base`
profile has:

~~~ ruby
module YourVehicle
    module Profiles
        profile "Control" do
            use_profile_transformer Base
        end
    end
end
~~~

## Using SDF-Derived Transformer Configuration in Live Systems

`use_gazebo_model` has a non-gazebo, SDF-only equivalent, `use_sdf_model`. Adding
`use_sdf_model` at the top of a profile does the transformer configuration, but without
any of the device definition that `use_gazebo_model` does.

If you wish to use this, you still need to provide a world file. This file is loaded
with `Syskit.conf.use_sdf_world` [instead of `Syskit.conf.use_gazebo_world`](./index.html#first_steps).
The require does not change.

To avoid installing all of gazebo and the gazebo plugins, while still being able to
load `rock_gazebo/syskit` to get `use_sdf_model`, one has to exclude the simulation
packages while simultaneously adding `simulation/rock_gazebo` explicitly in the layout.
In your autoproj manifest, do something along the lines of:

~~~ yaml
layout:
   - my.main.metapackage
   # Force-add simulation/rock_gazebo despite the simulation/.* exclude rule
   - simulation/rock_gazebo

excluded_packages:
   - simulation/.*
~~~
