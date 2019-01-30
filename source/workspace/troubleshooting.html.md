---
layout: documentation
title: Troubleshooting
sort_info: 60
---

# Troubleshooting
{:.no_toc}

- TOC
{:toc}

Common issues and how to troubleshoot them

## Deleted the install/ folder, now I can't rebuild !

Fix: open a new terminal **without loading the env.sh script**, `cd`
into the root of the workspace and run

~~~
.autoproj/bin/autoproj osdeps
~~~

Explanation: the `install/` folder contains all the non-OS dependencies (e.g.
RubyGems, pip, …). You need to reinstall them before you can successfully
rebuild

## A package is always rebuilt, regardless of whether it is needed or not

Autoproj determines whether a package needs to be rebuilt by looking at the
newest file in the package's source tree. It has a built-in ignore set of
patterns to avoid rebuilding for e.g. changes in Git configuration, but
sometimes packages modify files in their source tree for which Autoproj does
not have an exclude.

You can troubleshoot this by building the offending package with `--debug`:

~~~
amake planning/omplapp --debug
~~~

In the generated output, look for a line that looks like:

~~~
getting tree timestamp for /home/doudou/dev/squidbot/planning/omplapp
~~~

and then the nearest line afterwards that looks like:

~~~
newest file: /home/doudou/dev/squidbot/planning/omplapp/src/omplapp/config.h at 2019-01-30 15:48:15 -0200
~~~

That's the offending file. It's now up to you to decide whether the best is
changing the package's build system to avoid doing this, or to add an exception
in the package's autobuild definition with

~~~
cmake_package 'planning/omplapp' do |pkg|
    pkg.source_tree_excludes << File.join(pkg.srcdir, 'src', 'omplapp', 'config.h')
end
~~~
