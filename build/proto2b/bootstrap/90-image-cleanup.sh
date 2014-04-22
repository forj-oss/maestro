# cleanup

#rm -rf ./config

mv /var/log/cloud-init.log /var/log/cloud-init.proto.log
rm -fr /var/lib/puppet/ssl
rm -f /meta.js
umount /config
rm -fr /config
exit 0
