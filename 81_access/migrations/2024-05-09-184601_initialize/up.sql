-- ########## 0. CLEAN ##########

SET FOREIGN_KEY_CHECKS=0;
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
    name            VARCHAR(64) NOT NULL,
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
CREATE TABLE IF NOT EXISTS role_has_permission_for_domain
 (
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

-- ########## 2. Relations ##########
ALTER TABLE user ADD COLUMN origin_id INTEGER UNSIGNED NOT NULL DEFAULT 0 REFERENCES domain(id);

-- ########## 3. Inserts ##########
SET FOREIGN_KEY_CHECKS=0;
-- Insert pwds for default users
INSERT INTO password (hash, algorithm) VALUES
('$2b$12$x4EwIlqpEVrdxERlPoKfy.TX4cU5kiTfDrXHRI0yrUeHD/t.GWB3e', 'bcrypt'),    -- VonUndZuFalkenberg
('$2b$12$JwT6uRoCMinIugz4HLe.LeKBfScV7apBFQiznSHILr6oL04qUgQau', 'bcrypt'),    -- IchHasseMeinLeben
('$2a$12$/dXWFHtgAr5u/vA3B9zx7.pAwtmpDBCh6DIe6L3ReknFlm9xNvOtm', 'bcrypt'),    -- viewer-all
('$2a$12$CZIn3H4L8H7zuX6oAd1p7Ojf7xPls3u.umuZiAnMjcWyKUhUc/g2K', 'bcrypt'),    -- viewer-winston
('$2a$12$ev3C724ws1c2HTuWNSAfuOmZzIwE61.H3kgizLRjttK3LUAo9tV1O', 'bcrypt'),    -- operator-all
('$2a$12$JYOkIFd5XepxvNSlc/klcOdM9gxJaYFiTZfGr4GuzUn3JmoNiE4ZC', 'bcrypt');    -- operator-winston

-- Insert default users
INSERT INTO user (name, enabled, creator_id, description, origin_id, password_id) VALUES
('root', FALSE, 1, 'Root user', 0, (SELECT id FROM password WHERE hash LIKE '%.GWB3e')),
('winston', TRUE, 1, 'Winston application root user', 0, (SELECT id FROM password WHERE hash LIKE '%qUgQau')),
('viewer-all', TRUE, 1, 'User that can see all users and domains', 0, (SELECT id FROM password WHERE hash LIKE '%xNvOtm')),
('viewer-winston', TRUE, 1, 'User that can see all users and domains in the winston domain', 0, (SELECT id FROM password WHERE hash LIKE '%Uc/g2K')),
('operator-all', TRUE, 1, 'User that can see and modify all users and domains', 0, (SELECT id FROM password WHERE hash LIKE '%o9tV1O')),
('operator-winston', TRUE, 1, 'User that can see and modify all users and domains in the winston domain', 0, (SELECT id FROM password WHERE hash LIKE '%NiE4ZC'));

UPDATE user SET creator_id = (SELECT id FROM user WHERE name = 'root') WHERE name = 'winston';
UPDATE user SET creator_id = (SELECT id FROM user WHERE name = 'winston') WHERE name IN ('viewer-all', 'viewer-winston', 'operator-all', 'operator-winston');

-- Insert environments
INSERT INTO environment (name, shorthand, enabled, creator_id, description) VALUES
('development', 'dev', TRUE, (SELECT id FROM user WHERE name = 'root'), 'Development environment'),
('integration', 'int', FALSE, (SELECT id FROM user WHERE name = 'root'), 'Integration environment'),
('production', 'prod', FALSE, (SELECT id FROM user WHERE name = 'root'), 'Production environment');

-- Insert domains
INSERT INTO domain (name, creator_id, environment_id, description, parent_id, owner_id) VALUES
('root', (SELECT id FROM user WHERE name = 'root'), (SELECT id FROM environment WHERE shorthand = 'dev'), 'Root node of the domain tree', 0, 0),
('winston', (SELECT id FROM user WHERE name = 'winston'), (SELECT id FROM environment WHERE shorthand = 'dev'), 'Root node of the winston application domain branch', 0, 1);

UPDATE domain SET parent_id = (SELECT id FROM domain WHERE name = 'root'), owner_id = (SELECT id FROM user WHERE name = 'root') WHERE name = 'root';
UPDATE domain SET parent_id = (SELECT id FROM domain WHERE name = 'root'), owner_id = (SELECT id FROM user WHERE name = 'winston') WHERE name = 'winston';

INSERT INTO domain (name, creator_id, environment_id, description, parent_id, owner_id) VALUES
('service', (SELECT id FROM user WHERE name = 'winston'), (SELECT id FROM environment WHERE shorthand = 'dev'), 'Domain of the winston service application', 0, (SELECT id FROM user WHERE name = 'winston')),
('web', (SELECT id FROM user WHERE name = 'winston'), (SELECT id FROM environment WHERE shorthand = 'dev'), 'Domain of the winston client web application', 0, (SELECT id FROM user WHERE name = 'winston'));

UPDATE domain SET parent_id = (SELECT id FROM domain WHERE name = 'winston') WHERE name = 'service';
UPDATE domain SET parent_id = (SELECT id FROM domain WHERE name = 'winston') WHERE name = 'web';
-- END domain

-- Insert default config
INSERT INTO config (name, enabled, origin_id, target_id, set_by_user_id, value, description) VALUES
('domain_separator', TRUE, (SELECT id FROM domain WHERE name = 'winston'), (SELECT id FROM domain WHERE name = 'service'), (SELECT id FROM user WHERE name = 'winston'), '.', 'Declares the character that separates domains'),
('password_default_algorithm', TRUE, (SELECT id FROM domain WHERE name = 'winston'), (SELECT id FROM domain WHERE name = 'service'), (SELECT id FROM user WHERE name = 'winston'), 'bcrypt', 'The default algorithm that is used to hash passwords'),
('password_default_iterations', TRUE, (SELECT id FROM domain WHERE name = 'winston'), (SELECT id FROM domain WHERE name = 'service'), (SELECT id FROM user WHERE name = 'winston'), '12', 'The default number of password hash iterations'),
('password_max_length', TRUE, (SELECT id FROM domain WHERE name = 'winston'), (SELECT id FROM domain WHERE name = 'service'), (SELECT id FROM user WHERE name = 'winston'), '36', 'The maximum password length; bcrypt has a limit at 72 bytes');

UPDATE user SET origin_id = (SELECT id FROM domain WHERE name = 'root') WHERE name = 'root';
UPDATE user SET origin_id = (SELECT id FROM domain WHERE name = 'winston') WHERE name IN ('winston', 'viewer-all', 'viewer-winston', 'operator-all', 'operator-winston');

-- Insert roles for winston application
INSERT INTO role (name, enabled, domain_id, creator_id, description) VALUES
('viewer-all', TRUE, (SELECT id FROM domain WHERE name = 'root'), (SELECT id FROM user WHERE name = 'winston'), 'Role that can see all config entries but can modify none and permissions'),
('viewer-winston', TRUE, (SELECT id FROM domain WHERE name = 'winston'), (SELECT id FROM user WHERE name = 'winston'), 'Role that can see all config entries that relate to the winston application but can modify none and permissions'),
('operator-all', TRUE, (SELECT id FROM domain WHERE name = 'winston'), (SELECT id FROM user WHERE name = 'winston'), 'Role that can see and modify all config entries and permissions'),
('operator-winston', TRUE, (SELECT id FROM domain WHERE name = 'winston'), (SELECT id FROM user WHERE name = 'winston'), 'Role that can see and modify all config entries and permissions');

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
((SELECT id FROM user WHERE name = 'viewer-all'), (SELECT id FROM role WHERE name = 'viewer-all')),
((SELECT id FROM user WHERE name = 'viewer-winston'), (SELECT id FROM role WHERE name = 'viewer-winston')),
((SELECT id FROM user WHERE name = 'operator-all'), (SELECT id FROM role WHERE name = 'operator-all')),
((SELECT id FROM user WHERE name = 'operator-winston'), (SELECT id FROM role WHERE name = 'operator-winston')),
((SELECT id FROM user WHERE name = 'winston'), (SELECT id FROM role WHERE name = 'viewer-all')),
((SELECT id FROM user WHERE name = 'winston'), (SELECT id FROM role WHERE name = 'viewer-winston')),
((SELECT id FROM user WHERE name = 'winston'), (SELECT id FROM role WHERE name = 'operator-all')),
((SELECT id FROM user WHERE name = 'winston'), (SELECT id FROM role WHERE name = 'operator-winston'));

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

SET FOREIGN_KEY_CHECKS=1;