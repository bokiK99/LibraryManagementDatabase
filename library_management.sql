-- Library Management Database (Microsoft SQL Server / T-SQL)
-- Run in a NEW, EMPTY database using SSMS or Azure Data Studio.
-- All people, contact details, publishers and book titles below are fictional.

CREATE TABLE dbo.countries (
    id INT NOT NULL CONSTRAINT PK_countries PRIMARY KEY,
    name VARCHAR(30) NOT NULL
);

CREATE TABLE dbo.publishers (
    id INT NOT NULL CONSTRAINT PK_publishers PRIMARY KEY,
    name VARCHAR(30) NOT NULL
);

CREATE TABLE dbo.categories (
    id INT NOT NULL CONSTRAINT PK_categories PRIMARY KEY,
    name VARCHAR(30) NOT NULL
);

CREATE TABLE dbo.members (
    id INT NOT NULL CONSTRAINT PK_members PRIMARY KEY,
    first_name VARCHAR(20) NOT NULL,
    gender CHAR(1) CONSTRAINT DF_members_gender DEFAULT 'M',
    last_name VARCHAR(20) NOT NULL,
    address VARCHAR(50),
    phone_number VARCHAR(15),
    membership_paid DECIMAL(5,2) CONSTRAINT DF_members_membership_paid DEFAULT 0
);

CREATE TABLE dbo.authors (
    id INT NOT NULL CONSTRAINT PK_authors PRIMARY KEY,
    first_name VARCHAR(20) NOT NULL,
    last_name VARCHAR(20) NOT NULL,
    birth_date DATE,
    death_date DATE,
    country_id INT,
    CONSTRAINT FK_authors_countries FOREIGN KEY (country_id) REFERENCES dbo.countries(id)
);

CREATE TABLE dbo.books (
    id INT NOT NULL CONSTRAINT PK_books PRIMARY KEY,
    title VARCHAR(50) NOT NULL,
    total_copies INT NOT NULL CONSTRAINT CK_books_copies CHECK (total_copies >= 0),
    publication_year INT,
    publisher_id INT,
    CONSTRAINT FK_books_publishers FOREIGN KEY (publisher_id) REFERENCES dbo.publishers(id)
);

CREATE TABLE dbo.loans (
    id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_loans PRIMARY KEY,
    borrowed_at DATETIME NOT NULL,
    returned_at DATETIME,
    amount_paid DECIMAL(5,2),
    member_id INT NOT NULL,
    book_id INT NOT NULL,
    CONSTRAINT FK_loans_members FOREIGN KEY (member_id) REFERENCES dbo.members(id),
    CONSTRAINT FK_loans_books FOREIGN KEY (book_id) REFERENCES dbo.books(id)
);

CREATE TABLE dbo.book_categories (
    book_id INT NOT NULL,
    category_id INT NOT NULL,
    CONSTRAINT PK_book_categories PRIMARY KEY (book_id, category_id),
    CONSTRAINT FK_book_categories_books FOREIGN KEY (book_id) REFERENCES dbo.books(id),
    CONSTRAINT FK_book_categories_categories FOREIGN KEY (category_id) REFERENCES dbo.categories(id)
);

CREATE TABLE dbo.author_books (
    author_id INT NOT NULL,
    book_id INT NOT NULL,
    CONSTRAINT PK_author_books PRIMARY KEY (book_id, author_id),
    CONSTRAINT FK_author_books_authors FOREIGN KEY (author_id) REFERENCES dbo.authors(id),
    CONSTRAINT FK_author_books_books FOREIGN KEY (book_id) REFERENCES dbo.books(id)
);
GO

-- Fictional seed data
INSERT INTO dbo.countries (id, name) VALUES (1, 'Germany'), (2, 'United States'), (3, 'United Kingdom');
INSERT INTO dbo.publishers (id, name) VALUES (1, 'Northbridge Press'), (2, 'Maple Leaf Books');
INSERT INTO dbo.categories (id, name) VALUES (1, 'Fiction'), (2, 'Mystery'), (3, 'Science Fiction');
INSERT INTO dbo.authors (id, first_name, last_name, birth_date, death_date, country_id) VALUES
    (1, 'Max', 'Mustermann', '1980-05-12', NULL, 1),
    (2, 'Jane', 'Doe', '1975-09-23', NULL, 2),
    (3, 'Alex', 'Smith', '1988-03-08', NULL, 3);
