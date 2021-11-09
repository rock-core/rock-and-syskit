---
layout: documentation
title: Introduction
sort_info: 0
directory_title: Log Management
directory_sort_info: 57
---

# Log Management

This chapter will give you an understanding of how and where logs are generated at runtime,
and what you can do with them. Data logging is a very important aspect of robotic system
development, and Rock does have your back on the subject.

In particular, we will go through the following subjects:

* [Log generation at runtime](runtime.html) "where and what are the logs"
* [Storing logs](datastore.html) how you store and manage system logs
* [Interactive log analysis using Jupyter](jupyter.html) how you can process logs using
  Ruby within a Jupyter notebook.

This last point is, in the end, the gateway for further processing in more common
languages for data oriented tasks (e.g. Python, R, ...). The basic tools presented
in this last section make it easy to extract relevant data from the generated datasets
and export it for further processing. Said processing can be automated (does not have
to be part of a Jupyter notebook).

Within a Rock system based on Syskit, the log management functionality is implemented
by the `syskit-log` package. It is defined by the rock.core package set, but is not
included by default within the `rock.core` metapackage.

To add it to your workspace, add `tools/syskit-log` to your manifest, or in one of your
system's metapackages, e.g.

~~~ yaml
manifest:
- ...
- tools/syskit-log
~~~

Additionally, if you intend to use Jupyter for interactive log plotting and analysis,
add the `rock.jupyter` package set in your manifest, under the `package_sets` section.
This will configure the jupyter location and add `rock.jupyter.osdeps` to your manifest:

~~~ yaml
package_sets:
   - ...
   - github: rock-core/rock.jupyter-package_set
   - ...

manifest:
   - ...
   - tools/syskit-log
   - rock.jupyter.osdeps
~~~
