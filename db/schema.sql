-- Database schema for Ebooksforlib

DROP TABLE IF EXISTS list_book;
DROP TABLE IF EXISTS lists;
DROP TABLE IF EXISTS user_roles;
DROP TABLE IF EXISTS user_libraries;
DROP TABLE IF EXISTS loans;
DROP TABLE IF EXISTS old_loans;
DROP TABLE IF EXISTS items;
DROP TABLE IF EXISTS files;
DROP TABLE IF EXISTS providers;

DROP TABLE IF EXISTS users;
CREATE TABLE users (
    id        INTEGER     AUTO_INCREMENT PRIMARY KEY,
    username  VARCHAR(32) NOT NULL       UNIQUE KEY,
    password  VARCHAR(64) NOT NULL,
    name      VARCHAR(255),
    email     VARCHAR(255), 
    anonymize INTEGER(1) DEFAULT 1, 
    hash      CHAR(64)   DEFAULT ''
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
    realm varchar(32)  UNIQUE KEY, 
    concurrent_loans INTEGER NOT NULL DEFAULT 1
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
    id       INTEGER AUTO_INCREMENT PRIMARY KEY,
    title    VARCHAR(255) NOT NULL, 
    date     VARCHAR(32) NOT NULL, 
    isbn     VARCHAR(64), 
    pages    VARCHAR(32),
    coverurl VARCHAR(255), 
    coverimg BLOB,
    dataurl  VARCHAR(255)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS creators;
CREATE TABLE creators (
    id      INTEGER AUTO_INCREMENT PRIMARY KEY,
    name    VARCHAR(255) NOT NULL, 
    dataurl VARCHAR(255)
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

CREATE TABLE files (
    id          INTEGER AUTO_INCREMENT PRIMARY KEY,
    book_id     INTEGER NOT NULL,
    provider_id INTEGER NOT NULL,
    library_id  INTEGER,
    file        LONGBLOB,
    updated     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE ( book_id, provider_id, library_id ), -- there should only be one file per book, provider and library
    CONSTRAINT files_fk_1 FOREIGN KEY (book_id)     REFERENCES books     (id) ON DELETE CASCADE,
    CONSTRAINT files_fk_2 FOREIGN KEY (provider_id) REFERENCES providers (id) ON DELETE CASCADE,
    CONSTRAINT files_fk_3 FOREIGN KEY (library_id)  REFERENCES libraries (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE items (
    id          INTEGER AUTO_INCREMENT PRIMARY KEY,
    library_id  INTEGER NOT NULL,
    file_id     INTEGER NOT NULL,
    loan_period INTEGER NOT NULL DEFAULT 0,
    deleted     INTEGER DEFAULT 0,
    CONSTRAINT items_fk_1 FOREIGN KEY (library_id)  REFERENCES libraries (id) ON DELETE CASCADE,
    CONSTRAINT items_fk_2 FOREIGN KEY (file_id)     REFERENCES files (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE loans (
    item_id INTEGER NOT NULL UNIQUE KEY, -- item_id should only occur once in this table at any one time
    user_id INTEGER NOT NULL,
    loaned  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    due     DATETIME DEFAULT NULL,
    PRIMARY KEY item_loan (item_id, user_id),
    CONSTRAINT loans_fk_1 FOREIGN KEY (item_id) REFERENCES items (id) ON DELETE CASCADE,
    CONSTRAINT loans_fk_2 FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE old_loans (
    id       INTEGER AUTO_INCREMENT PRIMARY KEY,
    item_id  INTEGER NOT NULL, -- item_id can occur more than once
    user_id  INTEGER NOT NULL,
    loaned   DATETIME NOT NULL,
    due      DATETIME NOT NULL,
    returned DATETIME NOT NULL,
    CONSTRAINT old_loans_fk_1 FOREIGN KEY (item_id) REFERENCES items (id) ON DELETE CASCADE,
    CONSTRAINT old_loans_fk_2 FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Sample data
-- TODO Split this out into a separate file

-- Roles
INSERT INTO roles SET id = 1, role = 'admin';
INSERT INTO roles SET id = 2, role = 'superadmin';

-- Users
INSERT INTO users SET id = 1, username = 'anon', name = 'anon';
INSERT INTO users SET id = 2, username = 'henrik', password = '{SSHA}naJx7DlkVcnRkTUm2sOzg5IsaYPfm76H', name = 'Henrik Ibsen', email = 'henrik@example.org';  -- password = pass
INSERT INTO users SET id = 3, username = 'sigrid', password = '{SSHA}qf4CXx0V8668B8QzYGcGpHdyBWEhCv55', name = 'Sigrid Undset', email = 'sigrid@example.org'; -- password = pass
INSERT INTO users SET id = 4, username = 'test1',  name = 'Test 1', email = 'test1@example.org'; -- password = pass
INSERT INTO users SET id = 5, username = 'test2',  name = 'Test 2', email = 'test2@example.org'; -- password = pass

-- Libraries
INSERT INTO libraries SET id = 1, name = 'Storevik', realm = 'storevik', concurrent_loans = 3;
INSERT INTO libraries SET id = 2, name = 'Lillevik', realm = 'lillevik', concurrent_loans = 4;

-- Users and roles
INSERT INTO user_roles SET user_id = 2, role_id = 1; -- Henrik is admin at Storevik
INSERT INTO user_roles SET user_id = 3, role_id = 2; -- Sigrid is superadmin, not connected to a library

-- Users and libraries
INSERT INTO user_libraries SET user_id = 2, library_id = 2;
INSERT INTO user_libraries SET user_id = 4, library_id = 2; 
INSERT INTO user_libraries SET user_id = 5, library_id = 2;

-- Books
INSERT INTO books SET id = 1, title = 'Vildanden',                        date = '1891', isbn = '8205004714',    pages = 123, coverurl = 'http://krydder.bib.no/0191/304730.bilde.1327468070.s.jpg';
INSERT INTO books SET id = 2, title = 'Tales From The Fjeld',             date = '1892', pages = 234;
INSERT INTO books SET id = 3, title = 'Three Men In A Boat',              date = '1893', isbn = '9788292465851', pages = 235, coverurl = 'http://krydder.bib.no/0783/9286428.bilde.1346774574.s.jpg';;
INSERT INTO books SET id = 4, title = 'War And Peace',                    date = '1894', isbn = '8256014369',    pages = 236, coverurl = 'http://krydder.bib.no/0416/827259.bilde.1327570239.s.jpg';;
INSERT INTO books SET id = 5, title = 'Three In Norway (by two of them)', date = '1895', isbn = '9788202289355', pages = 237, coverurl = 'http://krydder.bib.no/0008/994590.bilde.1327493563.s.jpg';;
INSERT INTO books SET id = 6, title = 'Peer Gynt',                        date = '1895', isbn = '8205054177',    pages = 238, coverurl = 'http://www.bokkilden.no/SamboWeb/servlet/VisBildeServlet?produktId=1869724';;

-- Providers
INSERT INTO providers SET id = 1, name = 'Provider A', description = 'This is our first provider.';
INSERT INTO providers SET id = 2, name = 'Provider B', description = 'This is our second provider.';

-- Files
-- Common files, not restricted to one library
INSERT INTO files SET id = 3,  book_id = 1, provider_id = 2;
-- Storevik
INSERT INTO files SET id = 1,  book_id = 1, provider_id = 1, library_id = 1;
INSERT INTO files SET id = 4,  book_id = 2, provider_id = 1, library_id = 1;
INSERT INTO files SET id = 5,  book_id = 3, provider_id = 1, library_id = 1;
INSERT INTO files SET id = 6,  book_id = 4, provider_id = 1, library_id = 1;
INSERT INTO files SET id = 7,  book_id = 5, provider_id = 1, library_id = 1;
INSERT INTO files SET id = 8,  book_id = 6, provider_id = 1, library_id = 1;
-- Lillevik
INSERT INTO files SET id = 9,  book_id = 1, provider_id = 1, library_id = 2;
INSERT INTO files SET id = 12, book_id = 2, provider_id = 1, library_id = 2;
INSERT INTO files SET id = 13, book_id = 3, provider_id = 1, library_id = 2;
INSERT INTO files SET id = 14, book_id = 4, provider_id = 1, library_id = 2;
INSERT INTO files SET id = 15, book_id = 5, provider_id = 1, library_id = 2;
INSERT INTO files SET id = 16, book_id = 6, provider_id = 1, library_id = 2;

-- Items
-- Storevik
INSERT INTO items SET id = 1,  library_id = 1, file_id = 1, loan_period = 7;
INSERT INTO items SET id = 2,  library_id = 1, file_id = 1, loan_period = 28;
INSERT INTO items SET id = 3,  library_id = 1, file_id = 3, loan_period = 5;
INSERT INTO items SET id = 4,  library_id = 1, file_id = 4, loan_period = 7;
INSERT INTO items SET id = 5,  library_id = 1, file_id = 5, loan_period = 7;
INSERT INTO items SET id = 6,  library_id = 1, file_id = 6, loan_period = 7;
INSERT INTO items SET id = 7,  library_id = 1, file_id = 7, loan_period = 7;
INSERT INTO items SET id = 8,  library_id = 1, file_id = 8, loan_period = 7;
-- Lillevik
INSERT INTO items SET id = 9,  library_id = 2, file_id = 9, loan_period = 7;
INSERT INTO items SET id = 10, library_id = 2, file_id = 9, loan_period = 28;
INSERT INTO items SET id = 11, library_id = 2, file_id = 3, loan_period = 5;
INSERT INTO items SET id = 12, library_id = 2, file_id = 12, loan_period = 7;
INSERT INTO items SET id = 13, library_id = 2, file_id = 13, loan_period = 7;
INSERT INTO items SET id = 14, library_id = 2, file_id = 14, loan_period = 7;
INSERT INTO items SET id = 15, library_id = 2, file_id = 15, loan_period = 7;
INSERT INTO items SET id = 16, library_id = 2, file_id = 16, loan_period = 7;
INSERT INTO items SET id = 17, library_id = 2, file_id = 16, loan_period = 7;
INSERT INTO items SET id = 18, library_id = 2, file_id = 16, loan_period = 7;
INSERT INTO items SET id = 19, library_id = 2, file_id = 13, loan_period = 28;
INSERT INTO items SET id = 20, library_id = 2, file_id = 13, loan_period = 28;
INSERT INTO items SET id = 21, library_id = 2, file_id = 13, loan_period = 28;

-- Loans
-- User: Test 1, Library: Lillevik
INSERT INTO loans SET item_id = 10, user_id = 4, loaned = NOW() - INTERVAL 21 DAY, due = NOW() + INTERVAL 7 DAY; -- borrowed 21 days ago, due in 7 days
INSERT INTO loans SET item_id = 14, user_id = 4, loaned = NOW(), due = NOW() + INTERVAL 7 DAY; -- borrowed now, due in 7 days
INSERT INTO loans SET item_id = 16, user_id = 4, loaned = NOW(), due = NOW() + INTERVAL 7 DAY; -- borrowed now, due in 7 days
INSERT INTO loans SET item_id = 19, user_id = 4, loaned = NOW(), due = NOW() + INTERVAL 28 DAY; -- borrowed now, due in 28 days
-- User: Test 2, Library: Lillevik
INSERT INTO loans SET item_id = 9,  user_id = 5, loaned = NOW() - INTERVAL 7 DAY, due = NOW(); -- borrowed 7 days ago, due now
INSERT INTO loans SET item_id = 13, user_id = 5, loaned = NOW(), due = NOW() + INTERVAL 7 DAY; -- borrowed now, due in 7 days
INSERT INTO loans SET item_id = 12, user_id = 5, loaned = NOW(), due = NOW() + INTERVAL 7 DAY; -- borrowed now, due in 7 days
INSERT INTO loans SET item_id = 20, user_id = 5, loaned = NOW(), due = NOW() + INTERVAL 28 DAY; -- borrowed now, due in 28 days

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
