---
layout: documentation
title: Introduction
sort_info: 0
directory_title: Deprecated Behaviors
directory_sort_info: 110
---

# Deprecated Behaviors

Rock and Syskit try very hard to keep backward compatibility when it makes
sense.  Moreover, when backward compatibility should really be broken - either
because of a bug that must be fixed, or because new ways to do things are
clearly better - we try very hard to _keep_ the old behavior by default, and
either permit the usage of the new behavior in parallel, or use a configuration
flag to allow switching between the two.

This section lists these deprecated behaviors. Each page lists

- the old behavior
- the new behavior
- migration path
- how to control both old and new behavior availability