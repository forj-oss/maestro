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
 * create user (i.e. the service account)
 */

GRANT ALL ON kit_info.* TO '<%= @mysql_user %>'@'<%= @mysql_server %>' IDENTIFIED BY '<%= @mysql_password %>';

/*
 * kit_info database
 */

CREATE DATABASE IF NOT EXISTS `kit_info`;

/*
 * table: kit_options
 */

USE kit_info;

CREATE TABLE IF NOT EXISTS `kit_options` (
  `option_id` smallint(5) unsigned NOT NULL AUTO_INCREMENT,
  `option_name` varchar(40) NOT NULL,
  `option_value` varchar(400) NOT NULL,
  `option_regex` varchar(40) DEFAULT NULL,
  `option_desc` varchar(45) DEFAULT NULL,
  PRIMARY KEY (`option_id`),
  KEY `option_name` (`option_name`)
) ENGINE=InnoDB AUTO_INCREMENT=1000 DEFAULT CHARSET=utf8 PACK_KEYS=0;

/*
 NOTE: hack: according to mysql docs, the below works becuase we insert/hardcode the record id, if we let it autogen per DDL above!
       then INSERT IGNORE will not prevent a dupe record.
 */
INSERT IGNORE INTO kit_options VALUES (1,'agm_enabled','false',NULL,'agm defact tracking');
INSERT IGNORE INTO kit_options VALUES (2,'agm_tenant_id','',NULL,'agm tenant id');
INSERT IGNORE INTO kit_options VALUES (3,'bugzilla_enabled','false',NULL,'bugzilla defect tracking');
INSERT IGNORE INTO kit_options VALUES (4,'launchpad_enabled','false',NULL,'launchpad defect tracking');
INSERT IGNORE INTO kit_options VALUES (5,'agm_defect_url','',NULL,'AgM defect url');
INSERT IGNORE INTO kit_options VALUES (6,'launchpad_defect_url','https://code.launchpad.net/bugs/$2',NULL,'launchpad defect url');
INSERT IGNORE INTO kit_options VALUES (7,'bugzilla_defect_url','http://bugs.example.com/show_bug.cgi?id=$2',NULL,'bugzilla defect url');
INSERT IGNORE INTO kit_options VALUES (8,'openid_provider','<%= @auth_provider %>',NULL,'default openid provider');
INSERT IGNORE INTO kit_options VALUES (9,'openid_url','<%= @openidssourl %>',NULL,'default openid provider url');
INSERT IGNORE INTO kit_options VALUES (10,'show_welcome_notification','false',NULL,'Used to show the FORJ welcome message');
