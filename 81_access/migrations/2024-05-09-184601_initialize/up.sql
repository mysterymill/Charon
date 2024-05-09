-- ########## 0. CLEAN ##########

SET FOREIGN_KEY_CHECKS=0;
DROP TABLE IF EXISTS user;
DROP TABLE IF EXISTS domain;
DROP TABLE IF EXISTS config;
DROP TABLE IF EXISTS environment;

SET FOREIGN_KEY_CHECKS=1;

-- ########## 1. TABLES ##########

-- START user
CREATE TABLE IF NOT EXISTS user (
    id              INTEGER UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    name            VARCHAR(64)NOT NULL,
    enabled         BOOLEAN NOT NULL DEFAULT FALSE,
    creator_id      INTEGER UNSIGNED NOT NULL REFERENCES user(id),
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
    domain_id       INTEGER UNSIGNED NOT NULL REFERENCES domain(id),     -- The domain a config entry lives in
    target_id       INTEGER UNSIGNED NOT NULL REFERENCES domain(id),     -- The domain a config entry refers to
    creator_id      INTEGER UNSIGNED NOT NULL REFERENCES user(id),
    created         DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated         DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    value           VARCHAR(255) DEFAULT NULL,
    description     VARCHAR(255) DEFAULT NULL
);
-- END config

-- ########## 2. Relations ##########
ALTER TABLE user ADD COLUMN domain_id INTEGER UNSIGNED NOT NULL DEFAULT 0 REFERENCES domain(id);

-- ########## 3. Inserts ##########
SET FOREIGN_KEY_CHECKS=0;
-- Insert default users
INSERT INTO user (name, enabled, creator_id, description, domain_id) VALUES ('root', FALSE, 1, 'Root user', 0);
INSERT INTO user (name, enabled, creator_id, description, domain_id) VALUES ('winston', TRUE, 1, 'Winston application root user', 0);
UPDATE user SET creator_id = (SELECT id FROM user WHERE name = 'root') WHERE 1 = 1;


-- Insert environments
INSERT INTO environment (name, shorthand, enabled, creator_id, description) VALUES ('development', 'dev', TRUE, (SELECT id FROM user WHERE name = 'root'), 'Development environment');
INSERT INTO environment (name, shorthand, enabled, creator_id, description) VALUES ('integration', 'int', FALSE, (SELECT id FROM user WHERE name = 'root'), 'Integration environment');
INSERT INTO environment (name, shorthand, enabled, creator_id, description) VALUES ('production', 'prod', FALSE, (SELECT id FROM user WHERE name = 'root'), 'Production environment');

-- Insert domains
INSERT INTO domain (name, creator_id, environment_id, description, parent_id, owner_id) VALUES ('root', (SELECT id FROM user WHERE name = 'root'), (SELECT id FROM environment WHERE shorthand = 'dev'), 'Root node of the domain tree', 0, 0);
INSERT INTO domain (name, creator_id, environment_id, description, parent_id, owner_id) VALUES ('winston', (SELECT id FROM user WHERE name = 'winston'), (SELECT id FROM environment WHERE shorthand = 'dev'), 'Root node of the winston application domain branch', 0, 1);

UPDATE domain SET parent_id = (SELECT id FROM domain WHERE name = 'root'), owner_id = (SELECT id FROM user WHERE name = 'root') WHERE name = 'root';
UPDATE domain SET parent_id = (SELECT id FROM domain WHERE name = 'root'), owner_id = (SELECT id FROM user WHERE name = 'winston') WHERE name = 'winston';

INSERT INTO domain (name, creator_id, environment_id, description, parent_id, owner_id)
VALUES ('service', (SELECT id FROM user WHERE name = 'winston'), (SELECT id FROM environment WHERE shorthand = 'dev'), 'Domain of the winston service application', 0, (SELECT id FROM user WHERE name = 'winston'));
INSERT INTO domain (name, creator_id, environment_id, description, parent_id, owner_id)
VALUES ('web', (SELECT id FROM user WHERE name = 'winston'), (SELECT id FROM environment WHERE shorthand = 'dev'), 'Domain of the winston client web application', 0, (SELECT id FROM user WHERE name = 'winston'));

UPDATE domain SET parent_id = (SELECT id FROM domain WHERE name = 'winston') WHERE name = 'service';
UPDATE domain SET parent_id = (SELECT id FROM domain WHERE name = 'winston') WHERE name = 'web';
-- END domain

-- Insert default config
INSERT INTO config (name, enabled, domain_id, target_id, creator_id, value, description) VALUES ('domain_separator', TRUE, (SELECT id FROM domain WHERE name = 'service'), (SELECT id FROM domain WHERE name = 'winston'), (SELECT id FROM user WHERE name = 'winston'), '.', 'Declares the character that separates domains');

UPDATE user SET domain_id = (SELECT id FROM domain WHERE name = 'root') WHERE name = 'root';
UPDATE user SET domain_id = (SELECT id FROM domain WHERE name = 'winston') WHERE name = 'winston';
SET FOREIGN_KEY_CHECKS=1;