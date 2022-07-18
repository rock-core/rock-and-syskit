---
layout: documentation
title: Storing Logs
sort_info: 20
---

# Storing Logs
{:.no_toc}

- TOC
{:toc}

Given the convention of putting all generated data [in a Syskit instance log
directory](runtime.html), all data that needs to be stored about a given Syskit
execution is present in a single folder. Saving that data means copying that folder.

This is the simplest method to save a successful mission's data: copy the whole
Syskit log folder to save it.

However, the `tools/syskit-log` package also offers a way to normalize data in a
_datastore_. In a datastore, the common data of a Syskit run (i.e. Syskit event
log, component properties and output ports) are converted in a normalized form,
creating a dataset. Datasets are immutable, given an immutable ID and can safely
be copied across machines.

All commands related to stores are under the `syskit ds` command. See `syskit help ds`
for a list.

Data export and [analysis](jupyter.html) functionality from syskit-log rely on
data being converted to a normalized dataset.

## Setting up a datastore

A syskit-log datastore is a simple local folder. Just create it. `syskit ds`
subcommands may be given a datastore explicitly with the `--store` option or,
preferrably, one sets a global datastore using the SYSKIT_LOG_STORE environment
variable.

## Importing a dataset

To import a dataset, copy the data from your system and process it using `syskit
ds import`. Using rsync, it would look like

~~~
rsync -r --compress REMOTE_URL:/path/to/logs/current .
syskit ds import current "Description of this dataset" \
    --tags a list of tags to refer to the dataset later
~~~

Within the store, datasets themselves are stored in the `core/` folder, under
their full ID. Each dataset has a `syskit-dataset.yml` file that contains the
identity information for that set (i.e. the hash of the files are used to create
the set ID) as well as the Syskit event log. A `pocolog` folder contains the
output log files, normalized to a single file per stream, named as
`TASK_NAME::PORT_NAME.0.log`.

All other files that were contained in the original folder(s) are stored either
in the `text/` folder (if they are text files) or in the `ignored/` folder.

## Processing multiple log folders

Each Syskit run creates a new dataset folder. During a day of operation, it is often
the case that multiple datasets have been created. Let's assume you have copied them
all in a single (originally empty) local folder with:

~~~
rsync -r --compress REMOTE_URL:/path/to/logs/ .
~~~

You may decide to import them all separately in a single run using the `--auto`
parameter. This will create one dataset per subfolder.

~~~
syskit ds import --auto .
~~~

Alternatively, all created datasets from the same Syskit app can be imported and
processed together using the `--merge` option to `import`. It will create a single
dataset that can be analyzed as a single one later.

~~~
syskit ds import --merge .
~~~

## Listing and querying datasets

The `syskit ds list` command will list all datasets currently present in the store,
listed by increasing date (oldest first). The command also accepts ways to restrict
the datasets using its QUERY parameter.

The query is a list of `keyOPvalue` arguments, where `key` is one of the metadata
keys (as shown by `list` without arguments) and `OP` is either `=` for strict
equality or `~` for matching (in which case `value` is interpreted as a regular
expression).

Metadata of note is `roby:time`, which is a timestamp of the form
`YYYYMMDD-HHMM`.  One can for instance show all datasets from August 2020 with
`syskit ds list roby:time~202010`

Once you narrowed down the list of datasets to show, the `--pocolog` argument
will display all the data streams available within the dataset.

Alternatively to `list`, `find-streams` allows to look for specific data streams.
For instance, to look for all `/base/Time` streams do

~~~
syskit ds find-streams type=/base/Time
~~~

The `--ds-filter` argument allows to filter datasets the same way than `list`
does, i.e. to see all `/base/samples/RigidBodyState` streams generated during
August 2020,

~~~
syskit ds find-streams type~/base/samples/RigidBodyState --ds-filter roby:time~202010
~~~

[Opaque types](../components/importing_types.html#opaques), and types that are
derived from them (e.g. structure that have opaques as fields), are stored under
the type name of the intermediate type and not the original type name. For
instance, `/base/samples/RigidBodyState` is actually stored as
`/base/samples/RigidBodyState_m` in the log files. If a call to `find-streams`
does not return any result, check a single dataset to find out whether you
are referring to the right type.
{: .important}

See `syskit ds help find-streams` for more details.