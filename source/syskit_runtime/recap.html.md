---
layout: documentation
title: Recap
sort_info: 100
---

# Runtime Overview: Recap

- Syskit maintains the set of _jobs_ or _missions_, that is the set of goals
  that the system has the intent to reach. They can represent a function that
  should run, or -- as we will see later -- a goal to achieve.
- Components are related to each other by [the task
  structure](task_structure.html).
- Components are configured and started "when possible" by [the
  scheduler](event_loop.html#scheduling)
- Components are transparently [reconfigured](event_loop.html#reconfiguration)
  when needed.
- Components that are not useful to the goals are automatically stopped by
  [Syskit's garbage collection mechanism](event_loop.html#garbage_collection)
- The task structure also defines constraints between the components. Failure to
  meet these constraints is what Syskit interprets as [errors](errors.html)

Between this part and the [Basics](../syskit_basics), we've covered most of the basics
aspects of running a Syskit system. The rest of the subjects covered in this documentation
can be seen more as a need-to-know basis. See [how to read this documentation](../index.html#how_to_read).

