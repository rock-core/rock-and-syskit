---
layout: documentation
title: Writing the Hooks
sort_info: 40
---

# Writing the Hooks
{:.no_toc}

- TOC
{:toc}

This page describes the part of the C++ API, and their usage pattern, that are
relevant to the implementation of the hooks in a Rock component. You should
already have familiarized yourself with [the component
interface](interface.html) and its [lifecycle state
machine](state_machine.html).

## Interface Objects in C++

There is one C++ object for each declared interface element. The name of the
object is the name of the element with a leading underscore. For instance,

~~~ruby
# Another documentation string
output_port 'out', 'another_type'
~~~

is mapped to a C++ attribute of type `RTT::InputPort<another_type>` called
`_out`.

## Code Generation and Code Updates

oroGen will not update a file that is already present on disk. Whenever an
interface object requires the addition or removal of a method (operations and
dynamic properties), one must manually modify the corresponding files in
`tasks/`. To ease the process, oroGen does update template files in
`templates/`

In order to achieve this, each component is implemented in two classes: the one
you modify - which has the name declared in the orogen file - and a `Base`
class that is directly modified by orogen. The latter is where the interface
objects are defined. Have a look if you're interested in understanding more
about the component's implementation. It's in the `.orogen/tasks/` directory
{: .note}

## Properties

Plain properties are read only. They must be read either in the `configureHook()` or
in the `startHook()`. Syskit will write them before calling `configure`.

A property is read with `.get()`:

~~~ cpp
configuration_type config = _name.get();
~~~

Dynamic properties can be read at runtime. However, the property update method
is called in-between two hooks, and therefore any delay due to the update will
impact the component's update rate, plus one must take into account that the
state of the system does change in-between two `updateHook` calls. In other
words, dynamic properties have a cost both on the component's implementation
complexity and on its predictability. __Use them wisely__.

There are two ways to handle dynamic properties. Either by reading the property
object repeatedly, or by implementing a hook method that is called when the
property is written at runtime. This hook method is called `setPropertyName`
for a `property_name` property. In doubt, check the template files in
`templates/`.

If you do reimplement this method, always call the method from the base class
(as the generated template instructs you to do).

## Ports

The ports map to C++ attributes on the component class, with the name prefixed
by an underscore (i.e. `_in` and `_out` here. The most common operation is to
read the input port and write an output port;

~~~ cpp
my_type in_sample;
RTT::DataFlow status = _in.read(sample);
another_type out_sample;
_out.write(out_sample);
~~~

The `status` return value indicates whether there was nothing to read
(`RTT::NoData`), a new, never-read sample was read (`RTT::NewData`) or an
already-read sample was read (`RTT::OldData`). Let's now look at the common
port-reading patterns.

All input ports are cleared on `startHook`, i.e. just after `startHook`, the
status will very likely be `NoData`. This is done so that the component does not read
stale data from its last execution.
{: #port-clear-on-start}

Input ports can be used in the C++ code in two ways, which one you want to use
depends on what you actually want to do.

* if you want to read all new samples that are on the input (since an input port
  can be connected to multiple output ports)

  ~~~ cpp
  // my_type is the declared type of the port
  my_type sample;
  while (_in.read(sample, false) == RTT::NewData)
  {
      // got a new sample, do something with it
      // The 'false' here is a small optimization
  }
  ~~~

* if you are just interested by having some data

  ~~~ cpp
  // my_type is the declared type of the port
  my_type sample;
  if (_in.read(sample) != RTT::NoData)
  {
      // got a sample, do something with it
  }
  ~~~

Finally, to write on an output, you use 'write':

~~~ cpp
// another_type is the declared type of the port
another_type data = calculateData();
_out.write(data);
~~~

Another operation of interest is the <tt>connected()</tt> predicate. It tests if
there is a data provider that will send data to input ports
(<tt>in.connected()</tt>) or if there is a listener component that will get the
samples written on output ports.

For instance,

~~~ cpp
if (_out.connected())
{
    // generate the data for _out only if somebody may be interested by it. This
    // is useful if generating // the data is costly
    another_type data = calculateData();
    _out.write(data);
}
~~~

## Dynamic Ports {#dynamic_ports}

Components that have a dynamic port mechanism must create these ports in
`configureHook`. They will usually do so based on information on their
properties.

For the purpose of example, let's assume that we're implementing a time source,
and need different ports to be at different periods. A valid configuration type
would be

~~~ cpp
struct PortConfiguration
{
   std::string port_name;
   base::Time period;
};
~~~ 

To hold the list of created ports, the task would need an attribute

~~~ cpp
typedef RTT::InputPort<type::of::the::Port> TimeOutputPort;
std::vector<TimeOutputPort*> mCreatedPorts;
~~~

The task's `configureHook` would create the ports (after checking for e.g. name
collisions)

~~~ cpp
for (auto const& conf : _port_configurations.get())
{
  TimeOutputPort* port = new TimeOutputPort("name_of_the_port");
  ports()->addPort(port);
  mCreatedPorts.push_back(port);
}
~~~

and `cleanupHook` would remove and delete them

~~~ cpp
while (!mCreatedPorts.empty())
{
  TimeOutputPort* port = mCreatedPorts.back();
  mCreatedPorts.pop_back();
  ports->removePort(created_port->getName());
  delete created_port;
}
~~~

## Operations

Operations map to a C++ method. E.g. for the declaration

~~~ruby
operation('operationName').
    returns('int').
    argument('arg0', '/arg/type').
    argument('arg1', '/example/other_arg')
~~~

oroGen will generate a method with the signature

~~~ cpp
return_type operationName(arg::type const& arg0, example::other_arg const& arg1);
~~~

By default, the operations are run into the thread of the callee, i.e. the thread of
the component on which the operation is defined. This is easier from a thread-safety
point of view, as one thus guarantees that there won't be concurrent access to the task's
internal state. However, it also means that the operation will be executed only when all
the task's hooks have returned (waiting potentially long).

If it is desirable, one can design the operation's C++ method to be thread-safe
and declare it as being executed in the caller thread instead of the callee
thread. This is done with

~~~ ruby
operation('operationName').
    returns('int').
    argument('arg0', '/arg/type').
    argument('arg1', '/example/other_arg').
    runs_in_caller_thread
~~~

We've covered how a component's code is structured inside the component's state machine.
Let's move on to more specific implementation topics, chief of which the one of [timestamping](timestamping.html).
{: .next-page}
