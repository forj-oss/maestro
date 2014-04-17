Directories structure:
======================

bootstrap     : Contains Box init code after server bootstraped.
build/bin     : Contains scripts to build Maestro or node images or any distribution packages.
build/maestro : Contains bootstrap to build a basic maestro image
build/maestro : Contains bootstrap to build a basic maestro image
build/node    : Contains bootstrap to build a basic node image.
puppet-libs   : Contains puppet modules to build maestro or node images.
api           : Internal Maestro api
ui            : Maestro ui

How Maestro is created:
=======================

If you are building a Maestro image for your cloud, do the following:

This tool is based on hpcloud cli. You have to install it before. See http://docs.hpcloud.com/cli/unix

* Configuring cloud credential

* Starting your build
    $ cd build
    $ bin/build.sh --box-name maestro --build-conf-dir conf

it will create a Maestro box image, by building a server and snapshooting it.

maestro requires a proto2b image to be built before.

To build proto2b image, use the following:

    $ bin/build.sh --box-name proto2b

For more details, read build/README.md

FORJ Team
