This directory contains scripts to build a predefined box, and create images.
We can use it to create a box and run it for testing/hacking.

There is 2 different images:

> - maestro : Describe how to create maestro image
> - node    : Describe how to create node image. A node image is used to create kits boxes.
> - proto2b : Based for any images.

how we create a predefined box?
===============================

Several spaces are used to build a box:

> * bin/build.sh<br>
>   This is the main script tool. You have to be here to build a box, as it requires to have access to the box subdirectory like maestro, proto2b or node.
> * conf/*.env<BR>
>   This directory contains a collection of build configuration used to build your box.
> * bin/build/built-tools/boothook.sh<br>
>   This is a the first common cloud-init script
> * <BoxName>/cloudconfig.yaml<br>
>   This is the first specific box init definition sent to cloud-init.
> * <BoxName>/bootstrap<br>
>   Collection of files to build the last cloud-init boot step.

build.sh will first build the cloud-init based on: 

> * boothook.sh (build/bin/build-tools/boothook.sh)<br>
>   Used to mainly set hostname, debug mode, log redirection, proxy management, extra updates.
> * cloudconfig.yaml (build/{BoxName}/cloudconfig.yaml<br>
>   Used to keep hostname set by boothook, and extra packages updates.
> * boot-maestro.sh (build/{BoxName}/bootstrap/*.sh)<br>
  Used to git clone repos, and start your defined bootstrap

Start building a box
====================

build.sh requires hpcloud cli command to be installed on your box. look at http://docs.hpcloud.com/cli/unix

then start it:

    bin/build.sh --box-name <BoxName> --build-conf-dir conf

If you want your box to send some meta data, use --meta

    bin/build.sh --box-name maestro --build-conf-dir conf --meta "cdksite=maestro.test"

Create your own build configuration:
====================================

First of all, why do you need that?
Because:

* You want to influence the cloud-init boot
* You want to introduce some box init steps defined in your repository. This will be done after cloud-init sequence.
* You want to ensure to use some specific cloud configuration, like tenantID depending on branch you are building your box. 
* ...

Updating cloud or default meta data
-----------------------------------

If you want to create your own box based on one of our default image, you can copy the desired conf/*.env.
As an example, let's say you copy maestro.master.env to **~/src/MyRepo/maestro**.

You can ensure any of cloud specification to be forcelly used by your configuration.
You will need to define the name of HPCloud account setup with **FORJ_HPC**.

Look in the copied env file to update it as needed.

You can ensure or set as default some meta-data.

Ex: Set default 'cdksite' metadata

    if [ "${META[cdksite]}" = "" ]
    then # Default
       META[cdksite]="cdksite=${APP_NAME}.tmpl"
    fi

Ex: Forcelly use 'cdksite' (--meta "cdksite=..." will have no effect)

    META[cdksite]="cdksite=${APP_NAME}.tmpl"

Then start your build.sh as follow:

    bin/build.sh --build-conf-dir ~/src/MyRepo/maestro --box-name maestro

Introducing some cloud-init boot step:
--------------------------------------

build.sh by default uses **< BoxName >/bootstrap** to create the 3 cloud-init sequence, named boot-maestro.sh

You can configure your build configuration file to add additionnal steps to cloud-init. To do it, set your **BOOTSTRAP_DIR** to an absolute path to use.

    BOOTSTRAP_DIR="$HOME/src/MyRepo/maestro/bootstrap"

You can add reference to where your configuration is to set this **BOOTSTRAP_DIR**.

    BOOTSTRAP_DIR=$(cd $CONFIG_PATH/bootstrap ; pwd)

CONFIG_PATH is set to $HOME/src/MyRepo/maestro because you set `--build-conf-dir ~/src/MyRepo/maestro` to your build.sh call.

The way boot-maestro.sh is concatenated is base on files name sorted.

Ex: Maestro have those files:

> - 10-step1.sh
> - 20-step2.sh
> - 99-laststep.sh

If you want to add a step 3 before laststep, create a file **30-step3.sh** in your **~/src/MyRepo/maestro/bootstrap** directory.

Then boot-maestro.sh will be composed by *10-step1.sh*, *20-step2.sh*,  *30-step3.sh* and *99-laststep.sh* in this order.

You can verify your cloud-init file, with bin/bootstrap_build.sh to check your sequence.

    $ bin/bootstrap-build.sh --build-conf-dir ~/src/MyRepo/maestro --box-name maestro 
    INFO! /home/ME/src/MyRepo/maestro//maestro.master.env loaded.
    INFO! Preparing cloudinit mime.
    Read boot script: 
    Included : bootstrap/00-functions.sh
    Included : bootstrap/01-maestro-bootstrap.sh
    Included : bootstrap/10-openstack-config.sh
    Included : /home/ME/src/MyRepo/maestro/bootstrap/maestro/30-step3.sh
    Included : bootstrap/99-maestro-start-boot.sh

    INFO! /home/ME/src/MyRepo/maestro/./boot_maestro.sh added to the mime.
    /home/ME/.build/./boothook.sh:text/cloud-boothook cloudconfig.yaml /home/ME/.build/./boot_maestro.sh  > /home/ME/.build/./userdata.mime

Then, you can review: 

> * the mime file : `/home/ME/.build/./userdata.mime`
> * your boot-maestro.sh : `/home/ME/.build/./boot_maestro.sh`

If you have added some meta data, you can see then in the generated boothook:

    /home/ME/.build/./boothook.sh

== Running Maestro bootstrap ==

As soon as your box is starting the bootsequence, ie boot then cloud-init, maestro boot init sequence can be executed.

This is described in the `bootstrap/README.md file`

FORJ Team