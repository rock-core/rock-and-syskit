---
layout: documentation
title: Models, Links, Joints and Sensors
sort_info: 10
---

# Models, Links, Joints and Sensors
{:.no_toc}

- TOC
{:toc}

In this section, we will learn how models defined in a Gazebo SDF world are made
accessible within the Syskit system. We will limit ourselves to the supported built-in
elements of a model: links, joints and sensors. The [next section](plugins.html) will
cover plugins.

## Models

The gist of things is to "dedicate" a Syskit profile to be the interface for a given
model in Gazebo, the same way that we usually "dedicate" a profile for a given robot
system. This profile, usually called `Base` will contain a `use_gazebo_model` stanza.

~~~ ruby
module MyBundle
    module Profiles
        module Gazebo
            profile "Base" do
                # prefix_device_with_name is a backward compatibility thing.
                # Just pass true.
                use_gazebo_model "model://ModelName", prefix_device_with_name: true
            end
        end
    end
end
~~~

This stanza will define a number of devices for [links](#links), [sensors](#sensors) and [plugins](plugins.html)
These devices are named after the full gazebo name, with gazebo's `::` separator replaced by `_` and
resp. `_link`, `_sensor` and `_plugin` suffixes.

For instance, in

~~~
<model name="wet_paint">
    <link name="camera" />
</model>
~~~

the device that represents the model will be named `wet_paint` and the one for
the link `wet_paint_camera_link`, respectively accessible via `Base.wet_paint_dev` and
`Base.wet_paint_camera_link_dev`. See [our tutorial](../basics/devices.html) for
a live example.

The stanza exposes a device per link. This device, of type
[CommonModels::Devices::Gazebo::Link](https://github.com/rock-core/bundles-common_models/blob/master/models/devices/gazebo/link.rb)
exposes the whole link state (pose, velocity and acceleration), and allows to
apply efforts to it through its `Wrench` input port.

When the model is root in the world, i.e. is not child of another model, a
device of type
[CommonModels::Devices::Gazebo::RootModel](https://github.com/rock-core/bundles-common_models/blob/master/models/devices/gazebo/root_model.rb)
will also be created. This device exposes the model's pose and allows to change it.
It is useful mainly to place a model in a certain pose without having to control it through
forces. However, if you do not want to lose composability of your models, do not use this feature.

**Note**: an ill-documented behavior of Gazebo is that a model pose is the pose of
its canonical link, which in general is the first link of the model
{: .alert .alert-info}

## Reusing Gazebo-related devices across profiles

One must never have two `use_gazebo_model` stanzas with the same model in two different
profiles that are used on the same system. The recommended way to deal with the need
to share gazebo-related devices across profiles is to have a `Base` profile that does
the `use_gazebo_model`, and then refer to these devices explicitly, as e.g.
`Base.wet_paint_camera_dev`

## Accessing Links {#links}

Instead of using the pre-defined link devices, we recommend that you define
devices for the links you need through the `sdf_export_link` stanza. This stanza
creates a
[CommonModels::Devices::Gazebo::Link](https://github.com/rock-core/bundles-common_models/blob/master/models/devices/gazebo/link.rb)
device that allows to read the status of the link, as well as apply an effort (a
wrench) on it.

~~~ ruby
module MyBundle
    module Profiles
        module Gazebo
            profile "Base" do
                # prefix_device_with_name is a backward compatibility thing.
                # Just pass true.
                use_gazebo_model "model://model_name", prefix_device_with_name: true

                sdf_export_link(
                    model_name_dev, as: "some2other",
                    from_frame: "model_name::some",
                    to_frame: "model_name::other"
                )
            end
        end
    end
end
~~~

The `as` argument declares the device name (which in this case will therefore be
accessed with `Base.some2other_dev`). `from_frame` defines the name of the link
whose pose the device's pose output will publish, and `to_frame` the name of the
reference link (i.e. w.r.t. the `from_frame` link's pose will be calculated).
The `to_frame` is considered fixed in these calculations (i.e. we do not compute
relative velocities). The `world` frame represents the frame attached to the origin
of the Gazebo world.

We recommend following [these conventions](../libraries/geometric_transformations.html)
to name the exported link, that is always `${from_frame}2${to_frame}`. Note that the
world frame is always available via `world`.

For instance, assuming we have a vehicle's model named `customvehicle` and that this
vehicle has a camera attached to a tilt unit. The SDF could be:

~~~ xml
<model name="custom_vehicle">
    <link name="cog" />
    <link name="camera" />

    <joint name="camera2cog" type="revolute">
        <parent>cog</parent>
        <child>camera</child>
    </joint>
</model>
~~~

Within the simulation, one could get access to the `camera2cog` transform through
the `camera2cog_dev` device declared by:

~~~ ruby
module CustomVehicle
    module Profiles
        module Gazebo
            module Base
                use_gazebo_model "model://custom_vehicle", prefix_device_with_name: true

                sdf_export_link(
                    custom_vehicle_dev,
                    as: "camera2cog", from_frame: "custom_vehicle::camera",
                    to_frame: "custom_vehicle::cog"
                )
            end
        end
    end
end
~~~

## Accessing Joints

Subset of the joints can be exported as single devices via the
`sdf_export_joint` stanza.  This defines an interface of type
`CommonModels::Services::JointsControlledSystem`, through which you can control
the joints and read its status. For instance, assuming our custom vehicle has a pan-tilt
unit for the camera, with separate pan and tilt joints, the following declaration will
create a `Base.camera_ptu_dev` device that will have one input and one output
of type `base::samples::Joints`, in which the elements will be first the tilt and then
the pan joint.

~~~ ruby
module CustomVehicle
    module Profiles
        module Gazebo
            module Base
                use_gazebo_model "model://custom_vehicle", prefix_device_with_name: true

                sdf_export_joint(
                    custom_vehicle_dev,
                    as: "camera_ptu",
                    ignore_joint_names: true,
                    joint_names: [
                        "custom_vehicle::camera_tilt_joint",
                        "custom_vehicle::camera_pan_joint"
                    ]
                )
            end
        end
    end
end
~~~

The `ignore_joint_names` instructs the component to assume that the order of the joints
on input is the declared order, and not care about the joint names. We recommend working
this way.

Gazebo supports setting a joint's effort, position and velocity. The input joints
must have exactly one of these fields set. If more than one is set, the model task will
go into the `INVALID_JOINT_COMMAND` exception.

## Recursive Models

As long as you

- use the model device only to read its position,
- use `sdf_export_link` and `sdf_export_joint`,
- use `ignore_joint_names: true` in `sdf_export_joint`

Then the gazebo-syskit integration gracefully handles having the model used in a
profile as a submodel of another in the world that is being actually loaded.
This allows for instance to define profiles that control complex parts of a
system (e.g. a manipulator), test them separately and then combine them in a
single system.

<div class="alert alert-info">
**How is this different from Gazebo ?** While [sdformat](http://sdformat.org) allows to have a `<model>` inside another, as well
as include a model inside another, what it does is lexically "flatten" the SDF to
have a single model. That is, all joints and links from submodels are placed in their
parent model, only adding the submodel name as prefix. It means that link and joint
names change when you combine your models.

For instance, from the perspective of Gazebo

~~~ xml
<model name="base">
  <model name="left_arm">
    <link name="base" />
  </model>
  <model name="right_arm">
    <link name="base" />
  </model>
</model>
~~~

is actually managed as:

~~~ xml
<model name="base">
  <link name="left_arm::base" />
  <link name="left_arm::right_arm">
</model>
~~~
</div>

## Using Sensors {#sensors}

Apart from links and models, the [`use_gazebo_model`](models_links_and_joints.html)
stanza will create devices to expose devices that are present in the sdformat model.
The Syskit support for Gazebo handles only a subset of the sensors available in Gazebo.
All sensor-related components are declared in the
[`simulation/orogen/rock_gazebo`](https://github.com/rock-gazebo/simulation-orogen-rock_gazebo)
package.

- `ray` are exposed as `rock_gazebo::LaserScanTask`
- `imu` are exposed as `rock_gazebo::ImuTask`
- `gps` are exposed as `rock_gazebo::GPSTask`
- `camera` are exposed as `rock_gazebo::CameraTask`

The devices are named after the sensor's full name, with the `_sensor` suffix, e.g.
a `camera` camera in the `wet_paint` model would be `wet_paint_camera_sensor_dev`.
In doubt, just open the syskit IDE and check the profile.
