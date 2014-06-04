In this directory you will find some extra feature that you can add in your box at user_data boot time.

98-test-box.sh
==============
To remind a little: High level build of a box is done in 2 sequences:
  
  1. user_data bootstrap : Get user_data instructions built by build.sh and run it
  2. box bootstrap       : Start booting the box, with scripts/puppets from repositories/packages.
  
98-test-box.sh is added in the first sequence. It will help you to connect to the box, do any update you want, and thanks to a flag in /tmp, cloudinit will start the second sequence based on repositories/files updated.

If you want to test an update in the first boot sequence, do your changes locally, and start your build.
If you want to test an update in the second boot sequence, you will need to use this 98-test-box.sh. Here some steps to play with it:

1. Add '--extra-bs-step maestro/build/extra-bs-step/98-test-box.sh' to your build.sh call.
   Ex: 

    [ ~/src/maestro/build ]$ bin/build.sh --box-name maestro --build-config box --extra-bs-step maestro/build/extra-bs-step/98-test-box.sh

2. On another shell session, call test-box --configure ServerIP --repo maestro
   ServerIP is given by build.sh previously. You may need to wait for the box to respond to the ssh protocol.
   Ex:
    [ ~/src/maestro/build ]$ test-box --configure ubuntu@15.125.115.161 --repo maestro

3. Do your updates, and commit them
   Ex:
    [ ~/src/maestro/build ]$ vim myFile
    [ ~/src/maestro/build ]$ git add myFile
    [ ~/src/maestro/build ]$ git commit -m "My file added"
    [ ~/src/maestro/build ]$ test-box --send
    [ ~/src/maestro/build ]$ ssh -t ubuntu@15.125.115.161 sudo -i
    [root@15.125.115.161 ~] touch /tmp/test-box
    [root@15.125.115.161 ~] tail -f /var/log/cloud-init.log

