---
layout: documentation
title: Testing C++ Libraries using Logs
sort_info: 50
---

# Testing in C++ Using Logs
{:.no_toc}

- TOC
{:toc}

## General idea

- one creates "test logs", that is single log files containing multiple streams that
  represent a pre-ordered input for the library
- run these logs through the library code using test programs, that is a program
  that takes the log as input, feeds it to the library and verifies or visualizes
  the result.

## Creating test logs

using export_to_single_file in export scripts (https://github.com/rock-core/tools-syskit-log/pull/41). E.g.

``` ruby
require "syskit/log"
require "syskit/log/dsl"
extend Syskit::Log::DSL

dataset_select "SOME_DATASET_ID"

# Can use the same means of interval selection or sub-sampling than in Jupyter notebooks,
# e.g.
#  interval_select roby.Seabots.Compositions.task_from_id(20)
#  interval_sample_every seconds: 1

export_to_single_file \
    "sensor_fusion.0.log",
   pose_estimator_task.pose_samples_port,
   ais_task.vessel_position_port do |pose, ais|
   pose.add("pose") # copy the whole stream as a stream named 'pose'
   # You can transform the data to e.g. correct for faulty logs
   ais.add("ais_vessel_positions") { |s| s.mmsi = correct_mmsi(s.mssi) }
end
```

Then run with `ruby`

## Creating benchmarking / test programs in C++ libraries

The `tools/pocolog_cpp` package contains a class to streamline processing these
log files, `SequentialSampleReader`

This class adds a dependency on framework packages (`rtt` and `tools/rtt_typelib`).
Because of this, we recommend you make the benchmark/test programs dependent on
tests being enabled, to allow using the library in production by itself.

```xml
<test_depend package="tools/pocolog_cpp" />
```

To create the test program you have to
- import types from the typekits that export it on the orogen side with importTypesFrom
- declare the streams you are interested in, with `add(stream_name, callback)`
- run

The dispatcher object will call each callback in the order of the samples in the log
file, which means essentially in a time-ordered manner.

e.g.

``` cpp
using namespace pocolog_cpp;

int main(int argc, char** argv) {
    if (argc < 2) {
        std::cerr << "usage: " << argv[0] << " LOGFILE\n";
        return 1;
    }
    string logfile = argv[1];
    SequentialReadDispatcher dispatcher;

    /* NOTE: remember to add the corresponding orogen packages as test depend as well */
    dispatcher.importTypesFrom("base");
    dispatcher.importTypesFrom("ais_base");

    DataFusionLibrary fusion;
    dispatcher.add<base::samples::RigidBodyState>(
        /** name of the stream, same than during export. Use `pocolog <FILE>` to
         * list streams */
        "pose",
        [&fusion](auto const& value) { fusion.processPose(value); }
    );

    dispatcher.add<ais_base::VesselPosition>(
        "ais_vessel_positions",
        [&fusion](auto const& value) { fusion.processAISVesselPosition(value); }
    );

    dispatcher.run();
}
```