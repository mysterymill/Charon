-- ########## 0. CLEAN ##########

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

-- ########## 1. TABLES ##########

-- START password
CREATE TABLE IF NOT EXISTS password (
    id              INTEGER UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    hash            VARCHAR(256) NOT NULL,
    salt            VARCHAR(256) NULL,
    algorithm       VARCHAR(12) NOT NULL,
    iterations      SMALLINT UNSIGNED NOT NULL DEFAULT 12,
    preliminary     BOOLEAN NOT NULL DEFAULT TRUE,
    created         DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated         DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- END password

-- START user
CREATE TABLE IF NOT EXISTS user (
    id              INTEGER UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    enabled         BOOLEAN NOT NULL DEFAULT FALSE,
    creator_id      INTEGER UNSIGNED NOT NULL REFERENCES user(id),
	password_id		INTEGER UNSIGNED NOT NULL UNIQUE REFERENCES password(id),
    created         DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated         DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    description     VARCHAR(255) DEFAULT NULL
);

-- END user

-- START environment
CREATE TABLE IF NOT EXISTS environment (
    id              INTEGER UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    name            VARCHAR(64) UNIQUE NOT NULL,
    shorthand       VARCHAR(8) UNIQUE NOT NULL,
    enabled         BOOLEAN NOT NULL DEFAULT FALSE,
    creator_id      INTEGER UNSIGNED NOT NULL REFERENCES user(id),
    created         DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated         DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    description     VARCHAR(255) DEFAULT NULL
);
-- END environment

-- START user_identifier
CREATE TABLE IF NOT EXISTS user_identifier (
    id              INTEGER UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    identifier      VARCHAR(256) NOT NULL,
    type            ENUM('USERNAME', 'EMAIL') NOT NULL,
    user_id         INTEGER UNSIGNED NOT NULL REFERENCES user(id),
    environment_id  INTEGER UNSIGNED NOT NULL REFERENCES environment(id),   -- required to ensure that every identifier exists max. once per environment
    created         DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated         DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    INDEX(identifier)
);
-- END user_identifier

-- START domain
CREATE TABLE IF NOT EXISTS domain (
    id              INTEGER UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    name            VARCHAR(64) NOT NULL,
    enabled         BOOLEAN NOT NULL DEFAULT FALSE,
    creator_id      INTEGER UNSIGNED NOT NULL REFERENCES user(id),
    environment_id  INTEGER UNSIGNED NOT NULL REFERENCES environment(id),
    created         DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated         DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    description     VARCHAR(255) DEFAULT NULL,
    parent_id       INTEGER UNSIGNED NOT NULL DEFAULT 0 REFERENCES domain(id),
    owner_id        INTEGER UNSIGNED NOT NULL REFERENCES user(id)
);

-- START config
CREATE TABLE IF NOT EXISTS config (
    id              INTEGER UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    name            VARCHAR(64) NOT NULL,
    enabled         BOOLEAN NOT NULL DEFAULT FALSE,
    inheritable     BOOLEAN NOT NULL DEFAULT FALSE,
    origin_id       INTEGER UNSIGNED NOT NULL REFERENCES domain(id),     -- The domain a config entry lives in
    target_id       INTEGER UNSIGNED NOT NULL REFERENCES domain(id),     -- The domain a config entry refers to
    set_by_user_id  INTEGER UNSIGNED NOT NULL REFERENCES user(id),
    created         DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated         DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    value           VARCHAR(255) DEFAULT NULL,
    description     VARCHAR(255) DEFAULT NULL
);
-- END config

-- START role
CREATE TABLE IF NOT EXISTS role (
    id              INTEGER UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    name            VARCHAR(64) NOT NULL,
    enabled         BOOLEAN NOT NULL DEFAULT FALSE,
    domain_id       INTEGER UNSIGNED NOT NULL REFERENCES domain(id),
    creator_id      INTEGER UNSIGNED NOT NULL REFERENCES user(id),
    created         DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated         DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    description     VARCHAR(255) DEFAULT NULL
);
-- END role

-- START permission
CREATE TABLE IF NOT EXISTS permission (
    id              INTEGER UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    name            VARCHAR(64) NOT NULL,
    enabled         BOOLEAN NOT NULL DEFAULT FALSE,
    inheritable     BOOLEAN NOT NULL DEFAULT FALSE,
    origin_id       INTEGER UNSIGNED NOT NULL REFERENCES domain(id),     -- The domain a permission entry lives in
    created         DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated         DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    description     VARCHAR(255) DEFAULT NULL
);
-- END permission

-- START user_has_role
CREATE TABLE IF NOT EXISTS user_has_role (
    id              INTEGER UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    user_id         INTEGER UNSIGNED NOT NULL REFERENCES user(id),
    role_id         INTEGER UNSIGNED NOT NULL REFERENCES role(id),
    created         DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL
);
-- END user_has_role

-- START role_has_permission_for_domain
CREATE TABLE IF NOT EXISTS role_has_permission_for_domain (
    id              INTEGER UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    role_id         INTEGER UNSIGNED NOT NULL REFERENCES role(id),
    permission_id   INTEGER UNSIGNED NOT NULL REFERENCES permission(id),
    target_id       INTEGER UNSIGNED NOT NULL REFERENCES domain(id),        -- The domain a permission entry refers to for a role
    created         DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL
);
-- END role_has_permission_for_domain

-- START role_config_permission
CREATE TABLE IF NOT EXISTS role_config_permission (
    id              INTEGER UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    role_id         INTEGER UNSIGNED NOT NULL REFERENCES role(id),
    config_id       INTEGER UNSIGNED NOT NULL REFERENCES config(id),
    type            ENUM('READ', 'MODIFY') NOT NULL,
    created         DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL
);
-- END role_config_permission

-- START session
CREATE TABLE IF NOT EXISTS `session` (
    id              CHAR(32) PRIMARY KEY,
    user_id         INTEGER UNSIGNED NOT NULL UNIQUE REFERENCES user(id) ON DELETE CASCADE,
    permanent       BOOLEAN NOT NULL DEFAULT FALSE,
    created         DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated         DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL
);
-- END session

-- START session_to_domain
CREATE TABLE IF NOT EXISTS `session_to_domain` (
    id              INTEGER UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    session_id      CHAR(32) NOT NULL REFERENCES session(id) ON DELETE CASCADE,
    domain_id       INTEGER UNSIGNED NOT NULL REFERENCES domain(id) ON DELETE CASCADE
);
-- END session_to_domain

-- ########## 2. Constraints ##########
ALTER TABLE user ADD COLUMN origin_id INTEGER UNSIGNED NOT NULL DEFAULT 0 REFERENCES domain(id);
ALTER TABLE user_identifier ADD UNIQUE `user_identifier_per_environment_uq`(identifier, environment_id);

-- ########## 3. Views ##########
CREATE VIEW roles_of_session AS SELECT s.id session_id, r.id role_id, d.id domain_id FROM session s, user u, user_has_role uhr, role r, domain d, session_to_domain std
WHERE s.user_id = u.id AND u.id = uhr.user_id AND uhr.role_id = r.id AND r.domain_id = d.id AND s.id = std.session_id AND std.domain_id = d.id;

CREATE VIEW roles_of_user AS SELECT u.id user, r.id role_id, d.id domain_id FROM user u, user_has_role uhr, role r, domain d
WHERE u.id = uhr.user_id AND uhr.role_id = r.id AND r.domain_id = d.id AND u.enabled = TRUE;

-- ########## 4. Inserts ##########
SET FOREIGN_KEY_CHECKS=0;

-- Insert environments
INSERT INTO environment (name, shorthand, enabled, creator_id, description) VALUES
('development', 'dev', TRUE, 0, 'Development environment'),
('integration', 'int', FALSE, 0, 'Integration environment'),
('production', 'prod', FALSE, 0, 'Production environment');

-- Insert pwds for default users
INSERT INTO password (hash, algorithm) VALUES
('$2b$12$x4EwIlqpEVrdxERlPoKfy.TX4cU5kiTfDrXHRI0yrUeHD/t.GWB3e', 'bcrypt'),    -- VonUndZuFalkenberg
('$2b$12$JwT6uRoCMinIugz4HLe.LeKBfScV7apBFQiznSHILr6oL04qUgQau', 'bcrypt'),    -- IchHasseMeinLeben
('$2a$12$/dXWFHtgAr5u/vA3B9zx7.pAwtmpDBCh6DIe6L3ReknFlm9xNvOtm', 'bcrypt'),    -- viewer-all
('$2a$12$CZIn3H4L8H7zuX6oAd1p7Ojf7xPls3u.umuZiAnMjcWyKUhUc/g2K', 'bcrypt'),    -- viewer-winston
('$2a$12$ev3C724ws1c2HTuWNSAfuOmZzIwE61.H3kgizLRjttK3LUAo9tV1O', 'bcrypt'),    -- operator-all
('$2a$12$JYOkIFd5XepxvNSlc/klcOdM9gxJaYFiTZfGr4GuzUn3JmoNiE4ZC', 'bcrypt');    -- operator-winston

-- Insert default users
INSERT INTO user (enabled, creator_id, description, origin_id, password_id) VALUES
(FALSE, 1, 'Root user', 0, (SELECT id FROM password WHERE hash LIKE '%.GWB3e')),
(TRUE, 1, 'Winston application root user', 0, (SELECT id FROM password WHERE hash LIKE '%qUgQau')),
(TRUE, 1, 'User that can see all users and domains', 0, (SELECT id FROM password WHERE hash LIKE '%xNvOtm')),
(TRUE, 1, 'User that can see all users and domains in the winston domain', 0, (SELECT id FROM password WHERE hash LIKE '%Uc/g2K')),
(TRUE, 1, 'User that can see and modify all users and domains', 0, (SELECT id FROM password WHERE hash LIKE '%o9tV1O')),
(TRUE, 1, 'User that can see and modify all users and domains in the winston domain', 0, (SELECT id FROM password WHERE hash LIKE '%NiE4ZC'));

-- Insert username identifiers for default users
INSERT INTO user_identifier (identifier, type, user_id, environment_id) VALUES
('root', 'USERNAME', (SELECT id FROM user WHERE description = 'Root user'), (SELECT id FROM environment WHERE shorthand = 'dev')),
('winston', 'USERNAME', (SELECT id FROM user WHERE description = 'Winston application root user'), (SELECT id FROM environment WHERE shorthand = 'dev')),
('viewer-all', 'USERNAME', (SELECT id FROM user WHERE description = 'User that can see all users and domains'), (SELECT id FROM environment WHERE shorthand = 'dev')),
('viewer-winston', 'USERNAME', (SELECT id FROM user WHERE description = 'User that can see all users and domains in the winston domain'), (SELECT id FROM environment WHERE shorthand = 'dev')),
('operator-all', 'USERNAME', (SELECT id FROM user WHERE description = 'User that can see and modify all users and domains'), (SELECT id FROM environment WHERE shorthand = 'dev')),
('operator-winston', 'USERNAME', (SELECT id FROM user WHERE description = 'User that can see and modify all users and domains in the winston domain'), (SELECT id FROM environment WHERE shorthand = 'dev')),
('root', 'USERNAME', (SELECT id FROM user WHERE description = 'Root user'), (SELECT id FROM environment WHERE shorthand = 'int')),
('winston', 'USERNAME', (SELECT id FROM user WHERE description = 'Winston application root user'), (SELECT id FROM environment WHERE shorthand = 'int')),
('root', 'USERNAME', (SELECT id FROM user WHERE description = 'Root user'), (SELECT id FROM environment WHERE shorthand = 'prod')),
('winston', 'USERNAME', (SELECT id FROM user WHERE description = 'Winston application root user'), (SELECT id FROM environment WHERE shorthand = 'prod'));

UPDATE user SET creator_id = (SELECT user_id FROM user_identifier WHERE identifier = 'root' AND environment_id = (SELECT id FROM environment WHERE shorthand = 'dev'))
WHERE id = (SELECT user_id FROM user_identifier WHERE identifier = 'winston' AND environment_id = (SELECT id FROM environment WHERE shorthand = 'dev'));
UPDATE user SET creator_id = (SELECT user_id FROM user_identifier WHERE identifier = 'winston' AND environment_id = (SELECT id FROM environment WHERE shorthand = 'dev'))
WHERE id IN (SELECT user_id FROM user_identifier WHERE identifier IN ('viewer-all', 'viewer-winston', 'operator-all', 'operator-winston') AND environment_id = (SELECT id FROM environment WHERE shorthand = 'dev'));
UPDATE user SET creator_id = (SELECT user_id FROM user_identifier WHERE identifier = 'root' AND environment_id = (SELECT id FROM environment WHERE shorthand = 'int'))
WHERE id = (SELECT user_id FROM user_identifier WHERE identifier = 'winston' AND environment_id = (SELECT id FROM environment WHERE shorthand = 'int'));
UPDATE user SET creator_id = (SELECT user_id FROM user_identifier WHERE identifier = 'root' AND environment_id = (SELECT id FROM environment WHERE shorthand = 'prod'))
WHERE id = (SELECT user_id FROM user_identifier WHERE identifier = 'winston' AND environment_id = (SELECT id FROM environment WHERE shorthand = 'prod'));

-- Insert domains
INSERT INTO domain (name, creator_id, environment_id, description, parent_id, owner_id) VALUES
('root', (SELECT user_id FROM user_identifier WHERE identifier = 'root' AND environment_id = (SELECT id FROM environment WHERE shorthand = 'dev')), (SELECT id FROM environment WHERE shorthand = 'dev'), 'Root node of the domain tree', 0, 0),
('winston', (SELECT user_id FROM user_identifier WHERE identifier = 'winston' AND environment_id = (SELECT id FROM environment WHERE shorthand = 'dev')), (SELECT id FROM environment WHERE shorthand = 'dev'), 'Root node of the winston application domain branch', 0, 1);

UPDATE domain SET parent_id = (SELECT id FROM domain WHERE name = 'root'), owner_id = (SELECT user_id FROM user_identifier WHERE identifier = 'root' AND environment_id = (SELECT id FROM environment WHERE shorthand = 'dev')) WHERE name = 'root';
UPDATE domain SET parent_id = (SELECT id FROM domain WHERE name = 'root'), owner_id = (SELECT user_id FROM user_identifier WHERE identifier = 'winston' AND environment_id = (SELECT id FROM environment WHERE shorthand = 'dev')) WHERE name = 'winston';

INSERT INTO domain (name, creator_id, environment_id, description, parent_id, owner_id) VALUES
('service', (SELECT user_id FROM user_identifier WHERE identifier = 'winston' AND environment_id = (SELECT id FROM environment WHERE shorthand = 'dev')), (SELECT id FROM environment WHERE shorthand = 'dev'), 'Domain of the winston service application', 0, (SELECT user_id FROM user_identifier WHERE identifier = 'winston' AND environment_id = (SELECT id FROM environment WHERE shorthand = 'dev'))),
('web', (SELECT user_id FROM user_identifier WHERE identifier = 'winston' AND environment_id = (SELECT id FROM environment WHERE shorthand = 'dev')), (SELECT id FROM environment WHERE shorthand = 'dev'), 'Domain of the winston client web application', 0, (SELECT user_id FROM user_identifier WHERE identifier = 'winston' AND environment_id = (SELECT id FROM environment WHERE shorthand = 'dev')));

UPDATE domain SET parent_id = (SELECT id FROM domain WHERE name = 'winston') WHERE name = 'service';
UPDATE domain SET parent_id = (SELECT id FROM domain WHERE name = 'winston') WHERE name = 'web';
-- END domain

-- Insert default config
INSERT INTO config (name, enabled, origin_id, target_id, set_by_user_id, value, description) VALUES
('domain_separator', TRUE, (SELECT id FROM domain WHERE name = 'winston'), (SELECT id FROM domain WHERE name = 'service'),
(SELECT user_id FROM user_identifier WHERE identifier = 'winston' AND environment_id = (SELECT id FROM environment WHERE shorthand = 'dev')), '.', 'Declares the character that separates domains'),
('password_default_algorithm', TRUE, (SELECT id FROM domain WHERE name = 'winston'), (SELECT id FROM domain WHERE name = 'service'),
(SELECT user_id FROM user_identifier WHERE identifier = 'winston' AND environment_id = (SELECT id FROM environment WHERE shorthand = 'dev')), 'bcrypt', 'The default algorithm that is used to hash passwords'),
('password_default_iterations', TRUE, (SELECT id FROM domain WHERE name = 'winston'), (SELECT id FROM domain WHERE name = 'service'),
(SELECT user_id FROM user_identifier WHERE identifier = 'winston' AND environment_id = (SELECT id FROM environment WHERE shorthand = 'dev')), '12', 'The default number of password hash iterations'),
('password_max_length', TRUE, (SELECT id FROM domain WHERE name = 'winston'), (SELECT id FROM domain WHERE name = 'service'),
(SELECT user_id FROM user_identifier WHERE identifier = 'winston' AND environment_id = (SELECT id FROM environment WHERE shorthand = 'dev')), '36', 'The maximum password length; bcrypt has a limit at 72 bytes');

UPDATE user SET origin_id = (SELECT id FROM domain WHERE name = 'root') WHERE id = (SELECT user_id FROM user_identifier WHERE identifier = 'root' AND environment_id = (SELECT id FROM environment WHERE shorthand = 'dev'));
UPDATE user SET origin_id = (SELECT id FROM domain WHERE name = 'winston') WHERE id IN (SELECT user_id FROM user_identifier WHERE identifier IN ('winston', 'viewer-all', 'viewer-winston', 'operator-all', 'operator-winston') AND environment_id = (SELECT id FROM environment WHERE shorthand = 'dev'));

-- Insert roles for winston application
INSERT INTO role (name, enabled, domain_id, creator_id, description) VALUES
('viewer-all', TRUE, (SELECT id FROM domain WHERE name = 'root'), (SELECT user_id FROM user_identifier WHERE identifier = 'winston' AND environment_id = (SELECT id FROM environment WHERE shorthand = 'dev')), 'Role that can see all config entries but can modify none and permissions'),
('viewer-winston', TRUE, (SELECT id FROM domain WHERE name = 'winston'), (SELECT user_id FROM user_identifier WHERE identifier = 'winston' AND environment_id = (SELECT id FROM environment WHERE shorthand = 'dev')), 'Role that can see all config entries that relate to the winston application but can modify none and permissions'),
('operator-all', TRUE, (SELECT id FROM domain WHERE name = 'winston'), (SELECT user_id FROM user_identifier WHERE identifier = 'winston' AND environment_id = (SELECT id FROM environment WHERE shorthand = 'dev')), 'Role that can see and modify all config entries and permissions'),
('operator-winston', TRUE, (SELECT id FROM domain WHERE name = 'winston'), (SELECT user_id FROM user_identifier WHERE identifier = 'winston' AND environment_id = (SELECT id FROM environment WHERE shorthand = 'dev')), 'Role that can see and modify all config entries and permissions');

-- Insert permissions used in winston application
INSERT INTO permission (name, enabled, inheritable, origin_id, description) VALUES
('create_subdomain', TRUE, TRUE, (SELECT id FROM domain WHERE name = 'winston'), 'Permission to create subdomains'),
('read_subdomain', TRUE, TRUE, (SELECT id FROM domain WHERE name = 'winston'), 'Permission to read subdomain properties'),
('update_subdomain', TRUE, TRUE, (SELECT id FROM domain WHERE name = 'winston'), 'Permission to modify subdomain properties'),
('delete_subdomain', TRUE, TRUE, (SELECT id FROM domain WHERE name = 'winston'), 'Permission to delete subdomains'),
('create_user', TRUE, TRUE, (SELECT id FROM domain WHERE name = 'winston'), 'Permission to create users'),
('read_user', TRUE, TRUE, (SELECT id FROM domain WHERE name = 'winston'), 'Permission to read user properties'),
('update_user', TRUE, TRUE, (SELECT id FROM domain WHERE name = 'winston'), 'Permission to modify user properties'),
('delete_user', TRUE, TRUE, (SELECT id FROM domain WHERE name = 'winston'), 'Permission to delete users'),
('modify_user_permissions', TRUE, TRUE, (SELECT id FROM domain WHERE name = 'winston'), 'Permission to modify user permissions');

-- Give default users roles
INSERT INTO user_has_role (user_id, role_id) VALUES
((SELECT user_id FROM user_identifier WHERE identifier = 'viewer-all' AND environment_id = (SELECT id FROM environment WHERE shorthand = 'dev')), (SELECT id FROM role WHERE name = 'viewer-all')),
((SELECT user_id FROM user_identifier WHERE identifier = 'viewer-winston' AND environment_id = (SELECT id FROM environment WHERE shorthand = 'dev')), (SELECT id FROM role WHERE name = 'viewer-winston')),
((SELECT user_id FROM user_identifier WHERE identifier = 'operator-all' AND environment_id = (SELECT id FROM environment WHERE shorthand = 'dev')), (SELECT id FROM role WHERE name = 'operator-all')),
((SELECT user_id FROM user_identifier WHERE identifier = 'operator-winston' AND environment_id = (SELECT id FROM environment WHERE shorthand = 'dev')), (SELECT id FROM role WHERE name = 'operator-winston')),
((SELECT user_id FROM user_identifier WHERE identifier = 'winston' AND environment_id = (SELECT id FROM environment WHERE shorthand = 'dev')), (SELECT id FROM role WHERE name = 'viewer-all')),
((SELECT user_id FROM user_identifier WHERE identifier = 'winston' AND environment_id = (SELECT id FROM environment WHERE shorthand = 'dev')), (SELECT id FROM role WHERE name = 'viewer-winston')),
((SELECT user_id FROM user_identifier WHERE identifier = 'winston' AND environment_id = (SELECT id FROM environment WHERE shorthand = 'dev')), (SELECT id FROM role WHERE name = 'operator-all')),
((SELECT user_id FROM user_identifier WHERE identifier = 'winston' AND environment_id = (SELECT id FROM environment WHERE shorthand = 'dev')), (SELECT id FROM role WHERE name = 'operator-winston'));

-- Define permissions of roles per domain
INSERT INTO role_has_permission_for_domain (role_id, permission_id, target_id) VALUES
-- role 'viewer-all' can 'read_subdomain' and 'read_user' in all under domain 'root'
((SELECT id FROM role WHERE name = 'viewer-all'), (SELECT id FROM permission WHERE name = 'read_subdomain' AND origin_id = (SELECT id FROM domain WHERE name = 'winston')), (SELECT id FROM domain WHERE name = 'root')),
((SELECT id FROM role WHERE name = 'viewer-all'), (SELECT id FROM permission WHERE name = 'read_user' AND origin_id = (SELECT id FROM domain WHERE name = 'winston')), (SELECT id FROM domain WHERE name = 'root')),
-- role 'viewer-winston' can 'read_subdomain' and 'read_user' in all under domain 'winston'
((SELECT id FROM role WHERE name = 'viewer-winston'), (SELECT id FROM permission WHERE name = 'read_subdomain' AND origin_id = (SELECT id FROM domain WHERE name = 'winston')), (SELECT id FROM domain WHERE name = 'winston')),
((SELECT id FROM role WHERE name = 'viewer-winston'), (SELECT id FROM permission WHERE name = 'read_user' AND origin_id = (SELECT id FROM domain WHERE name = 'winston')), (SELECT id FROM domain WHERE name = 'winston')),
-- role 'operator-all' can '*_subdomain', '*_user' and 'modify_user_permissions' in all under domain 'root'
((SELECT id FROM role WHERE name = 'operator-all'), (SELECT id FROM permission WHERE name = 'create_subdomain' AND origin_id = (SELECT id FROM domain WHERE name = 'winston')), (SELECT id FROM domain WHERE name = 'root')),
((SELECT id FROM role WHERE name = 'operator-all'), (SELECT id FROM permission WHERE name = 'read_subdomain' AND origin_id = (SELECT id FROM domain WHERE name = 'winston')), (SELECT id FROM domain WHERE name = 'root')),
((SELECT id FROM role WHERE name = 'operator-all'), (SELECT id FROM permission WHERE name = 'update_subdomain' AND origin_id = (SELECT id FROM domain WHERE name = 'winston')), (SELECT id FROM domain WHERE name = 'root')),
((SELECT id FROM role WHERE name = 'operator-all'), (SELECT id FROM permission WHERE name = 'read_subdomain' AND origin_id = (SELECT id FROM domain WHERE name = 'winston')), (SELECT id FROM domain WHERE name = 'root')),
((SELECT id FROM role WHERE name = 'operator-all'), (SELECT id FROM permission WHERE name = 'delete_subdomain' AND origin_id = (SELECT id FROM domain WHERE name = 'winston')), (SELECT id FROM domain WHERE name = 'root')),
((SELECT id FROM role WHERE name = 'operator-all'), (SELECT id FROM permission WHERE name = 'create_user' AND origin_id = (SELECT id FROM domain WHERE name = 'winston')), (SELECT id FROM domain WHERE name = 'root')),
((SELECT id FROM role WHERE name = 'operator-all'), (SELECT id FROM permission WHERE name = 'read_user' AND origin_id = (SELECT id FROM domain WHERE name = 'winston')), (SELECT id FROM domain WHERE name = 'root')),
((SELECT id FROM role WHERE name = 'operator-all'), (SELECT id FROM permission WHERE name = 'update_user' AND origin_id = (SELECT id FROM domain WHERE name = 'winston')), (SELECT id FROM domain WHERE name = 'root')),
((SELECT id FROM role WHERE name = 'operator-all'), (SELECT id FROM permission WHERE name = 'delete_user' AND origin_id = (SELECT id FROM domain WHERE name = 'winston')), (SELECT id FROM domain WHERE name = 'root')),
((SELECT id FROM role WHERE name = 'operator-all'), (SELECT id FROM permission WHERE name = 'modify_user_permissions' AND origin_id = (SELECT id FROM domain WHERE name = 'winston')), (SELECT id FROM domain WHERE name = 'root')),
-- role 'operator-winston' can '*_subdomain', '*_user' and 'modify_user_permissions' in all under domain 'winston'
((SELECT id FROM role WHERE name = 'operator-winston'), (SELECT id FROM permission WHERE name = 'create_subdomain' AND origin_id = (SELECT id FROM domain WHERE name = 'winston')), (SELECT id FROM domain WHERE name = 'winston')),
((SELECT id FROM role WHERE name = 'operator-winston'), (SELECT id FROM permission WHERE name = 'read_subdomain' AND origin_id = (SELECT id FROM domain WHERE name = 'winston')), (SELECT id FROM domain WHERE name = 'winston')),
((SELECT id FROM role WHERE name = 'operator-winston'), (SELECT id FROM permission WHERE name = 'update_subdomain' AND origin_id = (SELECT id FROM domain WHERE name = 'winston')), (SELECT id FROM domain WHERE name = 'winston')),
((SELECT id FROM role WHERE name = 'operator-winston'), (SELECT id FROM permission WHERE name = 'read_subdomain' AND origin_id = (SELECT id FROM domain WHERE name = 'winston')), (SELECT id FROM domain WHERE name = 'winston')),
((SELECT id FROM role WHERE name = 'operator-winston'), (SELECT id FROM permission WHERE name = 'delete_subdomain' AND origin_id = (SELECT id FROM domain WHERE name = 'winston')), (SELECT id FROM domain WHERE name = 'winston')),
((SELECT id FROM role WHERE name = 'operator-winston'), (SELECT id FROM permission WHERE name = 'create_user' AND origin_id = (SELECT id FROM domain WHERE name = 'winston')), (SELECT id FROM domain WHERE name = 'winston')),
((SELECT id FROM role WHERE name = 'operator-winston'), (SELECT id FROM permission WHERE name = 'read_user' AND origin_id = (SELECT id FROM domain WHERE name = 'winston')), (SELECT id FROM domain WHERE name = 'winston')),
((SELECT id FROM role WHERE name = 'operator-winston'), (SELECT id FROM permission WHERE name = 'update_user' AND origin_id = (SELECT id FROM domain WHERE name = 'winston')), (SELECT id FROM domain WHERE name = 'winston')),
((SELECT id FROM role WHERE name = 'operator-winston'), (SELECT id FROM permission WHERE name = 'delete_user' AND origin_id = (SELECT id FROM domain WHERE name = 'winston')), (SELECT id FROM domain WHERE name = 'winston')),
((SELECT id FROM role WHERE name = 'operator-winston'), (SELECT id FROM permission WHERE name = 'modify_user_permissions' AND origin_id = (SELECT id FROM domain WHERE name = 'winston')), (SELECT id FROM domain WHERE name = 'winston'));

-- Define which role can modify which configs
INSERT INTO role_config_permission (role_id, config_id) VALUES
((SELECT id FROM role WHERE name = 'operator-all'), (SELECT id config_id FROM config WHERE name = 'domain_separator')),
((SELECT id FROM role WHERE name = 'operator-all'), (SELECT id config_id FROM config WHERE name = 'password_default_algorithm')),
((SELECT id FROM role WHERE name = 'operator-all'), (SELECT id config_id FROM config WHERE name = 'password_default_iterations')),
((SELECT id FROM role WHERE name = 'operator-all'), (SELECT id config_id FROM config WHERE name = 'password_max_length'));

COMMIT;

SET FOREIGN_KEY_CHECKS=1;