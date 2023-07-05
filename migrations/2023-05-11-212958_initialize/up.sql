-- ########## 1. TABLES ##########

-- START user
CREATE TABLE IF NOT EXISTS user (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    'name'          VARCHAR(64) NOT NULL,
    'enabled'       BOOLEAN NOT NULL DEFAULT 'false',
    creator_id      INTEGER NOT NULL REFERENCES user(id),
    created         DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated         DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    description     VARCHAR(255) DEFAULT NULL
);

-- Insert default users
INSERT INTO user (id, 'name', 'enabled', creator_id, description) VALUES (0, 'root', 'false', 0, 'Root user');
INSERT INTO user (id, 'name', 'enabled', creator_id, description) VALUES (1, 'winston', 'true', 0, 'Winson application root user');

-- END user

-- START environment
CREATE TABLE IF NOT EXISTS environment (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    'name'          VARCHAR(64) NOT NULL,
    shorthand       VARCHAR(8) NOT NULL,
    'enabled'       BOOLEAN NOT NULL DEFAULT 0,
    creator_id      INTEGER NOT NULL REFERENCES user(id),
    created         DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated         DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    description     VARCHAR(255) DEFAULT NULL
);

-- Insert environments
INSERT INTO environment (id, 'name', shorthand, 'enabled', creator_id, description) VALUES (0, 'development', 'dev', 1, 0, 'Development environment');
INSERT INTO environment (id, 'name', shorthand, 'enabled', creator_id, description) VALUES (1, 'integration', 'int', 0, 0, 'Integration environment');
INSERT INTO environment (id, 'name', shorthand, 'enabled', creator_id, description) VALUES (2, 'production', 'prod', 0, 0, 'Production environment');
-- END environment

-- START domain
CREATE TABLE IF NOT EXISTS domain (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    'name'          VARCHAR(64) NOT NULL,
    'enabled'       BOOLEAN NOT NULL DEFAULT 0,
    creator_id      INTEGER NOT NULL REFERENCES user(id),
    environment_id  INTEGER NOT NULL REFERENCES environment(id),
    created         DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated         DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    description     VARCHAR(255) DEFAULT NULL,
    parent_id       INTEGER NOT NULL DEFAULT 0 REFERENCES domain(id),
    owner_id        INTEGER NOT NULL REFERENCES user(id)
);

-- Insert domains
INSERT INTO domain (id, 'name', creator_id, environment_id, description, parent_id, owner_id) VALUES (0, 'root', 0, 0, 'Root node of the domain tree', 0, 0);
INSERT INTO domain (id, 'name', creator_id, environment_id, description, parent_id, owner_id) VALUES (1, 'winston', 1, 0, 'Root node of the winston application domain branch', 0, 1);
INSERT INTO domain (id, 'name', creator_id, environment_id, description, parent_id, owner_id) VALUES (2, 'service', 1, 0, 'Domain of the winston service application', 1, 1);
INSERT INTO domain (id, 'name', creator_id, environment_id, description, parent_id, owner_id) VALUES (3, 'web', 1, 0, 'Domain of the winston client web application', 1, 1);
-- END domain

-- START config
CREATE TABLE IF NOT EXISTS config (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    'name'          VARCHAR(64) NOT NULL,
    'enabled'       BOOLEAN NOT NULL DEFAULT 0,
    domain_id       INTEGER NOT NULL REFERENCES domain(id),     -- The domain a config entry lives in
    target_id       INTEGER NOT NULL REFERENCES domain(id),     -- The domain a config entry refers to
    creator_id      INTEGER NOT NULL REFERENCES user(id),
    created         DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated         DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    'value'         VARCHAR(255) DEFAULT NULL,
    description     VARCHAR(255) DEFAULT NULL
);

-- Insert default config
INSERT INTO config ('name', 'enabled', domain_id, target_id, creator_id, value, description) VALUES ('domain_separator', 'true', 2, 0, 1, '.', 'Declares the character that separates domains');

-- END config

-- ########## 2. Relations ##########
ALTER TABLE user ADD COLUMN domain_id INTEGER NOT NULL DEFAULT 0 REFERENCES domain(id);