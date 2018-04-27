---
layout: documentation
title: Publishing
sort_info: 55
---

# Publishing the Bundle
{:.no_toc}

- TOC
{:toc}

In order to publish our bundle, sharing it with e.g. our coworkers, we actually
have to do a few things:

1.  Create a `manifest.xml` with the following contents:

    ~~~xml
    <package>
        <description brief="Syskit Tutorial Bundle from 'Rock and Syskit'">
        </description>

        <depend package="bundles/common_models" />
        <depend package="simulation/rock_gazebo" />
        <depend package="control/orogen/cart_ctrl_wdls" />
        <depend package="control/orogen/robot_frames" />
    </package>
    ~~~

2.  You will obviously need to put the code somewhere. Let's assume it will
    end up on GitHub. The repository naming convention is to separate the folder
    names with dashes, so in this case, the repo would be named
    `bundles-syskit_basics`. Let's use the `rock-core` organization as an
    example.

    Turn first the `bundles/syskit_basics` folder into a `git` repository, and
    add the files we have created with:

    ~~~
    git init
    git add .
    git commit -m "Initial commit - Finished the Basics tutorial"
    ~~~

    Then create the repository and push to it (replacing the URL with your repository
    URL):

    ~~~
    git push git@github.com:rock-core/bundles-syskit_basics master
    ~~~

3.  Create your own Autoproj project, on top of which you will be able to
    expand your developments. This is described in [the Starting A New Project
    section](../workspace/setup.html) in the _Workspace and Packages_ chapter. Read this
    chapter, and apply it here.
    
    Make sure you added the newly created package set to both the
    `package_sets` and the `layout`, as the "Starting a new project' section
    instructed you to.

4.  Finally, add the bundle to your newly create package set. Edit the
    `packages.autobuild` file and add

    ~~~ruby
    bundle_package "bundles/syskit_basics"
    ~~~

    And add a corresponding entry in the package set's `source.yml`, which would
    look like

    ~~~yaml
    - bundles/syskit_basics:
      github: rock-core/bundles-syskit_basics
    ~~~

    Check that things resolve properly with `autoproj show syskit_basics` and do a
    `aup -n syskit_basics` to verify that the repository is properly setup.

5.  Because the bundle is part of the package set, and because the bundle depends on
    the `control/orogen/cart_ctrl_wdls` and `control/orogen/robot_frames` packages,
    they should not be listed anymore within the workspace manifest. Removes them
    from `autoproj/manifest`.

    The general best practice is to basically ensure that your projects packages depend
    on what they need, and then either depend on the whole package set (common on
    developer machines), or on specific packages. The latter is usually the bundle,
    which happens on the robot machines themselves.

5.  Publish the changes from your package set and main build configuration.
  
Let's finally go to the [section's recap](recap.html)