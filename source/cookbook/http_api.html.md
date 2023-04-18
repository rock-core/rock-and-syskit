---
layout: documentation
title: Control and Monitoring through a HTTP API
sort_info: 20
---

# HTTP API of a Syskit-based System
{:.no_toc}

- TOC
{:toc}

One way to create an external interface with a Syskit-based system is through a
HTTP API. This is **not** a HTTP API that is generic and allow to automatically
access Syskit and rock primitives such as ports or actions. The objective is to
create a well-defined, system-specific interface that common UI development
tools can easily hit (e.g. web frontend).

The rest of this page will describe the overall structure and the various
techniques related to this objective.

## Overall Structure

The central idea is to provide a HTTP server inside the Syskit process, which naturally
has access to the Syskit APIs to control and monitor the system. To make it practical,
however, we have to split the implementation of this HTTP API in different bits and
pieces.

For the HTTP API itself, we will use [Grape](https://github.com/ruby-grape/grape),
which provides a declarative way to create a HTTP API. Roby provides an integration
with the thin web server, which allows to serve

Usually, the main Grape class will be created in `lib/syskit_basics/rest/api.rb`. Roby task
that manages the HTTP server is called `Tasks::REST` and the corresponding action
`http_api`. Assuming we are within the `SyskitBasics` application of [the
tutorials](../basics/), let's implement those now.

Create `lib/syskit_basics/rest/api.rb` and fill it with

~~~ ruby
# frozen_string_literal: true

require "roby/interface/rest/api"
require "roby/interface/rest/helpers"

module SyskitBasics
    module REST
        class API < Grape::API
            format :json

            mount Roby::Interface::REST::API
            helpers Roby::Interface::REST::Helpers
        end
    end
end
~~~

Now, create the rest task with `syskit gen task http_api` and modify it to fit:

~~~ ruby
# frozen_string_literal: true

require "syskit_basics/rest/api"

module SyskitBasics
    module Tasks
        class HTTP_API < Roby::Interface::REST::Task
            terminates

            def rest_api
                SyskitBasics::REST::API
            end
        end
    end
end
~~~

And finally create the action interface with `syskit gen act http_api`, and
define the action within:

~~~ ruby
describe("start the HTTP API")
    .required_arg("port", "the port on which the HTTP API should listen")
def http_api(port:)
    SyskitBasics::Tasks::HTTP_API.new(main_route: "/", port: port)
end
~~~

You can then add the interface to the `actions` block and
`Robot.http_api!(port: 5_000)` in the controller block within
`config/robots/gazebo.rb`. You can check the API is alive using some browser
extension Rested to call the `/ping` endpoint (which is part of
[Roby::Interface::REST::API](https://github.com/rock-core/tools-roby/tree/master/lib/roby/interface/rest/api.rb))

## Implementing the endpoints in the Grape class

There are a few rules regarding the interaction with the Syskit system from the
Grape class. For starters, the two run in different threads so any access with
Syskit data structures must be synchronized. Second of all, Grape does not provide
a way to store data between different calls of the endpoints (i.e. there is no
way built-in grape to have one call to one endpoint save a value so that )

### Synchronization between Syskit and Grape

The [roby REST helpers](https://github.com/rock-core/tools-roby/tree/master/lib/roby/interface/rest/helpers.rb)
provide accessors to the internal Syskit data structures. This access **must** always
be synchronized by calling them inside a `roby_execute` block:

~~~ ruby
get "/some/stuff" do
    roby_execute do
        # Interact with Syskit
    end
end
~~~

Moreover, any data that is taken out of Syskit must be copied before getting
out of the `roby_execute` block.

`roby_execute` actually blocks Syskit. You must not do anything that blocks for
a long time in there, or your system will become unresponsive.
{: .important}

### Storing data in the Grape endpoints

Grape does not provide a way to store data between different calls of the
endpoints (i.e. there is no way built-in grape to have one call to one endpoint
save a value so that another call to an endpoint - the same or different - picks
it up).

The helpers provide `roby_storage`. This is a hash whose value will be kept
across calls. You may use it to store information / data / configuration parameters
and have it available across all endpoints. `roby_storage` may be initialized
within the initial Roby task (`SyskitBasics::Tasks::HTTP_API` in our example
application):

~~~ ruby
module SyskitBasics
    module Tasks
        class HTTP_API < Roby::Interface::REST::Task
            terminates

            # ID to be made available to the caller
            argument :system_id

            def rest_server_args
                super.merge(
                    storage: {
                        system_id: system_id
                    }
                )
            end

            def rest_api
                SyskitBasics::REST::API
            end
        end
    end
end
~~~

Since we are using `thin`, the different endpoints never run in
parallel and there is no need to synchronize the access to `roby_storage`
{: .note}

Be careful with `roby_storage`. Never store information in it that is already
available within the Syskit plan, or you will more surely end up having a
disconnection between the data you return to your clients and the actual state
of the system. Use it for configuration parameters, or for data that is directly
relevant to the API itself without being available within the Syskit system.
{: .important}

# Common Operations

## Reading data streams

The fact that Grape objects are short-lived - essentially living the time of a
single HTTP call - reading and managing state within them is tricky. Managing
the data readers themselves would already be a challenge. For this reason, we
usually delegate the aggregation of data relevant to the HTTP API into one or
more compositions, e.g. a `HTTPStateMonitoring` composition.

### Data readers with port queries

However, we do not use the standard composition-child relationship to refer to
the data sources. Indeed, using this strong relationship would make Syskit
terminate the state monitoring composition every time a single data source fails,
something that is obviously not desired.

Instead, we use a different mode of the [data readers and
writers](../coordination/tasks_and_events.html). Instead of providing
composition children, these writers may be given plan queries. That is, objects
that are used to find ports within Syskit's plan, and provide readers on them
*when they are available*, letting the composition know when they are not
available.

In practice, the most common query is to provide a data service and its port. This
query will match with any task that provides the data service, and will bind to its port.

If there is more than one match, it will pick the first one.
{: .important}

For instance,

~~~ ruby
data_reader CommonModels::Services::Pose.match.pose_samples_port, as: "pose"
~~~

will create a reader on the `pose_samples` port of any pose provider in the
system. One usually wants to refine the query. Two very common predicates are
`with_arguments` to match arguments, and `mission` to check if the task is marked
as mission (has been started as a toplevel action, see below the [Managing missions](#missions) section).
For instance:

~~~ ruby
data_reader CommonModels::Services::Pose
            .match.mission
            .with_arguments(source: "gps").pose_samples_port,
            as: "pose"
~~~

See [Roby::Queries::Query](https://github.com/rock-core/tools-roby/blob/master/lib/roby/queries/query.rb)
API for a full list of predicates.

To disambiguate sources, when more than one provide the service you use to identify them,
you may:

1. create a "source selection" composition whose sole purpose is to "mark" the data
   source. This composition would export the relevant port(s), and you would use the
   composition model in the data reader match object.
2. create a new service for this purpose and make sure the task/composition you
   are targetting provide it.
3. directly use the task model of the task that implement the source (**not recommended**)

### Example state monitoring composition implementation

Assuming we only want to read the pose source we defined above (the simplest version),
the

~~~ ruby
module SyskitBasics
    module Compositions
        class HTTPStateMonitoring < Syskit::Composition
            data_reader CommonModels::Services::Pose
                        .match.pose_samples_port, as: "pose"

            # @return [Hash] the state to be returned from the HTTP endpoint
            #   as a hash
            attr_reader :json

            def initialize(**)
                super

                # Data formatted to be ready to send to our caller
                @json = {}
            end

            poll do
                # VERY important. This will update the readers
                super()

                if (p = pose_reader.read_new)
                    # Update @json
                    @json["position"] = { x: p.position.x, y: p.position.y }
                elsif !pose_reader.connected?
                    # No pose provider available
                end
            end
        end
    end
end
~~~

### Accessing the state monitoring composition from a Grape endpoint

Within the endpoint, you have to do two things: find the `HTTPStateMonitoring` task
and then return the JSON document

While the second part is rather trivial, the first part requires using plan
queries, akin to the port queries we have just seen to define the readers.
`Plan#find_tasks` will allow us to find a running state monitoring task using a
query and then we can access its `json` data.

~~~ ruby
get "/state" do
    roby_execute do
        monitoring_task =
            roby_plan.find_tasks(Compositions::HTTPStateMonitoring).running.first
        monitoring_task&.json || {}
    end
end
~~~

### Final word

Once more, the objective of this HTTP API is to provide a well-defined interface
to a complex system, **not** a generic "read whatever you want" type of debug
interface. Use the Syskit IDE and other Rock tools (e.g. vizkit) for the latter.

## Controlling the System

What we have just seen is how to read data streams. Now, we will most definitely
want to also control the system through the same means (e.g. PUT or POST endpoints).
This section will outline how that is done.

First, within a Syskit system, a list of tasks are specially markes as
"missions". Syskit considers these tasks to represent the objective of the
system, and uses it as its basis to decide what to run. I recommend you
(re-)read [this part of the documentation](../runtime_overview/task_structure.html)
if this concept is not familiar to you

### Modifying what runs

Essentially "controlling the system" at the level of the HTTP API works with adding
and removing missions. This is what we are going to learn about right now.

Let's assume, to simplify, that the system only has one "user-provided" mission at
any given time. He would have auxiliary services, which also run as missions from
Syskit's perspective, but only one of these is *the* mission set externally by
the HTTP API. Let's create a task service to mark these missions and make them
discoverable:

~~~ ruby
# frozen_string_literal: true
# Created by syskit gen task-srv mission

module SyskitBasics
    module Services
        task_service "Mission"
    end
end
~~~

From now on, the toplevel task of the missions that you want to be able to
manipulate from the HTTP API will have to have `provides Services::Mission` in its
declaration. These must be toplevel tasks - that is, they are used to represent
the action itself, and are the return type of the action. In the case of profile
definitions, this is the type of the definition. In the case of other actions
(e.g. [action methods](../coordination/action_methods.html) or [action state
machines](../coordination/action_state_machines.html) it has to be declared as
the return type with

~~~ ruby
describe("the action documentation")
    .returns(MyReturnType)
~~~

From this point on, the endpoint that will change the mission has two jobs:
finding the current mission, ensuring it is available for [garbage
collection](../runtime_overview/task_structure.html) and then spawn the new
mission.

~~~ ruby
# find the current mission
roby_execute do
    # Find the single task that provides the mission service, and that is also
    # marked as mission
    mission_task = roby_plan.find_tasks(SyskitBasics::Services::Mission).mission.first
    # Make sure it is available for garbage collection
    roby_plan.make_useless(mission_task) if mission_task
    # And create the new mission
    Robot.send("#{new_mission_name}!", **new_mission_args)
end
~~~

The core concepts here are:
- the `mission` flag
- the `find_tasks` API. Note that if more than one action of a given type are meant
  to be running, you can filter with arguments or other services to disambiguate.

The corresponding GET endpoint, which would allow to inspect what mission is running
would use the `find_tasks` to get the task and then return the value:

~~~ ruby
roby_execute do
    mission_task = roby_plan.find_tasks(SyskitBasics::Services::Mission).mission.first
    return {} unless mission_task

    {
        id: mission_task.mission_id,
        # fill the hash according to your API
    }
end
~~~

### Dynamically changing configuration

The technique above may be used to change the configuration of some running services.
If *everywhere* in the system you rely on default arguments for a action or definition,
then starting the same action/definition "on the side" with specific arguments will
take precedence, that is, in the robot controller:

~~~ ruby
# We assume that some_action! uses for instance a gps_dev! with default arguments only
Robot.some_action!
# Start gps_dev! with specific arguments. The gps_dev of some_action will pick them up
Robot.gps_dev! origin: [22, -3]
~~~

However, this becomes tedious quickly, especially if some parameter value need to be
propagated across different subnets. The alternative technique is to use Syskit's global
`Conf` object, passing argument values with the `from_conf` helper.

In the example above, in our system-specific profiles, we would inject
`gps_dev` in `some_action` with `with_arguments(origin: Roby.from_conf.global_localization_origin)`.
This makes Syskit pick up the actual value at deployment time (and every time
there is a deployment). We will be able to change the value and trigger a deployment to
propagate it.

First, in the `Robot.init` block we initialize the value

~~~ ruby
Conf.global_localization_origin = [0, 2]
~~~

Finally, in an endpoint we can do

~~~ ruby
roby_execute do
    Conf.global_localization_origin = options[:origin]
    Syskit::Runtime.apply_requirement_modifications(roby_plan, force: true)
end
~~~
