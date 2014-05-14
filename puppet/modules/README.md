= Overview
These modules will mainly be focused on being blueprint independent.
Modules created here should not require modules from another blueprint, but
they may require 3rd party modules as specified by modules.env


== Orchestration / Gozer contribution modules ==
These modules were core contributions for behavior changes based on gozer 
best practices for ci system management.
# packages
#: Allows us to manage package installations from hiera, supports many 
#: all features of package specification
# hiera
#: Sets up our hiera data, works in conjuction with runtime_project\files\hiera
# puppet
#: Sets up all puppet required infastructure and manages puppet.conf.  
#: Configured to run puppet under cron/passenger, includes reporting and 
#: dashboard.
# pip
#: Sets up python module installer tool.
# salt
#: Sets up saltmaster and agents
# mysql_tuning
#: used to adjust sizings for mysql installation.

== Forj core modules ==
These modules help integrate a working forj system with push button click functionality.
# cacerts
#: Manage ssl certificates and private key data (ssh, key pair exchanges)
# gardener
#: Manage cloud things, compute, storage, networking, and cdn.
# jimador
#: Manage discovery for puppet and communication to maestro.
# maestro
#: UI rendering engine for easy push button management.
# nodejs_wrap
#: required to manage/install maestro requirements

= License
 Copyright 2013 OpenStack Foundation.
 Copyright 2013 Hewlett-Packard Development Company, L.P.

 Licensed under the Apache License, Version 2.0 (the "License"); you may
 not use this file except in compliance with the License. You may obtain
 a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
 License for the specific language governing permissions and limitations
 under the License.
