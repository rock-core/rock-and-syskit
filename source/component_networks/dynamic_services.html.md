---
layout: documentation
title: Dynamic Services
sort_info: 37
---

# Dynamic Services
{:.no_toc}

- TOC
{:toc}

In the [Components reference section](../components/writing_the_hooks.html#dynamic_ports), we briefly
breached the subject of how one could create ports dynamically on a component.
This is rarely used, but is actually, nonetheless, very useful.

This page will expand on the subject from the perspective of Syskit: how, in
Syskit, dynamic ports are modelled and handled. The core concept behind this
integration is the _dynamic service_.

**Best practice** prefer instanciating more than one component to having dynamic
ports and dynamic services when possible
{: .important}

## Concept

Conceptually, dynamic ports are part of both a component's data flow interface
and its configuration interface. Syskit being rather obviously very dataflow oriented,
this "dual identity" is solved by providing a way to _declare_ that ports will exist
that are not part of the "main" component interface, along with some configuration
data. It is up to the component's [extension block](../components/runtime.html#extension_file)
to configure the component as required by the instanciated dynamic services.

For instance, the rock-gazebo integration has [`rock_gazebo::ModelTask`](https://github.com/rock-gazebo/simulation-orogen-rock_gazebo).
The component's `exported_joints` property is a list of set of joints that should be
exported on an output port (and for which commands can be received on an input port).

To integrate this in Syskit, we define a dynamic service in the
[rock_gazebo.rb extension file](https://github.com/rock-core/bundles-common_models/blob/master/models/orogen/rock_gazebo.rb#L83).
The block passed to `dynamic_service` does some bit of argument normalization and
then defines the required service (a device driver is a type of data service, and
therefore valid)

Later, the component updates the `exported_links` property accordingly within its own
[`#update_properties`](../components/runtime.html#extension_file) method.

## Declaring a dynamic service

Dynamic services are declared on the component model using the `dynamic_service` method.

~~~ ruby
dynamic_service Services::ServiceModel, as: "dynamic_service_name" do
    # Put here what to do to actually instanciate the service ... It usually is
    # simply a call to provides
    #
    # The name of the instanciated service is accessible as `name`. Instanciation
    # options (if any) are available as 'options' (a Hash)
    #
    # The name is omitted in the provides call. It is handled by the dynamic
    # service instanciation logic.
    provides Services::ServiceModel
end
~~~

The service model is the model of the data services that will be instanciated.
The `dynamic_service_name` is arbitrary, used when the dynamic services are to
be instanciated.

Within the block, the only thing that is required is to actually call `provides`
with the required model (that is, either the model itself, or a service that is
declared as [providing that model](./reusable_networks.html#data_service_relationships)).
However, this `provides` is different than the non-dynamic one. In the 'static' case,
`provides` will map the ports of the service to the ports of the task, and fail if ports
do not exist.

In the 'dynamic' case, however, Syskit will interpret missing ports as ports
that will be created by the component at runtime (that's the "dynamic" part).
One will often make these ports unique, which is done by using the
instanciated port name - available as the `name` method within the block. In the
example below, instanciating the `object_position` service with a name of `wall`
will be interpreted by Syskit as creating a port called `wall_position_samples`

Dynamic services can also refer to static ports. For instance, the `canbus::Task`
component will create one output per client, but has a single input for all the
CAN-connected devices.
{: .note}

~~~ ruby
dynamic_service CommonModels::Services::Position, as: "object_position" do
    provides CommonModels::Services::Position,
             "position_samples" => "#{name}_position_samples"
end
~~~

## Component Configuration

The configuration that matches the instanciated dynamic services must be generated
within the `#update_properties` method within the [component extension
file](../components/runtime.html). One calls `#each_required_dynamic_service`
and update the configuration accordingly.

~~~ ruby
Syskit.extend_model Orogen.project.Task do
    def update_properties
        super

        properties.exported_objects = each_required_dynamic_service.map do |srv|
            # Options pass during instanciation are available as
            # `srv.model.dynamic_service_options`
            { name: srv.name }
        end
    end
end
~~~

## Instanciating a dynamic service

Let's reinforce something: instanciating a dynamic service actually _updates the
component model_. It does not actually create ports. Port creation will happen
at runtime, when the component is configured.

That "addition of new ports", however, allows to use the new ports in the
component network(s) as if they existed in the original model.

Instanciating a dynamic service is done with `with_dynamic_service`.

~~~ ruby
task_m_with_instanciated_service = task_m.with_dynamic_service(
    "dynamic_service_name", as: "service_name", **options
)
~~~

Where `"dynamic_service_name"` is the name of the dynamic service as provided to
`dynamic_service`. `service_name` is the name of the service once instanciated and
`options` is passed as-is to the dynamic service block, and is available as
`dynamic_service_options` during configuration.

<div>
**Very important** the method returns the component model with the newly added
dynamic service, which might be different from the original. For instance,

~~~ ruby
task_m = OroGen.rock_gazebo.ModelTask.with_dynamic_service("link_export", as: "new_s")
# Here, task_m != OroGen.rock_gazebo.ModelTask
task_m = task_m.with_dynamic_service("link_export", as: "another_s")
# Here, task_m stayed the same
~~~
</div>
{: .important}

## Dynamic Services on Compositions

Dynamic services can also be defined on composition, in which case

- there is (obviously) no `update_properties` step
- the `dynamic_service` block is still expected to provide the service, which can e.g.
  be done by either overloading an existing child, or even adding a new child