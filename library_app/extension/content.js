// content.js
// Improved book title detection per priority and cleaning rules
// - Priority: og:title -> citation_title -> <title> -> headings -> pdf filename -> document.title
// - Stores { title, url, source } in chrome.storage.local (source: 'meta'|'title'|'heading'|'pdf')
// - Keeps behavior minimal and robust for single-page apps (uses MutationObserver)

(function () {
  // Helpers
  function isVisible(el) {
    if (!el) return false;
    const style = window.getComputedStyle(el);
    const rect = el.getBoundingClientRect();
    return (
      style &&
      style.display !== 'none' &&
      style.visibility !== 'hidden' &&
      rect.width > 0 &&
      rect.height > 0
    );
  }

  function cleanTitle(str) {
    if (!str) return '';
    let s = String(str).trim();

    // Remove common PDF markers
    s = s.replace(/\s*[-|]\s*PDF$/i, '');
    s = s.replace(/\(PDF\)$/i, '');
    s = s.replace(/\|\s*PDF$/i, '');

    // Remove site name heuristics: split by " | " or " - " and take the most likely title part (left side)
    if (s.includes('|')) s = s.split('|')[0];
    else if (s.includes(' - ')) s = s.split(' - ')[0];
    else if (s.includes(' — ')) s = s.split(' — ')[0];

    // Normalize whitespace
    s = s.replace(/\s+/g, ' ').trim();

    // Trim trailing separators
    s = s.replace(/[\-\|]+$/g, '').trim();

    return s;
  }

  // Heading selection: choose visible headings (h1,h2,h3) near top with largest font-size
  function pickBestHeading() {
    try {
      const candidates = Array.from(document.querySelectorAll('h1,h2,h3'))
        .map(el => ({ el, text: (el.innerText || el.textContent || '').trim() }))
        .filter(item => item.text && item.text.length > 0 && item.text.length <= 120)
        .filter(item => isVisible(item.el));

      if (!candidates.length) return null;

      // Score: prefer elements near the top and with larger font-size
      const scored = candidates.map(({ el, text }) => {
        const style = window.getComputedStyle(el);
        const fs = parseFloat(style.fontSize || '0') || 0;
        const rect = el.getBoundingClientRect();
        const top = rect.top || 0;
        // Score: bigger font-size + proximity to top (smaller top -> larger score)
        const score = fs * 2 + Math.max(0, 300 - top) / 100; // heuristics
        return { el, text: cleanTitle(text), score, top, fs };
      });

      // Sort by score desc, then top asc
      scored.sort((a, b) => b.score - a.score || a.top - b.top);
      return scored[0].text || null;
    } catch (e) {
      // Fail silently
      return null;
    }
  }

  // Extract filename from PDF URL
  function pdfTitleFromUrl(url) {
    try {
      const u = new URL(url);
      const path = u.pathname || '';
      const last = path.split('/').pop() || '';
      let name = decodeURIComponent(last.replace(/\.[a-z0-9]+$/i, ''));
      name = name.replace(/[._-]+/g, ' ');
      name = name.replace(/\s+/g, ' ').trim();
      // Remove trailing 'pdf' words
      name = name.replace(/\bpdf\b$/i, '').trim();
      return cleanTitle(name);
    } catch (e) {
      return null;
    }
  }

  function detect() {
    const url = location.href;
    const host = location.hostname || '';
    let title = '';
    let source = '';

    // --- Site-specific handling for booktime.org ---
    // booktime.org stores titles in meta tags, JSON-LD or in elements with role="heading"
    // Titles are not reliably in <h1>, so add targeted extraction to improve detection.
    if (host.includes('booktime.org')) {
      try {
        // helper to apply extra cleaning rules specific to booktime
        function cleanBooktimeTitle(s) {
          if (!s) return '';
          let out = String(s).trim();

          // Trim after '|' or en-dash '–' (site sometimes appends language/site info)
          out = out.split('|')[0];
          out = out.split('–')[0];

          // Remove common language suffixes like "(EN)", "(English)", "- English"
          out = out.replace(/\(\s*[A-Za-z]{2,}\s*\)$/, '');
          out = out.replace(/[-–—]\s*[A-Za-z]{2,}(?:\b.*)?$/i, '');
          out = out.replace(/\|\s*[A-Za-z]{2,}$/, '');

          // Normalize whitespace and apply general cleaning
          out = cleanTitle(out);

          // Ignore numeric-only titles
          if (/^[\d\s\W]+$/.test(out)) return '';

          return out;
        }

        // 1) twitter:title
        const twitter = document.querySelector('meta[name="twitter:title"]');
        if (twitter && twitter.content) {
          const ct = cleanBooktimeTitle(twitter.content);
          if (ct) {
            title = ct;
            source = 'booktime-meta';
          }
        }

        // 2) og:title
        if (!title) {
          const og = document.querySelector('meta[property="og:title"], meta[name="og:title"]');
          if (og && og.content) {
            const ct = cleanBooktimeTitle(og.content);
            if (ct) {
              title = ct;
              source = 'booktime-meta';
            }
          }
        }

        // 3) JSON-LD parsing for @type: Book
        if (!title) {
          const scripts = Array.from(document.querySelectorAll('script[type="application/ld+json"]'));
          for (const s of scripts) {
            if (!s.textContent) continue;
            try {
              const j = JSON.parse(s.textContent.trim());

              // recursive search for Book type
              function findBookName(node, depth = 0) {
                if (!node || depth > 6) return null;

                if (Array.isArray(node)) {
                  for (const el of node) {
                    const r = findBookName(el, depth + 1);
                    if (r) return r;
                  }
                } else if (typeof node === 'object') {
                  const type = (node['@type'] || node['type'] || '').toString().toLowerCase();
                  if (type === 'book' || type.endsWith(':book') || (Array.isArray(node['@type']) && node['@type'].map(t=>String(t).toLowerCase()).includes('book'))) {
                    if (node.name) return node.name;
                  }

                  // check common containers
                  if (node['@graph']) {
                    const r = findBookName(node['@graph'], depth + 1);
                    if (r) return r;
                  }

                  // search object properties
                  for (const k of Object.keys(node)) {
                    try {
                      const r = findBookName(node[k], depth + 1);
                      if (r) return r;
                    } catch (e) { /* continue */ }
                  }
                }
                return null;
              }

              const found = findBookName(j);
              if (found) {
                const ct = cleanBooktimeTitle(found);
                if (ct) {
                  title = ct;
                  source = 'booktime-jsonld';
                  break;
                }
              }
            } catch (e) {
              // ignore JSON parse errors for safety
            }
          }
        }

        // 4) DOM elements with role="heading"
        if (!title) {
          const roles = Array.from(document.querySelectorAll('[role="heading"]'))
            .map(el => ({ el, text: (el.innerText || el.textContent || '').trim() }))
            .filter(item => item.text && item.text.length > 0 && item.text.length <= 120)
            .filter(item => isVisible(item.el));

          if (roles.length) {
            // pick the one nearest top with largest font-size
            const scored = roles.map(({ el, text }) => {
              const style = window.getComputedStyle(el);
              const fs = parseFloat(style.fontSize || '0') || 0;
              const rect = el.getBoundingClientRect();
              const top = rect.top || 0;
              const score = fs * 2 + Math.max(0, 300 - top) / 100;
              return { text: cleanBooktimeTitle(text), score, top };
            }).filter(r => r.text && r.text.length > 0);

            if (scored.length) {
              scored.sort((a, b) => b.score - a.score || a.top - b.top);
              title = scored[0].text;
              source = 'booktime-heading';
            }
          }
        }

        // If we successfully found a title on booktime, write and return early
        if (title) {
          chrome.storage.local.set({ detectedBook: { title, url, source } });
          return;
        }
      } catch (e) {
        // If anything fails, continue to fallback detection
        console.error('booktime.org detection error', e);
      }
    }

    // --- Fallback to global detection logic ---
    // 1) <meta property="og:title"> or <meta name="og:title">
    const og = document.querySelector('meta[property="og:title"], meta[name="og:title"]');
    if (og && og.content) {
      title = cleanTitle(og.content);
      source = 'meta';
    }

    // 2) <meta name="citation_title">
    if (!title) {
      const citation = document.querySelector('meta[name="citation_title"]');
      if (citation && citation.content) {
        title = cleanTitle(citation.content);
        source = 'meta';
      }
    }

    // 3) <title> tag cleaned
    if (!title) {
      const t = document.querySelector('title');
      if (t && t.textContent) {
        const cleaned = cleanTitle(t.textContent);
        if (cleaned) {
          title = cleaned;
          source = 'title';
        }
      }
    }

    // 4) largest visible heading
    if (!title) {
      const heading = pickBestHeading();
      if (heading) {
        title = heading;
        source = 'heading';
      }
    }

    // 5) PDF filename
    if (!title && /\.pdf(\?|$)/i.test(url)) {
      const pdfTitle = pdfTitleFromUrl(url);
      if (pdfTitle) {
        title = pdfTitle;
        source = 'pdf';
      }
    }

    // 6) Fallback: document.title trimmed
    if (!title) {
      title = cleanTitle(document.title || '');
      source = 'title';
    }

    // If no meaningful title found, remove storage entry
    if (title && title.length > 0) {
      chrome.storage.local.set({ detectedBook: { title, url, source } });
    } else {
      chrome.storage.local.remove('detectedBook');
    }
  }

  // Initial detection and observe DOM changes for single-page apps
  detect();

  const observer = new MutationObserver(() => detect());
  observer.observe(document.body, { childList: true, subtree: true });
})();