INSERT INTO dbo.books (id, title, total_copies, publication_year, publisher_id) VALUES
    (1, 'The Quiet Library', 8, 2021, 1),
    (2, 'Mystery on Oak Street', 5, 2022, 2),
    (3, 'Beyond the Blue Horizon', 6, 2023, 1);
INSERT INTO dbo.author_books (author_id, book_id) VALUES (1, 1), (2, 2), (3, 3);
INSERT INTO dbo.book_categories (book_id, category_id) VALUES (1, 1), (2, 2), (3, 3);
INSERT INTO dbo.members (id, first_name, gender, last_name, address, phone_number, membership_paid) VALUES
    (1, 'John', 'M', 'Doe', 'Example Street 10', '000-000-0001', 0),
    (2, 'Erika', 'F', 'Mustermann', 'Example Avenue 20', '000-000-0002', 0),
    (3, 'Sam', 'M', 'Taylor', 'Sample Road 30', '000-000-0003', 0);
INSERT INTO dbo.loans (borrowed_at, returned_at, amount_paid, member_id, book_id) VALUES
    ('2025-04-01', '2025-04-10', 0, 1, 1),
    ('2025-04-03', NULL, 0, 2, 2),
    ('2025-04-05', NULL, 0, 3, 3),
    ('2025-04-08', '2025-04-18', 0, 1, 2);
GO

CREATE FUNCTION dbo.AVAILABLE_COPIES(@id INT)
RETURNS INT
AS
BEGIN
    DECLARE @total_copies INT;
    DECLARE @borrowed_count INT;
    SELECT @total_copies = total_copies FROM dbo.books WHERE id = @id;
    SELECT @borrowed_count = COUNT(*) FROM dbo.loans
    WHERE book_id = @id AND returned_at IS NULL;
    RETURN @total_copies - @borrowed_count;
END;
GO

CREATE FUNCTION dbo.AUTHOR_BOOK_COUNT(@id INT)
RETURNS INT
AS
BEGIN
    DECLARE @book_count INT;
    SELECT @book_count = COUNT(*) FROM dbo.author_books WHERE author_id = @id;
    RETURN @book_count;
END;
GO

CREATE FUNCTION dbo.MOST_BORROWED_BOOK()
RETURNS VARCHAR(50)
AS
BEGIN
    DECLARE @book_title VARCHAR(50);
    SELECT TOP (1) @book_title = k.title
    FROM dbo.books AS k JOIN dbo.loans AS p ON p.book_id = k.id
    GROUP BY k.id, k.title
    ORDER BY COUNT(*) DESC, k.title ASC;
    RETURN @book_title;
END;
GO

CREATE VIEW dbo.ALL_BOOKS
AS
SELECT a.id AS Author_ID,
       a.first_name + ' ' + a.last_name AS Author,
       k.title AS Book,
       k.total_copies AS Total_Copies,
       dbo.AVAILABLE_COPIES(k.id) AS Available_Copies
FROM dbo.author_books AS ak
JOIN dbo.authors AS a ON a.id = ak.author_id
JOIN dbo.books AS k ON k.id = ak.book_id;
GO

CREATE VIEW dbo.MEMBER_LOANS
AS
SELECT c.first_name + ' ' + c.last_name AS Member,
       p.id AS Loan_ID,
       p.borrowed_at AS Borrowed_At,
       p.returned_at AS Returned_At,
       k.title AS Book
FROM dbo.loans AS p
JOIN dbo.members AS c ON c.id = p.member_id
JOIN dbo.books AS k ON k.id = p.book_id;
GO

CREATE PROCEDURE dbo.GET_MEMBER_LOANS @MEMBER_ID INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT c.first_name + ' ' + c.last_name AS member_name,
           p.id, p.borrowed_at AS borrowed_at,
           p.returned_at AS returned_at, p.amount_paid
    FROM dbo.loans AS p
    JOIN dbo.members AS c ON c.id = p.member_id
    WHERE p.member_id = @MEMBER_ID
    ORDER BY p.borrowed_at;
END;
GO

CREATE PROCEDURE dbo.GET_UNRETURNED_BOOKS
AS
BEGIN
    SET NOCOUNT ON;
    SELECT c.first_name + ' ' + c.last_name AS member_name,
           k.title AS Book, p.borrowed_at AS Borrowed_At
    FROM dbo.loans AS p
    JOIN dbo.members AS c ON c.id = p.member_id
    JOIN dbo.books AS k ON k.id = p.book_id
    WHERE p.returned_at IS NULL
    ORDER BY p.borrowed_at;
