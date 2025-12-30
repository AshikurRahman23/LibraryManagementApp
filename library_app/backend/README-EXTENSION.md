# Extension Backend Endpoints

Two simple endpoints added to support the Chrome extension:

1) GET /check-book?title=BOOK_TITLE
- Response: { exists: true | false }
- Checks the `books` table for a case-insensitive partial match of the title.

2) POST /suggest-book
- Body: { title: string }
- Behavior: Saves a suggested book into `suggested_books` table and returns the saved row.

Database:
- A `suggested_books` table is created automatically on server startup (if it does not exist).
- Fields: `id`, `title`, `suggested_at`.

CORS / Access:
- The server already allows CORS from any origin, so the extension can call `http://localhost:3000`.

Run:
- Start backend: `npm run dev` or `node app.js` (depending on your project scripts)
- Ensure Postgres is running and `db.js` config matches your environment.
