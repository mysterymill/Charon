SET FOREIGN_KEY_CHECKS=0;
DROP VIEW roles_of_session;
DROP VIEW roles_of_user;

DROP TABLE IF EXISTS user_identifier;
DROP TABLE IF EXISTS user;
DROP TABLE IF EXISTS password;
DROP TABLE IF EXISTS domain;
DROP TABLE IF EXISTS config;
DROP TABLE IF EXISTS environment;
DROP TABLE IF EXISTS role;
DROP TABLE IF EXISTS permission;
DROP TABLE IF EXISTS user_has_role;
DROP TABLE IF EXISTS role_has_permission_for_domain;
DROP TABLE IF EXISTS role_config_permission;
DROP TABLE IF EXISTS permission_target_domain;
DROP TABLE IF EXISTS session_to_domain;
DROP TABLE IF EXISTS session;

SET FOREIGN_KEY_CHECKS=1;