# This sequence will wait for a '/tmp/test-box' flag on the new box to go forward on the cloud-init bootstrap sequence.
# This is used to test bootstrap sequence from a repository updated. See test-box.sh or git-review -x to retrieve values and go forward in running boot sequence.

# To test your new bootstrap sequence, add '--extra-bs-step maestro/build/extra-bs-step/98-test-box.sh' to your build.sh call.
# Connect to the box, update repositories needed. (test-box.sh or git-review -x)
# When all is updated as expected, do a touch of /tmp/test-box.

XTRACE="$(set +o | grep xtrace)"
VERBOSE="$(set +o | grep verbose)"

set +xv

echo "Test-box step sequence started. When your box has been updated as needed (test-box.sh or git-review -x), do a touch of '/tmp/test-box'"

while [ ! -f /tmp/test-box ]
do
  sleep 5
done

echo "/tmp/test-box flag detected. Bootstrap is back running."
eval $XTRACE
eval $VERBOSE
