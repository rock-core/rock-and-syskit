---
layout: documentation
title: Ruby Library Packages
sort_info: 20
---

# Geometric Transformations
{:.no_toc}

- TOC
{:toc}

<div class="panel panel-default" markdown="1">
This is a page in a 3-part series. This page will present the main issue at
hand, and a set of conventions and tools that exist within Rock to deal with it.
The [second part](../components/geometric_transformations.html) talks about
integration at the component boundary. The [third
page](../component_networks/geometric_transformations.html) explains how Syskit
handles it at the system level.
</div>

One very common task in robotics code is to represent the relationship between
different rigid bodies, and transform data between them.  For instance, a robot
body (or one of its parts) and the world. E.g. a gripper and an object being
gripped, an AUV and the ground, ... These relations
are usually estimated through complex processing chains. The object-gripper
relation is built by sensing the object in one or multiple sensors (LIDAR,
camera, ...) which are attached on the robot. Each of these sensors provide
information about the pose of the object _in the sensor frame_. A.k.a. the
sensor-object transform.

Within libraries, one will usually assume some data to represent given transformations,
that will allow us to transform input data into some other representation on the output.
For instance, a LIDAR will give us ranges from the LIDAR frame, but a library
may want to transform that into a common fixed frame to fuse them as point clouds.

This last example will be used as an illustration in the rest of this page

## Relations between Rigid Bodies

Some people did a much better work that I ever could to properly define, describe
and discuss relations between rigid bodies. I highly recommend you read their work:
[Geometric relations between rigid bodies (part 1): Semantics for standardization](
https://scholar.google.com/citations?view_op=view_citation&hl=en&user=U8peLJkAAAAJ&citation_for_view=U8peLJkAAAAJ:evX43VCCuoAC)

While their definition(s) are by far the most precise and useful, we'll narrow
things down to transforming positions and orientations and/or velocities (linear
and angular, that is twists) between frames of reference *considered fixed*. That
is, we won't be combining velocities (yet).

A _frame of reference_ in this case is a combination of a 3-vector cartesian
frame (which, in Rock, is always following the X-forward, Z-up convention) and
an origin point.

One thing to realize at this point is that all frame of references are relative
to each other. What we call a _pose_ is actually the pose of a frame of reference
_expressed in another's frame of reference_. There is no such thing as a "position"
in a vacuum.

## Defining frames of reference in code

When coding, we define (that is, name) frame of references locally to the algorithm.
In the LIDAR-to-pointcloud example above, the common frame into which data will be
transformed could be called "ref" (for "reference") regardless of what - when
the algorithm will be used - this target is meant to be. The LIDAR frame could
be "lidar".

But what is *really* important is to properly define the meaning and orientation
of each frame of reference, and document it

- in the algorithm's class or namespace documentation if these frames are used as part
  of the algorithm's public interface
- within methods/functions that define them for intermediate frames

* its name
* on which rigid body it is fixed
* its orientation w.r.t. said rigid body.

Regarding the last point: even though the "X-forward and Z-up" convention
guideline already constrains choices, there are quite a few things for which
"forward" and "up" are not obvious choices (example: a propeller)

## Conventions

That having been said, the most common error is to apply transformations in the
wrong order and/or the wrong transformations. The following convention aims
at reducing (drastically) the amount of such errors.

Whenever you create a quantity that represents a state of the frame A, expressed
in another's frame B (A and B being of course properly documented) you write:
`A2B_quantity`

For instance, `lidar2vessel_pose` or `target2ref_ori`

With the following quantity keywords (as well as accepted short version):
- pose,
- orientation (ori),
- position (pos),
- angular_velocity (angv),
- linear_velocity (linv),
- twist, combination of linear and angular velocity
- linear_acceleration (linacc),
- angular_acceleration (angacc),
- acceleration (acc), combination of linear and angular

With this convention, for instance, 'lidar2vessel_pos' is the position of the
lidar origin within the vessel frame

To apply transformations, in all the implementation for transformations we're
going to present, one combines quantities from right to left. Operations to the
left allow to change the frame the quantity is expressed _in_ (i.e. the right
part), while operations to the right change the frame the quantity represents
(i.e. the left part).

The pose of the lidar in an arbitrary object frame, can for instance be computed
with:

~~~
lidar2object_pose = ref2object_pose * vessel2ref_pose * lidar2vessel_pose
~~~

While inverting a relation swaps the two sides:

~~~
ref2object_pose = inverse(object2ref_pose)
~~~

**Recommendation**: do not hesitate to create intermediate variables with the "right"
names before you combine them in expressions. It makes validating the combinations
(and therefore, avoiding mistakes that are hard to discover) that much easier.

## Common and Non-Recommended frame Names

We strongly recommend to never use `body` and `world` as frame names. `Body` is
highly context dependent (which body are we talking about ?) and `world` is
usually "any common fixed reference frame".

Common frame names:
- `sensor` for the reference frame of the sensor being processed (if the
  algorithm only handles one)
- `ref` for the a common fixed reference frame

## Geometric Relations with Eigen (C++)

Eigen itself has easy-to-use implementations to deal with state (i.e. pose, position
and orientation).

The main type for position is `Eigen::Vector3d` (or `Vector3f` if you don't need
the precision). Orientations are computed with `Eigen::Quaterniond` or
`Eigen::Quaternionf` and poses with `Eigen::Affine3d` / `Eigen::Affine3f`

A well known pain point of Eigen is its alignment requirements. Rock provides
unaligned specializations of these types: just include `base/Eigen.hpp` and
replace `Eigen` by `base`. Use unaligned types in anything that looks like a
container, and as fields of types that are meant to go on component interfaces.
"Normal" Eigen types can be used without problem as class attributes, when
allocated on the stack and as function arguments.

These quantities are combined with the `*` operator, e.g.

~~~
lidar2object_pose = ref2object_pose * vessel2ref_pose * lidar2vessel_pose
~~~

## Uncertainties

Transforming uncertainties is ... patchy at best. The problem is the one of
representation, as for instance a rotated gaussian distribution represented
as a covariance matrix in a frame X is not itself represent-able as a covariance
matrix.

There are some types that can be used to manipulate and transform quantities
with uncertainties: `base::TransformWithCovariance` applies some linearization
algorithms to transform covariances on position and orientation while they
are being transformed.

## Relationship with Rock's base::samples::RigidBodyState (C++)

`base::samples::RigidBodyState` is a type that is usually not meant to be used
inside libraries. It is meant to be used on a component's port, and may be used
at the library interface. It is described in [the second
part](../components/geometric_transformations.html) of this series.

The pose part of `RigidBodyState` can be converted to/from `Eigen::Affine3d` with
`getTransform` and `setTransform`.

## Unset values in combined types

It is common to use a combined type to avoid passing multiple fields as separate
arguments to functions, but using only parts of them (e.g.  the twist and pose
but not acceleration and wrench). When fields do not contain valid values, they
should be initialized with NaN. Rock defines the `base::unset` template function
to make the semantic of that assignation easier.

`base::samples::RigidBodyState` is always initialized with all fields unset.

## Geometric Relations in Ruby

Rock's Ruby bindings are nowhere nearly as complete than the C++ APIs. It simply
includes Ruby bindings to Eigen's Vector3d (as `Eigen::Vector3`) and `Quaterniond`
(`Eigen::Quaternion`). You need to `require "eigen"`. The easiest way to create
a rotation is to use `Eigen::Quaternion.from_angle_axis(angle, vector)`

In addition, when within Syskit, `Types.base.samples.RigidBodyState.Invalid` allows
to create a properly initialized RBS.