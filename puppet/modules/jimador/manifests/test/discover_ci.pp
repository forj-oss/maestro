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
class jimador::test::discover_ci {

# we use json data here, but could also be yaml data see setup_documentation for example
  $json_data = parsejson("{
                    \"gerrit\" : {
                                  \"tool_email\" :\"${::gerrit_email}\",
                                  \"tool_config\":\"${::gerrit_url_config}\",
                                  \"tool_url\"   :\"${::gerrit_url}\",
                                  \"category\"   :\"dev\",
                                  \"dname\"      :\"Gerrit\",
                                  \"desc\"       :\"Code review\"
                                 },
                    \"pastebin\" : {
                                  \"tool_email\" :\"\",
                                  \"tool_config\":\"${::pastebin_url_config}\",
                                  \"tool_url\"   :\"${::pastebin_url}\",
                                  \"category\"   :\"dev\",
                                  \"dname\"      :\"Pastebin\",
                                  \"desc\"       :\"Store, share and compare text snippets\"
                                 },
                    \"jenkins\" : {
                                  \"tool_email\" :\"\",
                                  \"tool_config\":\"${::jenkins_url_config}\",
                                  \"tool_url\"   :\"${::jenkins_url}\",
                                  \"category\"   :\"dev\",
                                  \"dname\"      :\"Jenkins\",
                                  \"desc\"       :\"Continuous integration\"
                                 },
                    \"zuul\" : {
                                  \"tool_email\" :\"\",
                                  \"tool_config\":\"${::zuul_url_config}\",
                                  \"tool_url\"   :\"${::zuul_url}\",
                                  \"category\"   :\"dev\",
                                  \"dname\"      :\"Zuul\",
                                  \"desc\"       :\"Pipeline oriented project gating\"
                                 },
                     \"puppet\" : {
                                  \"tool_email\" :\"\",
                                  \"tool_config\":\"${::puppet_url_config}\",
                                  \"tool_url\"   :\"${::puppet_url}\",
                                  \"category\"   :\"dev\",
                                  \"dname\"      :\"Puppet Dashboard\",
                                  \"desc\"       :\"View managed nodes\"
                                 },
                     \"graphite\" : {
                                  \"tool_email\" :\"\",
                                  \"tool_config\":\"${::graphite_config}\",
                                  \"tool_url\"   :\"${::graphite_url}\",
                                  \"category\"   :\"dev\",
                                  \"dname\"      :\"Graphite\",
                                  \"desc\"       :\"View graphs\"
                                 }
                 }")

  jimador::discover { 'ci-node':
        tools      => ['jenkins','zuul'],
        tools_data => $json_data,
  }
}
