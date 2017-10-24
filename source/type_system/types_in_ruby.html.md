---
layout: documentation
title: Types in Ruby
sort_info: 20
---

# Types in Ruby
{:.no_toc}

- TOC
{:toc}

You will be using Ruby to interact with a running system (_via_ Syskit) and
post-process log files. It's important to understand how the types that are
defined and exchanged from the C++ side end up being manipulated in Ruby.

## Basics

The mapping from C++ to Ruby is mostly as one would expect: one can create, read
or modify a struct by setting or reading its fields. One can access an array or
`std::vector` as one would access a Ruby array and so on.

For instance, an instance of the Time type we
already [used as example](defining_types.html#type_declarations):

~~~ cpp
namespace base {
  struct Time
  {
    uint64_t microseconds;
    static Time fromMilliseconds(uint64_t ms);
    Time operator +(Time const& other);
  };
}
~~~

would be accessed with:

~~~ ruby
obj.microseconds # current value of 'microseconds' as a Ruby integer
obj.microseconds = 20 # set the value of 'microseconds' to 20
~~~

A more complex struct such as:

~~~ cpp
namespace base {
  struct Timestamps {
    std::vector<base::Time> stamps;
  };
}
~~~

would be accessed with

~~~ ruby
obj.stamps[0].microseconds
obj.stamps << new_time
~~~

Enums are represented as Ruby symbols, so

~~~ cpp
namespace base {
  enum Result {
    OK, FAILED
  };
  struct S {
    Result status;
  };
}
~~~

would be manipulated with

~~~ ruby
obj.status # => :OK
obj.status = :FAILED
~~~

## Loading and Accessing Types {#import_types_from}

To get access to registered types within Syskit, one needs to call
`import_types_from` at toplevel with the oroGen project that defines the type:

~~~ ruby
import_types_from 'base'
~~~

From their on, all the types that the `base` typekit define are made available
under the `Types` object. For instance, the `base::Time` type is available
as `Types.base.Time`. Containers based on `std::vector` are mapped using
functions, e.g. `Types.std.vector(Types.base.Time)` for
`/std/vector</base/Time>`.

New objects can thus be created `Types.base.Time.new`. New objects - except
enums - are left uninitialized. Enums are initialized to the first valid value
in their definition. Call `#zero!` to zero-initialize an object.

The fields of a struct can be initialized on construction: `Types.base.Time.new(microseconds: 0)`.

## Converting between the C++ definitions and more Ruby-ish types

As it is, the Rock type system is optimized for C++. The types can have a
proper API, accessors, initialization … These parts of the types are available
in C++ but are "lost in translation" when passed to Ruby.

However, Ruby also has a rich ecosystem of built-in types and external
libraries, that sometimes match what the C++ types provide. For instance,
Rock's existing `base::Time` type has an equivalent in the Ruby `Time` class.
To ease the use of Rock on the Ruby side, the framework provides a way to
convert to and from pure-Ruby types. Rock's own `base/types` package defines
such conversions. The main (but no only) conversions are used to handle Eigen
types in Ruby (using built-in Eigen bindings), and the `Time` conversion that
we just described.

If one defines a conversion to ruby with:

~~~ ruby
Typelib.convert_to_ruby '/base/Time', Time do |value|
    microseconds = value.microseconds
    seconds = microseconds / 1_000_000
    Time.at(seconds, microseconds % 1_000_000)
end
~~~

Then the framework will automatically convert `/base/Time` values into Ruby's
Time using the given block. Note that the Ruby type is optional in this case
(whatever's returned by the block will be considered "the converted type")

**Important** the conversions must be defined **before** the type is loaded

**Where to define these ?** One-shot conversions can be defined straight into
your system (ruby script or Syskit app). For conversions that are too widespread
for that, consider installing a `typelib_plugin.rb` file under a folder that is resolved
by `RUBYLIB` (e.g. `mylib/typelib_plugin.rb`), most likely [a Ruby package](../integrating_functionality/ruby_libraries.html). 

The inverse conversion may also be provided

~~~ ruby
Typelib.convert_to_ruby Time, '/base/Time' do |value, type|
  type.new(
    microseconds: value.tv_sec * 1_000_000 + value.tv_usec)
end
~~~

**Reminder** if you don't understand the `/base/Time` syntax, we've covered that
when we talked about the type system's [naming scheme](defining_types.html#naming_scheme).
{: .note}

## Extending the Rock Types

An alternative to the conversions mechanism is to extend the types with new
methods, and/or initializers.

To define methods on the type class itself, one uses
`Typelib.specialize_model`. The following would for instance allow to create a
`/base/Angle` initialized with NaN by doing `Types.base.Angle.Invalid`

~~~ ruby
Typelib.specialize_model '/base/Angle' do
  def Invalid
    new(rad: position: Float::NAN)
  end
end
~~~

To define methods on the values themselves, one uses `Typelib.specialize`.

~~~ ruby
Typelib.specialize '/base/Angle' do
  def to_degrees
    rad * 180 / Math::PI
  end
end
~~~

It is possible to define an initializer this way:

~~~ ruby
Typelib.specialize '/base/Angle' do
  def initialize
    self.rad = Float::NAN
  end
end
~~~

**Important** the specializations must be defined **before** the type is loaded

**Where to define these ?** One-shot conversions can be defined straight into
your system (ruby script or Syskit app). For conversions that are too widespread
for that, consider installing a `typelib_plugin.rb` file under a folder that is resolved
by `RUBYLIB` (e.g. `mylib/typelib_plugin.rb`). This would either be a plain Ruby package
or a file installed by a C++ package within the Ruby search path. Both methods are
described in more details in the [Creating Functionality](../integrating_functionality/ruby_libraries.html) section.

**Next** that's all about the type system. Go back to [the documentation
overview](../index.html#how_to_read) for more.
{: .next-page}

