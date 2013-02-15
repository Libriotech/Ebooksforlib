-- Database schema for Ebooksforlib

DROP TABLE IF EXISTS user_roles;
DROP TABLE IF EXISTS user_libraries;

DROP TABLE IF EXISTS users;
CREATE TABLE users (
    id       INTEGER     AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(32) NOT NULL       UNIQUE KEY,
    password VARCHAR(64) NOT NULL,
    name     VARCHAR(255),
    email    VARCHAR(255) 
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS roles;
CREATE TABLE roles (
    id    INTEGER     AUTO_INCREMENT PRIMARY KEY,
    role  VARCHAR(32) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS libraries;
CREATE TABLE libraries (
    id    INTEGER AUTO_INCREMENT PRIMARY KEY,
    name  VARCHAR(255) UNIQUE KEY NOT NULL,
    realm varchar(32)  UNIQUE KEY 
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE user_roles (
    user_id    INTEGER NOT NULL,
    role_id    INTEGER NOT NULL,
    PRIMARY KEY user_role (user_id, role_id), 
    CONSTRAINT user_roles_fk_1 FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
    CONSTRAINT user_roles_fk_2 FOREIGN KEY (role_id) REFERENCES roles (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE user_libraries (
    user_id    INTEGER NOT NULL,
    library_id INTEGER NOT NULL,
    PRIMARY KEY user_library (user_id, library_id),
    CONSTRAINT user_libraries_fk_1 FOREIGN KEY (user_id)    REFERENCES users     (id) ON DELETE CASCADE,
    CONSTRAINT user_libraries_fk_2 FOREIGN KEY (library_id) REFERENCES libraries (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS book_creators;
DROP TABLE IF EXISTS books;
CREATE TABLE books (
    id      INTEGER AUTO_INCREMENT PRIMARY KEY,
    title   VARCHAR(255) NOT NULL, 
    date    VARCHAR(32) NOT NULL, 
    isbn    VARCHAR(64)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS creators;
CREATE TABLE creators (
    id      INTEGER AUTO_INCREMENT PRIMARY KEY,
    name    VARCHAR(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE book_creators (
    book_id    INTEGER NOT NULL,
    creator_id INTEGER NOT NULL,
    PRIMARY KEY book_creator (book_id, creator_id), 
    CONSTRAINT book_creators_fk_1 FOREIGN KEY (book_id)    REFERENCES books    (id) ON DELETE CASCADE,
    CONSTRAINT book_creators_fk_2 FOREIGN KEY (creator_id) REFERENCES creators (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Sample data
-- TODO Split this out into a separate file

-- Roles
INSERT INTO roles SET id = 1, role = 'admin';
INSERT INTO roles SET id = 2, role = 'superadmin';

-- Users
INSERT INTO users SET id = 1, username = 'henrik', password = '{SSHA}naJx7DlkVcnRkTUm2sOzg5IsaYPfm76H', name = 'Henrik Ibsen', email = 'henrik@example.org';  -- password = pass
INSERT INTO users SET id = 2, username = 'sigrid', password = '{SSHA}qf4CXx0V8668B8QzYGcGpHdyBWEhCv55', name = 'Sigrid Undset', email = 'sigrid@example.org'; -- password = pass

-- Libraries
INSERT INTO libraries SET id = 1, name = 'Storevik', realm = 'storevik';
INSERT INTO libraries SET id = 2, name = 'Lillevik';

-- Users and roles
INSERT INTO user_roles SET user_id = 1, role_id = 1; -- Henrik is admin at Storevik
INSERT INTO user_roles SET user_id = 2, role_id = 2; -- Sigrid is superadmin, not connected to a library

-- Users and libraries
INSERT INTO user_libraries SET user_id = 1, library_id = 1;

-- Books
INSERT INTO books SET id = 1, title = 'Vildanden',                        date = '1891', isbn = '9780123456789';
INSERT INTO books SET id = 2, title = 'Tales From The Fjeld',             date = '1892', isbn = '9780123456788';
INSERT INTO books SET id = 3, title = 'Three Men In A Boat',              date = '1893', isbn = '9780123456787';
INSERT INTO books SET id = 4, title = 'War And Peace',                    date = '1894', isbn = '9780123456786';
INSERT INTO books SET id = 5, title = 'Three In Norway (by two of them)', date = '1895', isbn = '9780123456785';
INSERT INTO books SET id = 6, title = 'Peer Gynt',                        date = '1895', isbn = '9780123456784';

-- Creators
INSERT INTO creators SET id = 1, name = 'Henrik J. Ibsen';
INSERT INTO creators SET id = 2, name = 'Peter Christian J. Asbjørnsen';
INSERT INTO creators SET id = 3, name = 'Jørgen J. Moe';
INSERT INTO creators SET id = 4, name = 'Jerome K. Jerome';
INSERT INTO creators SET id = 5, name = 'Count Leo J. Tolstoy';
INSERT INTO creators SET id = 6, name = 'J.A. Lees';
INSERT INTO creators SET id = 7, name = 'W.J. Clutterbuck';

-- Book-creators
INSERT INTO book_creators SET book_id = 1, creator_id = 1;
INSERT INTO book_creators SET book_id = 2, creator_id = 2;
INSERT INTO book_creators SET book_id = 2, creator_id = 3;
INSERT INTO book_creators SET book_id = 3, creator_id = 4;
INSERT INTO book_creators SET book_id = 4, creator_id = 5;
INSERT INTO book_creators SET book_id = 5, creator_id = 6;
INSERT INTO book_creators SET book_id = 5, creator_id = 7;
INSERT INTO book_creators SET book_id = 6, creator_id = 1;
