---
layout: documentation
title: Extending oroGen
sort_info: 520
---

# Extending oroGen
{:.no_toc}

- TOC
{:toc}

oroGen plugins offer ways to add new statements to the oroGen specification
file, allowing to integrate some libraries in the component development
workflow. Two examples are the [stream aligner](TODO) and the
[transformer](TODO).

## General principle

The general plugin design is based on the extensible nature of the Ruby
language. How the plugin loading works is:

 * the OROGEN_PLUGIN_PATH environment variable contains directories in which
   plugin files (actually, ruby files) are.
 * these ruby files get loaded by oroGen at startup through the normal "require"
   mechanism
 * the code in the Ruby file should extend the task context's class
   (`OroGen::Spec::TaskContext`) to add new functionality. Examples can be found
   at the bottom of this page.

Example of a very simple plugin:

~~~ ruby
class BoolPlugin <  OroGen::Spec::TaskModelExtension
    attr_accessor :varname

    # implement extension for task
    def pre_generation_hook(task)
        task.add_base_member("simple_plugin", varname, "bool")
        task.operations["getBool"].
            base_body("return #{varname};")
    end
end

class OroGen::Spec::TaskContext
    def add_boolean_attribute(varname)
        extension_name = "BoolPlugin"
        # find previous instance of the extension
        extension = find_extension(extension_name)
        if !extension
            # create new instance
            boolp = BoolPlugin.new(extension_name)
            boolp.varname = varname
            # define interface for task
            hidden_operation("getBool").
                returns("bool")
            register_extension(boolp)
        else
            raise OroGen::ConfigError, "Plugin '#{extension_name}' is already instantiated with base member '#{extension.varname}'. '#{varname}' will not be created."
        end
    end
end
~~~

If this plugin is present, the `add_boolean_attribute` method becomes available on
task context definitions. Then, the generated Base class for these tasks will
include a boolean attribute with the name given as parameter. Below, it would be
"test".

~~~ ruby
task_context "Task" do
    add_boolean_attribute "test"
end
~~~

Edit `.orogen/tasks/TaskBase.hpp` to see the new attribute.

## Adding methods to task contexts

The add_base_method and add_user_method methods allow to add virtual methods to
(respectively) the user-visible part of a task context and the Base class of the
task context.

The syntax (simply replace add_base_method by add_user_method to have the same
behaviour on the user-part of the task class)

~~~ ruby
add_base_method(return_type, name, signature)
~~~

This method call declares a pure virtual method (no body has been specified
yet). To give a body, one has to call #body on the value returned by
add_base_method:

~~~ ruby
add_base_method(return_type, name, signature).
    body(body_of_the_method)
~~~

Where the body is the method's implementation without the toplevel block markers

For instance, oroGen adds a getModelName method to every task context. It is defined
by

~~~ ruby
add_base_method("std::string", "getModelName", "").
    body("return \"#{task_model.name}\";")
~~~

## Adding attributes to the base class

~~~ ruby
add_base_member("kind", "attribute_name", "attribute_type")
~~~

Additionally, related code can be added to the initializer list, constructor
and/or destructor:

~~~ ruby
add_base_member("kind", "attribute_name", "attribute_type").
    initializer("code_in_initializer_list").
    constructor("code_in_constructor").
    destructor("code_in_destructor")
~~~

`kind` is a simple string that is only used for sorting the declarations. For
instance the properties use "properties" as "kind" so that all properties get
grouped together.

## Adding code to the base class constructor and destructor

It is simply done with:

~~~ ruby
add_base_construction(kind, name, body)
add_base_destruction(kind, name, body)
~~~

+kind+ and +name+ will have no meaning. They will only be used for sorting the
code snippets, so that the generated code always stays the same (avoiding
unnecessary recompilations).

## Adding code the hooks in the base class

It is done with

~~~ ruby
in_base_hook(hook_name, code)
~~~

For instance, oroGen clears all input ports in the base `startHook` with

~~~ ruby
each_input_port do |port|
    in_base_hook('start', "_#{port.name}.clear();")
end
~~~

## Adding code at the toplevel

Code can be added at the toplevel of the Base.hpp and Base.cpp files. Simply do

~~~ ruby
add_base_header_code(code, include_before)
~~~

Where include_before should be true if the code needs to be added before the
Base class declaration and false if it should be after.

and

~~~ ruby
add_base_implementation_code(code, include_before)
~~~

## Code Generation Hooks

There are three different hook available which plugins could use.  The above
listed `pre_generation_hook` makes it able to add code to existing base-methods
or register new base methods for generation.

The `generation_hook` is the normal use-case for plugins. In this generation
step regular ports or methods can be created, but no new code can be added to
existing base-members.

The `post_generation_hook` is only intended to read the finally generated
task-context.  No modifications on the TaskContext or the generation should be
done at this step. This hook is useful to extract information during
compilation time.

## Adding user-defined classes to generation

Plugins that want to register additional classes during compilation
can register a subfolder within the CMake build system. These subfolders get 
added to the compilation unit. The plugin developer has to make sure that the folder
and a CMakeLists.txt within it has been generated during one of the above listed hooks.
If this classes should be installed or linked against other parts, regular CMake commands must
be used. The subfolders names must be export as a enumerable of string by the 
`each_auto_gen_source_directory` method of the plugin, example:

~~~ ruby
def each_auto_gen_source_directory(&block)
    ['src1','src2'].each(&block)
end
~~~

**Next** That's all, folks. Go back to [the list of topics](../index.html#how_to_read)
{: .next-page}
