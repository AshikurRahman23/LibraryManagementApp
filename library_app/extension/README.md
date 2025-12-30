# Library Suggestion Helper — Chrome Extension (Minimal)

Quick steps to load locally:
1. Open Chrome → chrome://extensions
2. Enable *Developer mode* (top-right)
3. Click *Load unpacked* and select this `extension/` folder
4. Visit a page with a book (or one with an <h1>)
5. Click the extension icon to open the popup

Behavior:
- The extension detects a book title from the page (uses `<h1>` first, then `document.title`).
- Click 🔍 to check `http://localhost:3000/check-book?title=...`.
- If missing, click ➕ to POST `http://localhost:3000/suggest-book` with `{title}`.

Notes:
- Backend must be running on http://localhost:3000
- Keep the extension minimal and framework-free for clarity
