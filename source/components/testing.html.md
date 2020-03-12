---
layout: documentation
title: Testing
sort_info: 57
---

# Testing
{:.no_toc}

- TOC
{:toc}

Syskit has built-in support to allow creating unit test suites for Rock
components, including integration in the [CMake/Autoproj testing
workflows](../workspace/testing.html). Note that by following the [recommended
library/component split](../libraries/index.html), the component tests are meant
to be verifying the component's logic (error handling, input validation,
configuration), not the actual data processing that is meant to already have
been tested in the library's unit tests.

Tests are Ruby files in the orogen package's `test/` folder. Create the folder and add
the following to the toplevel `CMakeLists.txt`:

~~~ cmake
if (ROCK_TEST_ENABLED)
    enable_testing()
    find_package(Syskit REQUIRED)
    syskit_orogen_tests(test)
endif()
~~~

and `tools/syskit` as a [test
dependency](../workspace/testing.html#test_dependency) in the package's
`manifest.xml`:

~~~ xml
<test_depend name="tools/syskit" />
~~~

With these two changes, enabling the tests will add a `make test` target that
runs any file ending in `_test.rb` within the `test/` folder.

## Test file scaffold

The convention is to create one file per task model, converting the task's
CamelCase into a file's convention snake\_case, e.g. the common `Task` becomes
`task_test.rb`. `SlaveTask` would be `slave_task_test.rb`.

The test file template is:

~~~ ruby
# frozen_string_literal: true

using_task_library 'project_name'

describe OroGen.project_name.Task do
    run_live
end
~~~

## Deploying a component

The test harness provides discrete steps to change the component step:

- _deployment_ to add component to the system
- _start execution agents_ to start the underlying process but do nothing to the
  component itself
- _configure_ to configure the component
- _start_ to start the component

Each step can be combined. For instance, to get a running component, do

~~~ ruby
syskit_deploy_configure_and_start(
    OroGen.project_name.Task.deployed_as('task_name')
)
~~~

The other possibilities are `syskit_deploy`, `syskit_deploy_and_configure` and
the single `syskit_configure` and `syskit_start`.

Only steps that start with `syskit_deploy` requires a model specification. The
other require a task instance, as returned by `syskit_deploy`. For instance, the
deploy/configure/start cycle can be broken down as:

~~~ ruby
task = syskit_deploy(
    OroGen.project_name.Task.deployed_as('task_name')
)
syskit_configure(task)
syskit_start(task)
~~~

## Providing configuration parameters

To provide configuration parameters, set them between the deploy and configure
steps through the [`#properties` interface](runtime.html#extension_file) that is
also used in the component's `#configure` method.

~~~ ruby
task = syskit_deploy(
    OroGen.project_name.Task.deployed_as('task_name')
)
task.properties.can_id = 0x42
syskit_configure(task)
~~~

## Testing the component behavior

Due to a component's essentially asynchronous behavior, behavior tests need to
be broken down into two parts:

1. an action
2. an expected reaction

The pattern is 

~~~ ruby
expect_execution { ACTIONS }
    .to { EXPECTATIONS }
~~~

Multiple actions and multiple expectations can be provided, in which case they
are all executed and verified simultaneously.

The actions listed below **must** be executed within an `expect_execution`
block. If an action needs to be done without any associated expectation, use the
`execute` shortcut:

~~~ ruby
execute { ACTIONS }
~~~

Conversely, one sometimes want to verify some component behavior that is not
related to a particular action (e.g. a periodic output). This is done by
omitting the action block:

~~~ ruby
expect_execution.to { EXPECTATIONS }
~~~

### Actions

The most common action is to write a sample on a component's input port. This is
done with `syskit_write`. Assuming the task under test has an `in` port, for
example:

~~~ ruby
task = syskit_deploy_configure_and_start(
    OroGen.project_name.Task.deployed_as('task')
)
sample = Types.project_name.SomeDataType.new
sample.value = 20
expect_execution { syskit_write task.in_port, sample }
    .to { EXPECTATIONS }
~~~

The second type of action is to start or stop the component. This is done by
emitting the start and stop events with `start!` and `stop!`:

~~~ ruby
expect_execution { task.start! }
    .to { EXPECTATIONS }
expect_execution { task.stop! }
    .to { EXPECTATIONS }
~~~

### Expectations

The two most common expectations are

1. checking samples (or lack of) read from output port(s)
2. checking that the component transitions to different state(s).

(1) is done with either `have_one_new_sample` or `have_no_new_sample`

~~~ ruby
sample = expect_execution { ACTIONS }
    .to { have_one_new_sample task.out_port }
# Now check the value of sample
assert_equal 20, sample.value

# Checks that no samples arrives on the `out` port for at least 0.5s
expect_execution { ACTIONS }
    .to { have_no_new_sample task.out_port, at_least_during: 0.5 }
~~~

(2) is done by checking that the component emits the events corresponding
to the states. For instance, to check that the component transitions to an
exception due to an invalid input, one would write

~~~ ruby
expect_execution { syskit_write task.in_port, invalid_sample }
    .to { emit task.exception_event }
~~~

Multiple expectations can be verified at the same time. The test will finish
only when all of them are verified, or if any of them is known to be impossible.
For instance, one could check that the `out1` port has a sample, `out2` does
not and the component transition to the active state with

~~~ ruby
expect_execution { ACTIONS }
    .to do
        have_one_new_sample task.out1_port
        have_no_new_sample task.out2_port
        emit task.active_event
    end
~~~

The value returned by the whole expectation is the last value of the block. In
the previous case, you would need to forward the return value of
`have_one_new_sample` to get access to it after the call:

~~~ ruby
expect_execution { ACTIONS }
    .to do
        sample = have_one_new_sample task.out1_port
        have_no_new_sample task.out2_port
        emit task.active_event
        sample
    end
~~~

Or, since the expectations are tested _simultaneously_, just reorder them in the
block to make sure `have_one_new_sample` is last:

~~~ ruby
expect_execution { ACTIONS }
    .to do
        have_no_new_sample task.out2_port
        emit task.active_event
        have_one_new_sample task.out1_port
    end
~~~

The last value may be an array, for instance to return multiple samples:

~~~ ruby
expect_execution { ACTIONS }
    .to do
        emit task.active_event
        [have_one_new_sample(task.out1_port),
         have_one_new_sample(task.out2_port)]
    end
~~~

## Using test components

For some generic base component implementations, it can be beneficial to create
a specific "stub" subclass of the component, or a "pair" component that will
mock an expected "client". These test components should be defined in a `test`
namespace, which ensures that the component will only be tested if the tests are
enabled. In the orogen file:

~~~ ruby
task_context 'test::SlaveTask', subclasses: 'Task' do
end
~~~

In the test file:

~~~ ruby
task = syskit_deploy(OroGen.project_name.test.SlaveTask.deployed_as('test'))
~~~

**Note** that one would expect the test-specific component to be used in the
test file for the base class, e.g. `task_test.rb` in the case above.

## Running the tests

Tests are started from within the package's build dir. Go into that directory
with `acd -b path/to/package`

The complete test suite can be run with `ctest`. Use the `-V` option to get the
complete output:

~~~
# Go in the package's build directory
acd -b .
ctest -V
~~~

If you want to focus on a particular test, run the syskit orogen tests manually
with

~~~
acd -b .
syskit orogen-test test/task_test.rb --workdir bundle -- "-n=/FILTER/"
~~~

where FILTER is a regular expression that should match the name of the test(s)
you want to run.

If you need to run the task under valgrind, pass the corresponding option to the
`deployed_as` statement:

~~~ ruby
syskit_deploy(OroGen.project_name.Task.deployed_as('test', valgrind: true))
~~~

Alternatively, you can start the component process manually within your debugger
of choice (e.g. using [rock.vscode's oroGen
launcher](https://marketplace.visualstudio.com/items?itemName=rock-robotics.rock)
and tell the test to attach to it by replacing `deployed_as` with
`deployed_as_unmanaged`:

~~~ ruby
syskit_deploy(OroGen.project_name.Task.deployed_as_unmanaged('test'))
~~~

