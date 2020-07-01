---
layout: documentation
title: Component Networks
sort_info: 80
---

# Component Networks
{:.no_toc}

- TOC
{:toc}

**STUB**


## Mapping of Rock component states to events

The tasks that represent the Syskit components have a 1:1 mapping between task
state transitions and events. The default transitions are rather straightforward:

- `STOPPED` -> `RUNNING`: `start` event
- `RUNNING` -> `STOPPED`: `success` event (which also emits `stop`)
- `RUNNING` -> `EXCEPTION`: `exception` event (which also emits `failed` and `stop`)

`configure` is handled