END;
GO

CREATE PROCEDURE dbo.BORROW_BOOK @MEMBER_ID INT, @BOOK_ID INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRANSACTION;
    -- Serialize loans for the same book to avoid exceeding available copies.
    IF NOT EXISTS (SELECT 1 FROM dbo.members WHERE id = @MEMBER_ID)
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50001, 'Member does not exist.', 1;
    END;
    IF NOT EXISTS (SELECT 1 FROM dbo.books WITH (UPDLOCK, HOLDLOCK)
                   WHERE id = @BOOK_ID)
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50002, 'Book does not exist.', 1;
    END;
    IF dbo.AVAILABLE_COPIES(@BOOK_ID) <= 0
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50003, 'No copies are available.', 1;
    END;
    INSERT INTO dbo.loans (member_id, book_id, borrowed_at, amount_paid)
    VALUES (@MEMBER_ID, @BOOK_ID, GETDATE(), 0);
    COMMIT TRANSACTION;
END;
GO

CREATE PROCEDURE dbo.RETURN_BOOK @LOAN_ID INT, @AMOUNT_PAID DECIMAL(5,2)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.loans
    SET returned_at = GETDATE(), amount_paid = @AMOUNT_PAID
    WHERE id = @LOAN_ID AND returned_at IS NULL;
END;
GO

CREATE PROCEDURE dbo.REPORT_LOST_BOOK @LOAN_ID INT, @AMOUNT_PAID DECIMAL(5,2)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRANSACTION;
    DECLARE @BOOK_ID_LOCAL INT;
    SELECT @BOOK_ID_LOCAL = book_id FROM dbo.loans WITH (UPDLOCK, HOLDLOCK)
    WHERE id = @LOAN_ID AND returned_at IS NULL;
    IF @BOOK_ID_LOCAL IS NULL
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50004, 'An active loan with this ID does not exist.', 1;
    END;
    -- Close the loan and reduce total inventory by one lost copy.
    UPDATE dbo.loans SET returned_at = GETDATE(), amount_paid = @AMOUNT_PAID WHERE id = @LOAN_ID;
    UPDATE dbo.books SET total_copies = total_copies - 1 WHERE id = @BOOK_ID_LOCAL;
    COMMIT TRANSACTION;
END;
GO

CREATE PROCEDURE dbo.DELETE_MEMBER @MEMBER_ID INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    DELETE FROM dbo.loans WHERE member_id = @MEMBER_ID;
    DELETE FROM dbo.members WHERE id = @MEMBER_ID;
    COMMIT TRANSACTION;
END;
GO

CREATE PROCEDURE dbo.DELETE_LOAN @LOAN_ID INT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM dbo.loans WHERE id = @LOAN_ID;
END;
GO

CREATE PROCEDURE dbo.DELETE_AUTHOR @AUTHOR_ID INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    DELETE FROM dbo.author_books WHERE author_id = @AUTHOR_ID;
    DELETE FROM dbo.authors WHERE id = @AUTHOR_ID;
    COMMIT TRANSACTION;
END;
GO

-- Optional examples (run manually; do not execute destructive actions by default):
-- SELECT * FROM dbo.ALL_BOOKS ORDER BY Author_ID;
-- SELECT * FROM dbo.MEMBER_LOANS ORDER BY Member;
-- SELECT dbo.AVAILABLE_COPIES(1) AS AvailableCopies;
-- SELECT dbo.AUTHOR_BOOK_COUNT(1) AS BooksByAuthor;
-- SELECT dbo.MOST_BORROWED_BOOK() AS MostBorrowedBook;
-- EXEC dbo.GET_MEMBER_LOANS @MEMBER_ID = 1;
-- EXEC dbo.GET_UNRETURNED_BOOKS;
-- EXEC dbo.BORROW_BOOK @MEMBER_ID = 1, @BOOK_ID = 1;
-- EXEC dbo.RETURN_BOOK @LOAN_ID = 2, @AMOUNT_PAID = 0;
-- EXEC dbo.REPORT_LOST_BOOK @LOAN_ID = 3, @AMOUNT_PAID = 25;
-- EXEC dbo.DELETE_LOAN @LOAN_ID = 1;
-- EXEC dbo.DELETE_MEMBER @MEMBER_ID = 3;
-- EXEC dbo.DELETE_AUTHOR @AUTHOR_ID = 3;
