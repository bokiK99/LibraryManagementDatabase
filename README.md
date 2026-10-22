# Library Management Database

A small **Microsoft SQL Server (T-SQL)** project demonstrating a relational database for managing a library's books, authors, publishers, members, and book loans. It includes sample data, relationships, views, functions, and stored procedures.

## Features

- Manage books, authors, publishers, categories, countries, and library members.
- Link books to multiple authors and categories.
- Record borrowed and returned books and track available copies.
- List active loans and individual members' borrowing history.
- Calculate an author's book count and the most frequently borrowed book.
- Handle loan creation, returns, lost copies, and record removal through stored procedures.

## Database structure

| Table | Purpose |
| --- | --- |
| `members` | Library members |
| `books` | Books and their inventory |
| `authors` | Authors |
| `publishers` | Publishers |
| `countries` | Countries associated with authors |
| `categories` | Book categories |
| `loans` | Book loans |
| `author_books` | Many-to-many relationship between authors and books |
| `book_categories` | Many-to-many relationship between books and categories |

The SQL file also defines the views `ALL_BOOKS` and `MEMBER_LOANS`; functions `AVAILABLE_COPIES`, `AUTHOR_BOOK_COUNT`, and `MOST_BORROWED_BOOK`; and stored procedures for loan and record management.

## Getting started

1. Install or access **Microsoft SQL Server** and a SQL editor such as **SQL Server Management Studio (SSMS)**.
2. Create a **new, empty database** (for example, `LibraryDB`).
3. Open `library_management.sql`, select the new database, and execute the script.
4. Run the example queries below to explore the records.

```sql
SELECT * FROM dbo.ALL_BOOKS;
SELECT * FROM dbo.MEMBER_LOANS;
SELECT dbo.AVAILABLE_COPIES(1) AS AvailableCopies;
EXEC dbo.GET_UNRETURNED_BOOKS;
EXEC dbo.GET_MEMBER_LOANS @MEMBER_ID = 1;
```

To create a new loan:

```sql
EXEC dbo.BORROW_BOOK @MEMBER_ID = 1, @BOOK_ID = 1;
```

> **Note:** This is a learning/demo project, not a production-ready library system. Its sample names, addresses, publishers, and book titles are fictional. The setup script is intended to run once in an empty database.

## Technologies

- Microsoft SQL Server
- Transact-SQL (T-SQL): primary/foreign keys, joins, constraints, views, scalar functions, and stored procedures
