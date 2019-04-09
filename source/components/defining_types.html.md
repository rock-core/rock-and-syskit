---
layout: documentation
title: Defining Types
sort_info: 5
---

# Defining Types
{:.no_toc}

- TOC
{:toc}


Types are first defined in C++. However, not all C++ types can be used. There
are limitations to which types are acceptable, and ways to work around these
limitations. This page will detail this.

They are then injected in Rock's type system through Rock's code generation
tool, `orogen`. The [next section](importing_types.html) deals with this topic.

## C++ Standard {#cxx_standard}

The C++ standard used by orogen is the latest standard required by its dependencies.
There is currently no way to tell orogen itself to use a given standard. One must
specify the standard [in the library packages that define the types](../libraries/cpp_libraries.html#cxx_standard).

## Type Declarations {#type_declarations}

Not all C++ types can be used by Rock's type system. To be usable as-is, a type must:

* be default constructible and copyable (i.e. have a constructor that have no
  arguments and can be copied).
* have no private fields
* have only public ancestors, that fit the definition of "acceptable type".
* not use pointers.

In addition, Rock does support `std::string` and `std::vector` standard
classes, so you can use them freely. Moreover, for types that can't be directly
managed by oroGen, the mechanism of [opaque types](importing_types#opaques) allows to
integrate them in the Rock workflow anyways. Opaque types must however
still be copyable.

Example: defining a Time class

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

## Type Names {#naming_scheme}

The Rock type system does not use the same naming scheme than C++ for types.
Parts of a type are separated by a forward slash `/`. A well-formed type name
is always absolute (always starts with /).

For instance, Rock's `base::Time` is `/base/Time` within the type system.

Containers derived from `/std/vector` do use the `<>` markers: `/std/vector</base/Time>`

## Handling of C++ templates {#templates}

Templates are not directly understood by oroGen. However, explicit
instantiations of them can be used.

Unfortunately, typedef'ing the type that you need is not enough. You have to
use the instantiated template directly in a structure. To work around this, you
can define a structure whose name contains the `orogen_workaround` string to
get the template instantiated, and then define the typedefs that you will
actually use in your typekits and oroGen task interfaces.

For instance, with

~~~ cpp
template <typename Scalar, int DIM>
struct Vector {
  Scalar values[DIM];
};

struct __orogen_workaround {
  Vector<3> vector3;
  Vector<4> vector4;
};
~~~

One can use Vector&lt;3&gt; in its orogen interface, and in other structures.
The `__orogen_workaround` structure itself will be ignored by oroGen to avoid
polluting the type system.

**Next** Now that you know all about defining data types, let's get to understand how
they are seen [from within Ruby](types_in_ruby.html)
{: .next-page}
