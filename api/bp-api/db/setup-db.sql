/*
 * create user (i.e. the service account)
 */

GRANT ALL ON kit_bp.* TO 'kitusr'@'localhost' IDENTIFIED BY '$Changeme01';

/*
 * kit_bp database
 */

CREATE DATABASE IF NOT EXISTS `kit_bp`;

/*
 * table: kit_bp
 */

USE kit_bp;

CREATE TABLE IF NO EXISTS `kit_bp`.`blueprints` (
  `id` VARCHAR(5) NOT NULL,
  `tools` TEXT NULL,
  `defect_tracker` TEXT NULL,
  `auth` TEXT NULL,
  `users` TEXT NULL,
  `projects` TEXT NULL,
  `documentation` TEXT NULL,
  `createdAt` TIMESTAMP NULL,
  `updatedAt` TIMESTAMP NULL,
  PRIMARY KEY (`id`));