---
layout: documentation
---

# A Brief Introduction

## Basic Concepts

**Design and runtime** Rock is a model-based architecture. A Rock system is
described **at design time**, that is before any piece of the actual
processing code needs to be run, and can verify properties regarding the
final system then. **Runtime** then refers to the point where the actual data
processing code runs -- which involves hardware or simulation in case of
robotics.

**Libraries, Components and System** Deep-down, the bulk of the code that
makes a Rock system is organized in libraries. Libraries propose APIs -
interfaces - to solve particular problems, e.g. OpenCV to process images, PCL
to process point clouds, a GPS driver to control a GPS device and read GPS
positions, … This way to organize software development is nothing specific to
Rock or even robotics. It's the principal way software is developed _period_.

However, libraries _offer_ functionality, but do not specify how this
functionality should be integrated to offer a "runtime", i.e. how the actual
data being processed can be passed to the processing code in the libraries,
from the sensors to the actuators, to turn all that code into a robot.

The paradigm that Rock follows is the one of **components**. Components are
black boxes that have inputs and produce outputs. It's by meshing these
components together - connecting outputs to inputs - that an active
sensor-processing-actuator loop is created and that the robot can act and react
in its environment. In addition to this _dataflow interface_ (data inputs and
outputs), Rock components also offer a _configuration_ interface where parameters
can be chosen and tested. In Rock, these components are implemented in **oroGen
packages**. They are described in an orogen file, which code-generates the
skeleton of the components. oroGen packages also define the datatypes that
can be transferred between the components.

What sets Rock apart from other component-based systems is the ability to
reconfigure the component network to fit the situation as best as possible.
This is made possible by explicitly choosing at any point in time both which
components are active, and which output-input connections are present in the
network. **Syskit** is the tool that makes such a design feasible, pushing most
of the complexity of such a dynamic system into the tool, leaving the developer
make higher-level design decisions.

**Software Packages** A software package is a way to distribute code (software).
Rock's only convention is to have a one library = one package correspondence or
one component = one package. Libraries should be "fat", components "slim" (i.e.
most of the functionality should be implemented as a component-independent
library.

That's all for now … [let's get started with our Syskit/Gazebo system](getting_started.html){:.btn .btn-primary}
