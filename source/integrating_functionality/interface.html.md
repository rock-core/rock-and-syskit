---
layout: documentation
title: Interface
sort_info: 35
---

# Component Interfaces
{:.no_toc}

- TOC
{:toc}

We'll cover in this page how to define your task's interface. All statements
presented in this page are to be included in a component definition, i.e.
between 'do' and 'end' in

~~~ ruby
task_context "ClassName" do
   needs_configuration

   ...
end
~~~

The only constraint on `ClassName` is that it *must* be different from the
project name. How one is meant to interact with these elements in the task's
own code is dealt with [later](writing_the_hooks.html)

The `needs_configuration` statement is historical and should always be present.

## Abstract Tasks {#abstract}

orogen supports subclassing a component class into another component class. Of
course, in some cases, one would create a component class that is only meant to
be subclasses. This is declared with the `abstract` statement, which ensures that
orogen will not attempt (nor allow to) create a component instance from this class.

~~~ ruby
task_context "ClassName" do
  needs_configuration
  abstract
  ...
end
~~~

## Interface Elements

![RTT Component Interface](media/orocos_component.svg)
{: .fullwidth}

 * **Ports** are used to transfer data between the components
 * **Properties** are used to store and set configuration parameters
 * Finally, **Operations** (not represented here) are used to do remote method
   calls on the components

As a general rule of thumb, the components should communicate with each other
only through ports. The properties and operations (as well as the state machine
covered in [the next page](state_machine.html)) are meant to be used by
a coordination layer, namely Syskit in our case.

### Ports
Ports are defined with

~~~ ruby
# A documentation string
input_port 'in', 'my_type'
# Another documentation string
output_port 'out', 'another_type'
~~~

### Properties

Properties are defined with

~~~ ruby
# What this property is about
property 'name', 'configuration_type'
~~~

Plain properties must be read by the component only before it is started. If
one needs to be able to change the value at runtime, the property must be
declared `dynamic`:

~~~ ruby
# What this property is about
property('name', 'configuration_type').
  dynamic
~~~

**Don't make everything dynamic**. Use dynamic properties only for things that
(1) won't affect the component functionality when the property is changed and
(2) for which the "dynamicity" is easy to implement. A counter example is for
instance a device whose change in parameter would take a few seconds. This
should definitely *not* be dynamic. A good example would be a simple scaling
parameter, which is only injected in a numerical equation - that is something
that won't require any internal reinitialization.
{: .important}

### Operations

The operations offer a mechanism from which a task context can expose
functionality through remote method calls. They are defined with:

~~~ ruby
# Documentation of the operation
operation('commandName').
    argument('arg0', '/arg/type').
    argument('arg1', '/example/other_arg')
~~~

Additionally, a return type can be added with

~~~ ruby
operation('operationName').
    returns('int').
    argument('arg0', '/arg/type').
    argument('arg1', '/example/other_arg')
~~~

Note the dot at the end of all but the last line. This dot is important and, if
omitted, will lead to syntax errors. If no return type is provided, the
operation returns nothing.

**When to use an operation ?** Well, don't. Mostly. Operations should very
rarely be used, as they create hard synchronization between components. The one
common case where an operation is actually useful is if something _really
expensive_ needs to rarely be done in the middle of the component processing,
such as dumping an internal state that is really expensive to dump.
{: .important}

### Dynamic Ports {#dynamic_ports}

Some components (e.g. the logger or the canbus components) may create new ports
at runtime, based on their configuration. To integrate within Syskit, it is
necessary to declare that such creation is possible. This is done with the
`dynamic_input_port` and `dynamic_output_port` statements, possibly using a
regular expression as name pattern and either a message type or nil for "type
unknown".

The following for instance declares, in the Rock
[canbus::Task](https://github.com/rock-drivers/drivers-orogen-canbus), that
ports with arbitrary names might be added to the task interface, and that these
ports will have the /canbus/Message type. 

~~~ ruby
dynamic_output_port /.*/, "/canbus/Message"
~~~

oroGen currently provides no support for dynamic ports at the C++ level.
`dynamic_output_port` and `dynamic_input_port` are purely declarative, it is
the job of the component implementer to handle their creation and destruction.
This is details [later in this section](writing_the_hooks.html#dynamic_ports)

Syskit expects dynamic ports to be created at configuration time and removed at
cleanup time. 

## Inheritance

It is possible to make the components inherit from each other, and have the
other oroGen features play well.

Given a `Task` base class, the subclass is defined with

~~~ ruby
task_context "SubTask", subclasses: "Task" do
end
~~~

When one does so, the component's subclass inherits from the parent. This means
that it has access to the methods defined on the parent class, and also that
it inherits the parent's class interface.

When inheriting between task contexts, the following constraints will apply:

 * it is not possible to add a task interface object (port, property, ...) that
   has the same name than one defined by the parent model.
 * the child shares the parent's [state definitions](state_machine.html)

Finally, "abstract task models", i.e. task models that are used as a base for
others, but which it would be meaningless to deploy since they don't have any
functionality can be marked as abstract with

~~~ ruby
task_context "SubTask" do
    abstract
end
~~~

One can also inherit from a task defined by another oroGen package. Import the
package first at the top of the `.orogen` file with

~~~ ruby
using_task_library "base_package"
~~~

and subclass the task from `base_package` using its full name:

~~~ ruby
task_context 'Task', subclasses: "base_package::Task" do
end
~~~

**Next** let's have a look at the component [lifecycle state machine](state_machine.html)
{: .next-page}

