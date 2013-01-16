-- Database schema for Ebooksforlib

DROP TABLE IF EXISTS user_roles;
DROP TABLE IF EXISTS users;
CREATE TABLE users (
    id       INTEGER     AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(32) NOT NULL       UNIQUE KEY,
    password VARCHAR(32) NOT NULL, 
    name     VARCHAR(255) 
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS roles;
CREATE TABLE roles (
    id    INTEGER     AUTO_INCREMENT PRIMARY KEY,
    role  VARCHAR(32) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE user_roles (
    user_id  INTEGER NOT NULL,
    role_id  INTEGER NOT NULL,
    PRIMARY KEY user_role (user_id, role_id), 
    CONSTRAINT user_roles_fk_1 FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
    CONSTRAINT user_roles_fk_2 FOREIGN KEY (role_id) REFERENCES roles (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Sample data

INSERT INTO users SET id = 1, username = 'admin', password = 'pass', name = 'Henrik Ibsen';
INSERT INTO roles SET id = 1, role = 'admin';
INSERT INTO user_roles SET user_id = 1, role_id = 1;
