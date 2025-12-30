// popup.js
// Minimal, commented code for clarity
document.addEventListener('DOMContentLoaded', () => {
  const titleEl = document.getElementById('title');
  const searchBtn = document.getElementById('search');
  const addBtn = document.getElementById('add');
  const statusEl = document.getElementById('status');

  // Read the detected book from content script storage
  chrome.storage.local.get('detectedBook', (data) => {
    const detected = data.detectedBook;

    if (detected && detected.title) {
      titleEl.textContent = detected.title;
      searchBtn.disabled = false;

      // Search button: check with backend if book exists
      searchBtn.addEventListener('click', async () => {
        statusEl.textContent = 'Checking...';
        try {
          const res = await fetch(`http://localhost:3000/check-book?title=${encodeURIComponent(detected.title)}`);
          const json = await res.json();
          if (json.exists) {
            statusEl.textContent = 'Book already available in library';
            addBtn.style.display = 'none';
          } else {
            statusEl.textContent = 'Book not found.';
            addBtn.style.display = 'inline-block';
          }
        } catch (err) {
          statusEl.textContent = 'Error contacting backend';
          console.error(err);
        }
      });

      // Add button: send suggestion to backend
      addBtn.addEventListener('click', async () => {
        statusEl.textContent = 'Suggesting...';
        try {
          const res = await fetch('http://localhost:3000/suggest-book', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            // url is no longer stored by the backend; only send title
            body: JSON.stringify({ title: detected.title })
          });
          if (res.ok) {
            statusEl.textContent = 'Thanks — book suggested!';
            addBtn.style.display = 'none';
          } else {
            const err = await res.json();
            statusEl.textContent = 'Failed to suggest book';
            console.error(err);
          }
        } catch (err) {
          statusEl.textContent = 'Network error';
          console.error(err);
        }
      });
    } else {
      titleEl.textContent = '(no book detected on this page)';
      searchBtn.disabled = true;
    }
  });
});
