---
layout: documentation
title: Backward compatible naming
sort_info: 10
---

# Backward Compatible Naming
{:.no_toc}

- TOC
{:toc}

## Old Behavior

### Folders

- action interfaces are expected to be in `models/planners/`
- Syskit compositions are expected to be in `models/blueprints/`

Note that Syskit does not auto-load model files anymore - and it has been like
this for years. For systems that have not explicitly set
`Roby.app.auto_load_models` to true, this behavior is transparent (it is a
convention that is not affecting Syskit's behavior in any way).

### Main action interface

The toplevel action interface, the one that the system is using to resolve call
to both the `Robot` object and remote interfaces, is registered at toplevel as
`Main`. This is the interface that gets set up from the `Robot.actions` block

### OroGen and Typelib models

Historically, both oroGen and Typelib models (component and type description)
were exported as constants (as all classes in Ruby are, it seemed to be a good
behavior). Because constants in Ruby have required to all be named in CamelCase,
this involved translating the oroGen project name (or C++ type namespaces) from
`snake_case` to `CamelCase`.

For instance, the `video_streamer_webrtc::StreamerTask` component was made
available as `OroGen::VideoStreamerWebrtc::StreamerTask` class. Rock's
`base::samples::RigidBodyState` was available as
`Types::Base::Samples::RigidBodyState`

[OroGen extension files](../components/runtime.html#extension_file) were using
Ruby's "monkey patching" to allow extending the component models at loading time.
For instance, the video streamer model would be extended with:

~~~ ruby
class OroGen::VideoStreamerWebrtc::StreamerTask
    ...
end
~~~

## New Behavior

### Folders

- action interfaces are expected to be in `models/actions/`
- Syskit compositions are expected to be in `models/compositions/`

Note that Syskit does not auto-load model files anymore - and it has been like
this for years. For systems that have not explicitly set
`Roby.app.auto_load_models` to true, this behavior is transparent (it is a
convention that is not affecting Syskit's behavior in any way).

### Main action interface

The toplevel action interface, the one that the system is using to resolve call
to both the `Robot` object and remote interfaces, is registered under the
`Actions` namespace, as `Actions::Main`. This is the interface that gets set up
from the `Robot.actions` block

### OroGen and Typelib models

Classes in Ruby are objects, and as such can be returned by methods. We now use
this to allow a more natural mapping from the namespaces to method names.

OroGen models are to be resolved from the `OroGen` namespace like this:
`OrGen.video_streamer_webrtc.StreamerTask`. Types from the `Types` namespace:
`Types.base.samples.RigidBodyState`

OroGen models must be extended using the `Syskit.extend_model` call as documented
in the [component development section](../components/runtime.html#extension_file):

~~~ ruby
Syskit.extend_model OroGen.video_streamer_webrtc.StreamerTask do
    ...
end
~~~

## New/old behavior: control and migration

The new behavior is automatically available. The old behavior is retained by
default. To disable, set `Roby.app.backward_compatible_naming` to false in either
`config/init.rb` or in a robot config's `init` block.

To make sure you have converted all your models and scripts, the simplest is to
grep for the `Main`, `OroGen::` and `Types::` patterns in the source code and convert
all matches.

Note that the flag is global. Dependent syskit bundles must have migrated before
you can turn off `backward_compatible_naming` yourself.

As noted in the respective sections, the change in folder structure is a convention,
unless you have `only_load_models` set to true. Nonetheless, we recommend changing
the folder (and namespace) for consistency reasons.
