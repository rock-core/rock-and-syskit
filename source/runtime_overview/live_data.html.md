---
layout: documentation
title: Live Data Visualization
sort_info: 40
---

# Live Data Visualization

When debugging a system's behavior, one has the obvious need to look at the
component's output, possibly through dedicated widgets that allow to understand
complex representations such as e.g. a quaternion.

We of course have the means to do so within a Syskit system. Generic live data
visualization is accessed within the Syskit IDE as shown on the video below. Rock
provides diverse widgets, some generic (e.g. plotting), some specialized for certain
data types (e.g. the `OrientationView` dedicated to quaternions).

<div class="fluid-video">
<iframe width="853" height="480" src="https://www.youtube.com/embed/IBeR6wbvBIg?rel=0&amp;showinfo=0" frameborder="0" allowfullscreen></iframe>
</div>

**Tip**: clicking on a job on the leftmost pane of the IDE restricts the list of
tasks on the right to the tasks that are needed by the job. Click on the top part
(the one showing a time) to show all components used by the system.
{: .callout .callout-info}

**Tip**: An opened visualization widget will rebind to the data stream it visualizes if
the corresponding component is restarted. Because of this, one usually does not
need to close and re-open widgets across Syskit restarts or across the start
and stop of jobs.
{: .callout .callout-info}

Let's finally get [to the part recap](recap.html){: .btn-next-page}
