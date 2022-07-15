---
layout: documentation
title: Geometric Transformations
sort_info: 47
---

# Geometric Transformations
{:.no_toc}

- TOC
{:toc}

<div>
This is a page in a 3-part series.The [first
part](../libraries/geometric_transformations.html) presented the issue, and how
to handle geometric transformations within C++ libraries. The [third
part](../component_networks/geometric_transformations.html) dealt with system-level
concerns.

This part presents how it is handled at the component level.
</div>
{: .note}

At the component boundary (i.e. ports), one has to use Rock's
`base::samples::RigidBodyState` (RBS) type to represent the state (pose and
velocity) of a rigid body expressed in a certain reference frame, and in
particular frame transforms. Unlike in libraries, where a certain flexibility
exists, that flexibility disappears at the component interface because inputs
and outputs must be of the same type to connect.

However, just as with libraries, one has to see the component as a self-contained
algorithm. Frames names inside the component's code must be chosen _in relation
to_ the algorithm and not the system it will be integrated into. This applies
to the component ports as well.

Generally speaking, define your frames precisely either in the orogen file (if
it is relevant for the component interface) or in the C++ files if it is
internal, and follow for ports [the same conventions](../libraries/geometric_transformations.html#conventions) than with variables in C++ code.
The one deviation from this convention is to use `_samples` as output prefix
(instead of one of the accepted prefixes) for RigidBodyState values that contain
composite quantities (e.g. pose+velocities).

## Generic Handling of Kinematic Chains: Rock's Transformer

A popular functionality in robotic software frameworks is the ability to
transparently provide to components the transformations between any two frames
on the system. This is critical to avoid embedding the kinematic structure of
a system in components that don't need it.

In Rock, this is done by the transformer. Each component that uses the transformer
gets as well:

- a certain number of transformation on the component's `dynamic_transforms` input port
- a certain number of transformation on the component's `static_transforms` property

The transformer then will be able to compute certain frame transforms for the benefit
of the algorithm inside the component. The rest of this page will present its usage.

It is somewhat tempting to use the transformer to manage all transformations
within a system. **Don't**. The transformer is really meant to handle variations
in the robotic system itself (placement of sensors and actuators). For
environment-robot transformations (pose and velocity of the robot, ...), stick
to having separate input ports.
{:.alert .alert-danger}

## Correspondence of global and local frame names

Any RigidBodyState that is meant to be passed as an input to the transformer
**must** fill the `RigidBodyState` `sourceFrame` and `targetFrame` field. As a
reminder, the `sourceFrame` is the object whose pose is being described, while
`targetFrame` is the reference frame.

Unlike the "internal" frame names chosen for variables or ports, the names
within the `RigidBodyState` are global frame names. As such, they have to be
configurable. To play nice with Syskit's support for the transformer, you must
name the property that will contain these names `${internal_frame_name}_frame`, of
type `/std/string`

For instance, let's assume I have a component that uses a lidar to compute the
transformation between an object and a reference frame. I would naturally define
`object` and `ref` as the frames of my output, name the output port `object2ref_pose`
and, assuming that I intend to use this output in the transformer, I would:

- define the `object_frame` and `ref_frame` properties of type '/std/string'
- fill the `RigidBodyState`'s `sourceFrame` with `_object_frame.get()` and
  the `targetFrame` with `_ref_frame.get()`

## Using the transformer

Components that require a transformation between two frames on the system's body
should use the transformer to get it. The main advantage to do so is that it
gives the system a single source of truth, and makes configuration a lot easier.

What should _never_ be injected in the transformer are output of probabilistic
estimations that have high uncertainty (such as any SLAM, really)

### Setup

Components that will want to use the transformer must depend on
the `drivers/orogen/transfomer` package, by adding the following line to the
package's `manifest.xml`.

~~~ xml
<depend package="drivers/orogen/transformer" />
~~~

### Transformer definition in the orogen file

Within the `task_context` block, one configures the transformer by passing
a block to the `transformer` statement, like so:

~~~ ruby
task_context "Task" do
    needs_configuration
    ...
    transformer do
        # Configuration statements
    end
end
~~~

Transformers are also [stream aligners](./stream_aligner.html): they align
streams to compute the best transform estimate, and also to optionally align
other data streams with the transform stream. As such, they need a `max_latency`
argument to set a default latency.

The main transform declaration statement is `transform`. It declares that the
component needs a certain transform, using frame names specific to the
component/algorithm.  For instance, in the context of the lidar object pose
estimation component I outlined above, we would do

~~~ ruby
task_context "Task" do
    needs_configuration
    ...
    transformer do
        transform "lidar", "ref"
        max_latency 0.1
    end
end
~~~

Another example: a visual servoing component that takes visual features as input
and provides a command within the vehicle's body frame would have the need for
the `features` to `command` transform. It would be declared with

~~~ ruby
task_context "Task" do
    needs_configuration
    ...
    transformer do
        transform 'features', 'command'
        max_latency 0.1
    end
end
~~~

The data that is meant to be processed with the transform can be _aligned_ with it.

~~~ ruby
transformer do
    align_port "detected_features"
    transform "features", "command"
    max_latency 0.1
end
~~~

In that case, a callback will be generated, much like with the [stream
aligner](./stream_aligner.html).  The difference is in the name: while the
stream aligner callbacks are named `${port_name}Callback`, the transformer ones
are named `${port_name}TransformerCallback`. In doubt, always look at the fresh
templates in the orogen's `templates/` folder.

~~~ cpp
void Task::detected_featuresTransformerCallback(const base::Time &ts, const ::VisualFeatures& features) {
}
~~~

### Transformer in the C++ Code

Being, under the hood, a stream aligner, [the rules](./stream_aligner.html#cpp)
related to usage of ports and `updateHook` implementation apply to the
transformer as well
{: .alert .alert-danger}

Within the C++, the transform object is available through a generated
`_features2command` object which can be queried through its `.get` method.

The first argument to `.get` controls what is the expected time of the queried
transform. It is needed only if the transformer is expected to generate an
_interpolated transform_ by setting the third argument to `true`.

When the third argument is `false`, the transformer computes the kinematic
chain using the transforms whose timestamp is just before the given `time`. If
it is `true`, it interpolates the transformation from the transforms it
received with a timestamp just before the passed timestamp, with the transforms
it received with a timestamp just after.

Note that this functionality will only work reliably inside the transformer
callbacks, since it ensures that the given time is ordered in time. The
transformer does not keep a full history of everything it receives, and is
therefore very likely to fail to interpolate or even return a transform if
called outside the stream alignment callback.

**Example**: accessing a transformation within a transformer callback

~~~ cpp
void Task::detected_featuresTransformerCallback(const base::Time &ts, const ::VisualFeatures& features) {
  base::samples::RigidBodyState features2command;
  if (!_features2command.get(ts, features2command, true))
  {
      // no transform available yet, do nothing
      return;
  }

  // Do the processing
}
~~~

**Example**: accessing a transformation in the updateHook

~~~ cpp
void Task::updateHook() {
    // VERY IMPORTANT. Must be first, ports are read here by the stream aligner
    TaskBase::updateHook();

    base::samples::RigidBodyState features2command;
    // Thirst argument MUST be false
    if (!_features2command.get(base::Time::now(), features2command, false))
    {
        // no transform available yet, do nothing
        return;
    }

    // Do the processing
}
~~~

## Limitations and Guidelines

See the [caveats](../component_networks/geometric_transformations.html#caveats) and
the [guidelines](../component_networks/geometric_transformations.html#guidelines) from
the system part.