-- Database schema for Ebooksforlib

DROP TABLE IF EXISTS list_book;
DROP TABLE IF EXISTS lists;
DROP TABLE IF EXISTS user_roles;
DROP TABLE IF EXISTS user_libraries;
DROP TABLE IF EXISTS items;
DROP TABLE IF EXISTS providers;
DROP TABLE IF EXISTS loans;

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

CREATE TABLE lists (
    id         INTEGER AUTO_INCREMENT PRIMARY KEY,
    name       VARCHAR(255) NOT NULL,
    library_id INTEGER NOT NULL,
    is_genre   INTEGER(1) DEFAULT 0,
    CONSTRAINT lists_fk_1 FOREIGN KEY (library_id) REFERENCES libraries (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE list_book (
    book_id    INTEGER NOT NULL,
    list_id    INTEGER NOT NULL,
    PRIMARY KEY list_book (book_id, list_id), 
    CONSTRAINT list_book_fk_1 FOREIGN KEY (book_id) REFERENCES books (id) ON DELETE CASCADE,
    CONSTRAINT list_book_fk_2 FOREIGN KEY (list_id) REFERENCES lists (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE providers (
    id          INTEGER AUTO_INCREMENT PRIMARY KEY,
    name        VARCHAR(255) NOT NULL, 
    description TEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE items (
    id          INTEGER AUTO_INCREMENT PRIMARY KEY,
    book_id     INTEGER NOT NULL,
    library_id  INTEGER NOT NULL,
    provider_id INTEGER NOT NULL,
    loan_period INTEGER NOT NULL DEFAULT 0,
    CONSTRAINT items_fk_1 FOREIGN KEY (book_id)     REFERENCES books     (id) ON DELETE CASCADE,
    CONSTRAINT items_fk_2 FOREIGN KEY (library_id)  REFERENCES libraries (id) ON DELETE CASCADE, 
    CONSTRAINT items_fk_3 FOREIGN KEY (provider_id) REFERENCES providers (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE loans (
    id      INTEGER AUTO_INCREMENT PRIMARY KEY,
    item_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    loaned  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    due     DATETIME DEFAULT NULL,
    CONSTRAINT loans_fk_1 FOREIGN KEY (item_id) REFERENCES items (id) ON DELETE CASCADE,
    CONSTRAINT loans_fk_2 FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
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

-- Providers
INSERT INTO providers SET id = 1, name = 'Provider A', description = 'This is our first provider.';
INSERT INTO providers SET id = 2, name = 'Provider B', description = 'This is our second provider.';

-- Items
INSERT INTO items SET id = 1,  book_id = 1, library_id = 1, provider_id = 1, loan_period = 7;
INSERT INTO items SET id = 2,  book_id = 1, library_id = 1, provider_id = 1, loan_period = 7;
INSERT INTO items SET id = 3,  book_id = 1, library_id = 1, provider_id = 2, loan_period = 5;
INSERT INTO items SET id = 4,  book_id = 2, library_id = 1, provider_id = 1, loan_period = 7;
INSERT INTO items SET id = 5,  book_id = 3, library_id = 1, provider_id = 1, loan_period = 7;
INSERT INTO items SET id = 6,  book_id = 4, library_id = 1, provider_id = 1, loan_period = 7;
INSERT INTO items SET id = 7,  book_id = 5, library_id = 1, provider_id = 1, loan_period = 7;
INSERT INTO items SET id = 8,  book_id = 6, library_id = 1, provider_id = 1, loan_period = 7;
INSERT INTO items SET id = 9,  book_id = 1, library_id = 2, provider_id = 1, loan_period = 7;
INSERT INTO items SET id = 10, book_id = 1, library_id = 2, provider_id = 2, loan_period = 7;
INSERT INTO items SET id = 11, book_id = 2, library_id = 2, provider_id = 1, loan_period = 7;
INSERT INTO items SET id = 12, book_id = 5, library_id = 2, provider_id = 1, loan_period = 7;
INSERT INTO items SET id = 13, book_id = 6, library_id = 2, provider_id = 1, loan_period = 7;

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

-- Lists
INSERT INTO lists SET id = 1, name = 'Classics',          library_id = 1, is_genre = 1;
INSERT INTO lists SET id = 2, name = 'Humour',            library_id = 1, is_genre = 1;
INSERT INTO lists SET id = 3, name = 'Easter reading',    library_id = 1, is_genre = 0;
INSERT INTO lists SET id = 4, name = 'Henrik recommends', library_id = 1, is_genre = 0;
INSERT INTO lists SET id = 5, name = 'Funny stuff',       library_id = 2, is_genre = 1;
INSERT INTO lists SET id = 6, name = 'Travel',            library_id = 2, is_genre = 1;

-- Books in lists
INSERT INTO list_book SET list_id = 1, book_id = 1;
INSERT INTO list_book SET list_id = 1, book_id = 2;
INSERT INTO list_book SET list_id = 1, book_id = 4;
INSERT INTO list_book SET list_id = 1, book_id = 6;
INSERT INTO list_book SET list_id = 2, book_id = 3;
INSERT INTO list_book SET list_id = 2, book_id = 5;
INSERT INTO list_book SET list_id = 3, book_id = 1;
INSERT INTO list_book SET list_id = 3, book_id = 5;
INSERT INTO list_book SET list_id = 4, book_id = 2;
INSERT INTO list_book SET list_id = 4, book_id = 3;
INSERT INTO list_book SET list_id = 5, book_id = 3;
INSERT INTO list_book SET list_id = 5, book_id = 5;
INSERT INTO list_book SET list_id = 6, book_id = 5;
