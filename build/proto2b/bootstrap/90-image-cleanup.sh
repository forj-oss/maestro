# cleanup

mv /var/log/cloud-init.log /var/log/cloud-init.proto.$RANDOM.log
[ -d /var/lib/puppet/ssl ] && rm -fr /var/lib/puppet/ssl
[ -f /meta.js ] && rm -f /meta.js
[ -f /meta-boot.js ] && rm -f /meta-boot.js
TMP_HOST=/tmp/hosts.$$.$RANDOM
cat /etc/hosts|grep -v maestro > $TMP_HOST
mv $TMP_HOST /etc/hosts
umount /config
[ -d /config ] && rm -fr /config
[ -f /get-pip.py ] && rm -f /get-pip.py
exit 0
