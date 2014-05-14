# == Class: jimador::test::test_discover_ci
# (c) Copyright 2014 Hewlett-Packard Development Company, L.P.
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
# test discovering the ci node by inserting fake data
class jimador::test::setup_documentation {

  jimador::write_config_yaml { 'documentation':
        data => parseyaml("
  -
    dname: 'Community Site'
    category: 'community'
    url: 'http://www.google.com'
  -
    dname: 'Kit Tutorial'
    category: 'tutorial'
    url: 'http://www.google.com'
  -
    dname: 'FAQ Site'
    category: 'faq'
    url: 'http://www.google.com'
"),
  }
}
