/*
 *
 * (c) Copyright 2014 Hewlett-Packard Development Company, L.P.
 *
 *   Licensed under the Apache License, Version 2.0 (the "License");
 *   you may not use this file except in compliance with the License.
 *   You may obtain a copy of the License at
 *
 *       http://www.apache.org/licenses/LICENSE-2.0
 *
 *   Unless required by applicable law or agreed to in writing, software
 *   distributed under the License is distributed on an "AS IS" BASIS,
 *   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *   See the License for the specific language governing permissions and
 *   limitations under the License.
 *
 */
CREATE DATABASE IF NOT EXISTS kit_info;
GRANT ALL ON kit_info.* TO '<%= @mysql_user %>'@'<%= @mysql_server %>' IDENTIFIED BY '<%= @mysql_password %>';
USE kit_info;
CREATE TABLE IF NOT EXISTS kit_tools_ui (
  tool_id       smallint(5) unsigned NOT NULL AUTO_INCREMENT,
  tool_name     varchar(40)  NOT NULL,
  tool_desc     varchar(400) NOT NULL,
  tool_category varchar(40)  NOT NULL,
  tool_icon     varchar(45)  DEFAULT NULL,
  tool_css      varchar(45)  NOT NULL,
  tool_fields   text NULL,
  PRIMARY KEY (tool_id)
);
INSERT IGNORE kit_tools_ui VALUES (1,'HP Agile Manager','HP Agile Manager',NULL,'/assets/hp_logo_blue_small.png','hp-agm','[ { "attrs": { "for": "tenantId", "style": "display: inline; font-size: 13px;" }, "content": [ {}, { "text": "Tenant ID" } ], "type": "label" }, { "attrs": { "type": "text" }, "id": "tenantId", "type": "input" } ]');
INSERT IGNORE kit_tools_ui VALUES (2,'Launchpad','Launchpad',NULL,'/assets/launchpad.png','launchpad-text',NULL);
INSERT IGNORE kit_tools_ui VALUES (3,'Bugzilla','Bugzilla',NULL,'/assets/bugzilla_logo.png','bugzilla-text',NULL);
