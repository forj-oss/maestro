# Starting Maestro bootstrap from forj/maestro repository.

if [ -x /opt/config/production/git/maestro/bootstrap/init.sh ]
then
   # Initialize bootstrap for Maestro
   /opt/config/production/git/maestro/bootstrap/init.sh /opt/config/production
fi

