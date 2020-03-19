---
layout: documentation
title: Test Integration
sort_info: 49
---

# Test Integration
{:.no_toc}


- TOC
{:toc}

Autoproj provides support to run all package's unit tests, including gathering
the unti test results at standard places, for further processing.

In this section, we will start by describing how to run a package's test suite
with Autoproj. Then, we'll talk about how to integrate your package's test suite
so that Autoproj can run it.

## Running a package's tests

Autoproj provides a way to identify which dependencies are needed exclusively
for the benefit of a package's tests. In order to run the tests, you must first
tell autoproj you needed these dependencies (and install/build them). This is
done by _enabling_ the tests for the package you're interested in:

~~~
cd path/to/my/package
autoproj test enable
aup --checkout-only
amake
~~~

Note that once a package's tests are enabled, following updates/build will also
update/build its test dependencies - i.e. you need to run the commands above
only once.

If you want to enable all tests suites of a workspace, run

~~~
autoproj test enable
~~~

And then a full update/build cycle.

Finally, to run the tests, do `autoproj test .` if within the package. Use the
`--tool` option to see the package's output right away, or use `alog` to see the
test log file afterwards.

Run `autoproj test list .` to know if a package has a test suite that can be
executed under Autoproj. If not, you can integrate it (see below)

## The Rock CMake macros

The Rock CMake macros provide all that's needed to run tests with CMake's CTest,
and generate JUnit files where Autoproj expects them. The `rock.core` package
set automatically configures the necessary CMake variables for the integration
with Autoproj.

In other words, if you're using the Rock CMake macros and the `rock.core`
package set, you're covered.

## Generic CMake support

The `cmake_package` definition looks for a `test/` folder in the package, and
declares that tests are available in this package if one is found. Tests are
executed with `make test` within the package's build directory. Test results are
expected to be generated in the `test/results/` subdirectory of the build
directory.

Use `#source_dir` if test results are generated in another subdirectory.
Relative paths are resolved with respect to the package's source directory.
We recommend always setting a full path.

If the package does not generate test results, set the `#no_results` attribute
to false:

~~~ ruby
cmake_package 'my/pkg' do |pkg|
    pkg.post_import do
        # Enable tests at the CMake level when they are enabled at the Autoproj
        # level
        pkg.define 'SOME_FLAG', pkg.test_utility.enabled?
        pkg.test_utility.source_dir =
            File.join(pkg.builddir, 'test', 'results')
        ## If the tests don't generate anything
        # pkg.test_utility.no_results
    end
end
~~~

## Ruby packages

The `ruby_package` handler looks for a `test/` folder in the package, and
declares that tests are available if it finds one. Tests are executed with `rake
test`. Results are expected in the `.test_results` subdirectory of the sources.

In addition, the `rock.core` package set installs the `minitest-junit` minitest
plugin, and ensures that JUnit reports are created where Autoproj expects them.

## Manual integration of a package's test suite

Autoproj provides three functionalities regarding test suites:

- providing the CLI interface needed to control whether tests should be enabled
  and executed
- running them
- optionally copying the test results in a common directory tree (the
  `test_results/<package_name>` folder under the log directory)

If your package(s) don't neatly fall within the standard Autoprojg package
handling, here's how you can integrate it.

First, you need to declare that tests are available. Tests are available if

1. a test _task_ is defined, that is Autoproj knows how to run the tests
2. a test result dir is set, or the `#no_results` flag is set to declare that
   none should be expected

A test task is defined by passing a block to `test_utility.task`, e.g.

~~~ ruby
import_package 'some/package' do |pkg|
    pkg.test_utility.task do
        # Code to run the tasks
    end
    pkg.test_utility.no_results
end
~~~

**Note** that if you need to test for the presence of folder/files on disk, you
**must** do it in a `post_import` block. Otherwise, your code will be executed
_before_ the package is imported and the test will fail. See for example
[autoproj's definition of tests for the base package types](
https://github.com/rock-core/autoproj/blob/372dd3252ca91d0f5ba1b0854619d37e1aa5d881/lib/autoproj/autobuild_extensions/dsl.rb#L228
)
{: .important}


Check whether Autoproj believes tests are available by running `autoproj test
list <PACKAGE_NAME>`.

The next step is to ensure that tests are available if they are enabled. The
goal here is to avoid unnecessary work when tests are not needed.

The first step is to add test-only dependencies using the `test_depend` tag in
the package's `manifest.xml`. This ensures that these dependencies will be
ignored if the tests are not enabled:

~~~ xml
<test_depend name="some/package" />
~~~

The second step is to control whether tests are built (when applicable) within
the autobuild files. For instance, `rock.core` controls whether
`ROCK_TEST_ENABLED` is set with

~~~ ruby
cmake_package 'some/package' do |pkg|
    pkg.post_import do
        pkg.define 'ROCK_TEST_ENABLED', pkg.test_utility.enabled?
    end
end
~~~

`#enabled?` will return false if the tests are not _available_ through the
settin of `#source_dir` or `#no_results`. This means that you need to check for
`#enabled?` in a `post_import` block if the test setup is done in a
`post_import` block as well
{: .important}

**Do not** conditionally set the variable that controls the test like so:
`pkg.define 'ROCK_TEST_ENABLED', true if pkg.test_utility.enabled?` as it would
enable the tests, but never disable them. Use instead the pattern seen above,
that is `pkg.define 'ROCK_TEST_ENABLED', pkg.test_utility.enabled?`
{: .important}

