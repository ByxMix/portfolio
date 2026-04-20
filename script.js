(function () {
  'use strict';

  // ─── Social Icons SVG Map ───────────────────
  const ICONS = {
    roblox: `<svg viewBox="0 0 24 24" fill="currentColor"><path d="M5.164 0L0 18.836 18.836 24 24 5.164 5.164 0zm8.746 15.094l-5.004-1.3 1.3-5.004 5.004 1.3-1.3 5.004z"/></svg>`,
    twitter: `<svg viewBox="0 0 24 24" fill="currentColor"><path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z"/></svg>`,
    discord: `<svg viewBox="0 0 24 24" fill="currentColor"><path d="M20.317 4.3698a19.7913 19.7913 0 00-4.8851-1.5152.0741.0741 0 00-.0785.0371c-.211.3753-.4447.8648-.6083 1.2495-1.8447-.2762-3.68-.2762-5.4868 0-.1636-.3933-.4058-.8742-.6177-1.2495a.077.077 0 00-.0785-.037 19.7363 19.7363 0 00-4.8852 1.515.0699.0699 0 00-.0321.0277C.5334 9.0458-.319 13.5799.0992 18.0578a.0824.0824 0 00.0312.0561c2.0528 1.5076 4.0413 2.4228 5.9929 3.0294a.0777.0777 0 00.0842-.0276c.4616-.6304.8731-1.2952 1.226-1.9942a.076.076 0 00-.0416-.1057c-.6528-.2476-1.2743-.5495-1.8722-.8923a.077.077 0 01-.0076-.1277c.1258-.0943.2517-.1923.3718-.2914a.0743.0743 0 01.0776-.0105c3.9278 1.7933 8.18 1.7933 12.0614 0a.0739.0739 0 01.0785.0095c.1202.099.246.1981.3728.2924a.077.077 0 01-.0066.1276 12.2986 12.2986 0 01-1.873.8914.0766.0766 0 00-.0407.1067c.3604.698.7719 1.3628 1.225 1.9932a.076.076 0 00.0842.0286c1.961-.6067 3.9495-1.5219 6.0023-3.0294a.077.077 0 00.0313-.0552c.5004-5.177-.8382-9.6739-3.5485-13.6604a.061.061 0 00-.0312-.0286zM8.02 15.3312c-1.1825 0-2.1569-1.0857-2.1569-2.419 0-1.3332.9555-2.4189 2.157-2.4189 1.2108 0 2.1757 1.0952 2.1568 2.419 0 1.3332-.9555 2.4189-2.1569 2.4189zm7.9748 0c-1.1825 0-2.1569-1.0857-2.1569-2.419 0-1.3332.9554-2.4189 2.1569-2.4189 1.2108 0 2.1757 1.0952 2.1568 2.419 0 1.3332-.946 2.4189-2.1568 2.4189z"/></svg>`,
    youtube: `<svg viewBox="0 0 24 24" fill="currentColor"><path d="M23.498 6.186a3.016 3.016 0 00-2.122-2.136C19.505 3.545 12 3.545 12 3.545s-7.505 0-9.377.505A3.017 3.017 0 00.502 6.186C0 8.07 0 12 0 12s0 3.93.502 5.814a3.016 3.016 0 002.122 2.136c1.871.505 9.376.505 9.376.505s7.505 0 9.377-.505a3.015 3.015 0 002.122-2.136C24 15.93 24 12 24 12s0-3.93-.502-5.814zM9.545 15.568V8.432L15.818 12l-6.273 3.568z"/></svg>`,
    github: `<svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 .297c-6.63 0-12 5.373-12 12 0 5.303 3.438 9.8 8.205 11.385.6.113.82-.258.82-.577 0-.285-.01-1.04-.015-2.04-3.338.724-4.042-1.61-4.042-1.61C4.422 18.07 3.633 17.7 3.633 17.7c-1.087-.744.084-.729.084-.729 1.205.084 1.838 1.236 1.838 1.236 1.07 1.835 2.809 1.305 3.495.998.108-.776.417-1.305.76-1.605-2.665-.3-5.466-1.332-5.466-5.93 0-1.31.465-2.38 1.235-3.22-.135-.303-.54-1.523.105-3.176 0 0 1.005-.322 3.3 1.23.96-.267 1.98-.399 3-.405 1.02.006 2.04.138 3 .405 2.28-1.552 3.285-1.23 3.285-1.23.645 1.653.24 2.873.12 3.176.765.84 1.23 1.91 1.23 3.22 0 4.61-2.805 5.625-5.475 5.92.42.36.81 1.096.81 2.22 0 1.606-.015 2.896-.015 3.286 0 .315.21.69.825.57C20.565 22.092 24 17.592 24 12.297c0-6.627-5.373-12-12-12"/></svg>`,
    twitch: `<svg viewBox="0 0 24 24" fill="currentColor"><path d="M11.571 4.714h1.715v5.143H11.57zm4.715 0H18v5.143h-1.714zM6 0L1.714 4.286v15.428h5.143V24l4.286-4.286h3.428L22.286 12V0zm14.571 11.143l-3.428 3.428h-3.429l-3 3v-3H6.857V1.714h13.714z"/></svg>`,
    linkedin: `<svg viewBox="0 0 24 24" fill="currentColor"><path d="M20.447 20.452h-3.554v-5.569c0-1.328-.027-3.037-1.852-3.037-1.853 0-2.136 1.445-2.136 2.939v5.667H9.351V9h3.414v1.561h.046c.477-.9 1.637-1.85 3.37-1.85 3.601 0 4.267 2.37 4.267 5.455v6.286zM5.337 7.433c-1.144 0-2.063-.926-2.063-2.065 0-1.138.92-2.063 2.063-2.063 1.14 0 2.064.925 2.064 2.063 0 1.139-.925 2.065-2.064 2.065zm1.782 13.019H3.555V9h3.564v11.452zM22.225 0H1.771C.792 0 0 .774 0 1.729v20.542C0 23.227.792 24 1.771 24h20.451C23.2 24 24 23.227 24 22.271V1.729C24 .774 23.2 0 22.222 0h.003z"/></svg>`,
    email: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="4" width="20" height="16" rx="2"/><path d="m22 7-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7"/></svg>`,
    default: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71"/><path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71"/></svg>`
  };

  // ─── Utility: sanitize text to prevent XSS ──
  function escapeHTML(str) {
    const div = document.createElement('div');
    div.appendChild(document.createTextNode(str));
    return div.innerHTML;
  }

  // ─── Utility: sanitize URL ──────────────────
  function sanitizeURL(url) {
    try {
      const parsed = new URL(url, window.location.origin);
      if (['http:', 'https:', 'mailto:'].includes(parsed.protocol)) {
        return parsed.href;
      }
    } catch (e) { /* invalid URL */ }
    return '#';
  }

  // ─── Load Config & Initialize ───────────────
  async function init() {
    let config;
    try {
      const resp = await fetch('config.json');
      if (!resp.ok) throw new Error('Failed to load config.json');
      config = await resp.json();
    } catch (err) {
      console.error('Error loading config:', err);
      document.body.innerHTML = '<p style="color:#fff;text-align:center;padding:40px;">Failed to load config.json. Make sure it exists in the same folder as index.html.</p>';
      return;
    }

    applyTheme(config.theme);
    applyMeta(config.meta);
    renderNavbar(config.navbar);
    renderIntro(config.intro, config.socialLinks);
    renderGames(config.games);
    renderVideos(config.videos);
    await renderSnippets(config.snippets);
    renderFAQ(config.faq);
    renderFooter(config.footer);
    initShader(config.theme);
    initScrollReveal();
    initNavScroll();

    // Dismiss loading screen
    const loader = document.getElementById('loading-screen');
    if (loader) loader.classList.add('hidden');
  }

  // ─── Apply Theme as CSS Custom Properties ───
  function applyTheme(theme) {
    if (!theme) return;
    const root = document.documentElement.style;
    if (theme.primaryColor) root.setProperty('--primary', theme.primaryColor);
    if (theme.secondaryColor) root.setProperty('--secondary', theme.secondaryColor);
    if (theme.accentColor) root.setProperty('--accent', theme.accentColor);
    if (theme.textColor) root.setProperty('--text', theme.textColor);
    if (theme.textSecondary) root.setProperty('--text-secondary', theme.textSecondary);
    if (theme.cardBackground) root.setProperty('--card-bg', theme.cardBackground);
    if (theme.cardBorder) root.setProperty('--card-border', theme.cardBorder);
    if (theme.fontFamily) {
      root.setProperty('--font', theme.fontFamily);
    }
    if (theme.headingFontFamily) {
      root.setProperty('--heading-font', theme.headingFontFamily);
    }
    if (theme.borderRadius) root.setProperty('--radius', theme.borderRadius);
  }

  // ─── Apply Meta Tags ────────────────────────
  function applyMeta(meta) {
    if (!meta) return;
    if (meta.title) {
      document.title = meta.title;
      const ogTitle = document.querySelector('meta[property="og:title"]');
      if (ogTitle) ogTitle.setAttribute('content', meta.title);
    }
    if (meta.description) {
      document.querySelector('meta[name="description"]').setAttribute('content', meta.description);
      const ogDesc = document.querySelector('meta[property="og:description"]');
      if (ogDesc) ogDesc.setAttribute('content', meta.description);
    }
    if (meta.favicon) {
      document.querySelector('link[rel="icon"]').setAttribute('href', meta.favicon);
    }
    if (meta.ogImage) {
      const ogImg = document.querySelector('meta[property="og:image"]');
      if (ogImg) ogImg.setAttribute('content', meta.ogImage);
    }
  }

  // ─── Render Navbar ──────────────────────────
  function renderNavbar(navbar) {
    if (!navbar) return;
    const logo = document.getElementById('nav-logo');
    const linksList = document.getElementById('nav-links');
    const toggle = document.getElementById('nav-toggle');

    if (navbar.logo) logo.textContent = navbar.logo;

    if (navbar.links) {
      linksList.innerHTML = navbar.links.map(link =>
        `<li><a href="${escapeHTML(link.href)}">${escapeHTML(link.label)}</a></li>`
      ).join('');
    }

    // Mobile toggle
    toggle.addEventListener('click', () => {
      toggle.classList.toggle('active');
      linksList.classList.toggle('open');
    });

    // Close mobile menu on link click
    linksList.addEventListener('click', (e) => {
      if (e.target.tagName === 'A') {
        toggle.classList.remove('active');
        linksList.classList.remove('open');
      }
    });
  }

  // ─── Render Introduction ────────────────────
  function renderIntro(intro, socialLinks) {
    if (!intro) return;

    const greeting = document.getElementById('intro-greeting');
    const name = document.getElementById('intro-name');
    const tagline = document.getElementById('intro-tagline');
    const bio = document.getElementById('intro-bio');
    const image = document.getElementById('intro-image');
    const linksContainer = document.getElementById('social-links');
    const resumeContainer = document.getElementById('resume-btn-container');

    if (intro.greeting) greeting.textContent = intro.greeting;
    if (intro.name) name.textContent = intro.name;
    if (intro.tagline) tagline.textContent = intro.tagline;
    if (intro.bio) bio.textContent = intro.bio;
    if (intro.profileImage) {
      image.src = intro.profileImage;
      image.alt = intro.profileImageAlt || 'Profile picture';
    }

    // Social links
    if (socialLinks && socialLinks.length) {
      linksContainer.innerHTML = socialLinks.map((link, i) => {
        const icon = ICONS[link.icon] || ICONS.default;
        if (link.action === 'copy' && link.copyText) {
          return `<button class="social-link social-copy-btn" data-copy="${escapeHTML(link.copyText)}" title="${escapeHTML(link.platform)}">${icon}</button>`;
        }
        const url = sanitizeURL(link.url);
        return `<a href="${url}" class="social-link" target="_blank" rel="noopener noreferrer" title="${escapeHTML(link.platform)}">${icon}</a>`;
      }).join('');

      // Copy-to-clipboard handler for Discord (or any copy action)
      linksContainer.querySelectorAll('.social-copy-btn').forEach(btn => {
        btn.addEventListener('click', () => {
          const text = btn.dataset.copy;
          navigator.clipboard.writeText(text).then(() => {
            const original = btn.getAttribute('title');
            btn.setAttribute('title', 'Copied!');
            btn.classList.add('copied');
            setTimeout(() => {
              btn.setAttribute('title', original);
              btn.classList.remove('copied');
            }, 2000);
          });
        });
      });
    }

    // Resume button
    if (intro.resumeButton && intro.resumeButton.show) {
      const url = sanitizeURL(intro.resumeButton.url);
      resumeContainer.innerHTML = `<a href="${url}" class="resume-btn" target="_blank" rel="noopener noreferrer">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>
        ${escapeHTML(intro.resumeButton.label)}
      </a>`;
    }
  }

  // ─── Render Games ───────────────────────────
  function renderGames(games) {
    if (!games) return;

    document.getElementById('games-title').textContent = games.sectionTitle || 'Games';
    document.getElementById('games-subtitle').textContent = games.sectionSubtitle || '';

    const grid = document.getElementById('games-grid');
    if (!games.items || !games.items.length) return;

    grid.innerHTML = games.items.map(game => {
      const tags = (game.tags || []).map(t => `<span class="game-tag">${escapeHTML(t)}</span>`).join('');
      const url = sanitizeURL(game.url);

      return `
        <div class="game-card reveal">
          <div class="game-thumbnail-wrapper">
            <img class="game-thumbnail" src="${escapeHTML(game.thumbnail)}" alt="${escapeHTML(game.title)}" loading="lazy">
          </div>
          <div class="game-body">
            <h3 class="game-title">${escapeHTML(game.title)}</h3>
            ${tags ? `<div class="game-tags">${tags}</div>` : ''}
            <p class="game-description">${escapeHTML(game.description)}</p>
            <div class="game-footer">
              <a href="${url}" class="game-link" target="_blank" rel="noopener noreferrer">
                Play Now
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><line x1="7" y1="17" x2="17" y2="7"/><polyline points="7 7 17 7 17 17"/></svg>
              </a>
            </div>
          </div>
        </div>`;
    }).join('');
  }

  // ─── Render Videos ──────────────────────────
  function renderVideos(videos) {
    if (!videos) return;

    document.getElementById('videos-title').textContent = videos.sectionTitle || 'Videos';
    document.getElementById('videos-subtitle').textContent = videos.sectionSubtitle || '';

    const grid = document.getElementById('videos-grid');
    if (!videos.items || !videos.items.length) return;

    grid.innerHTML = videos.items.map(video => {
      const type = (video.type || 'youtube').toLowerCase();
      let mediaHTML = '';

      if (type === 'youtube') {
        const videoUrl = sanitizeURL(video.videoUrl);
        mediaHTML = `
          <div class="video-embed-wrapper">
            <iframe src="${videoUrl}" title="${escapeHTML(video.title)}" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen loading="lazy"></iframe>
          </div>`;
      } else if (type === 'file') {
        // Local or hosted video file (mp4, webm, etc.)
        const src = escapeHTML(video.videoUrl);
        const poster = video.poster ? `poster="${escapeHTML(video.poster)}"` : '';
        mediaHTML = `
          <div class="video-embed-wrapper video-native-wrapper">
            <video controls preload="metadata" ${poster} playsinline>
              <source src="${src}" type="${escapeHTML(video.mimeType || 'video/mp4')}">
              Your browser does not support the video tag.
            </video>
          </div>`;
      } else if (type === 'streamable') {
        const videoUrl = sanitizeURL(video.videoUrl);
        mediaHTML = `
          <div class="video-embed-wrapper">
            <iframe src="${videoUrl}" title="${escapeHTML(video.title)}" allow="autoplay; fullscreen" allowfullscreen loading="lazy"></iframe>
          </div>`;
      } else if (type === 'vimeo') {
        const videoUrl = sanitizeURL(video.videoUrl);
        mediaHTML = `
          <div class="video-embed-wrapper">
            <iframe src="${videoUrl}" title="${escapeHTML(video.title)}" allow="autoplay; fullscreen; picture-in-picture" allowfullscreen loading="lazy"></iframe>
          </div>`;
      } else {
        // Fallback: treat as iframe embed
        const videoUrl = sanitizeURL(video.videoUrl);
        mediaHTML = `
          <div class="video-embed-wrapper">
            <iframe src="${videoUrl}" title="${escapeHTML(video.title)}" allowfullscreen loading="lazy"></iframe>
          </div>`;
      }

      return `
        <div class="video-card reveal">
          ${mediaHTML}
          <button class="video-expand-btn" title="Expand video">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="15 3 21 3 21 9"/><polyline points="9 21 3 21 3 15"/><line x1="21" y1="3" x2="14" y2="10"/><line x1="3" y1="21" x2="10" y2="14"/></svg>
          </button>
          <div class="video-body">
            <h3 class="video-title">${escapeHTML(video.title)}</h3>
            <p class="video-description">${escapeHTML(video.description)}</p>
          </div>
        </div>`;
    }).join('');

    // ─── Video Lightbox ───
    const lightbox = document.createElement('div');
    lightbox.className = 'video-lightbox';
    lightbox.innerHTML = `<div class="video-lightbox-content"></div>`;
    document.body.appendChild(lightbox);

    const closeLightbox = () => {
      lightbox.classList.remove('active');
      const inner = lightbox.querySelector('.video-lightbox-content');
      // Pause any playing videos and clear
      inner.querySelectorAll('video').forEach(v => v.pause());
      inner.querySelectorAll('iframe').forEach(f => f.src = '');
      setTimeout(() => { inner.innerHTML = ''; }, 300);
    };

    lightbox.addEventListener('click', (e) => {
      if (e.target === lightbox) closeLightbox();
    });
    document.addEventListener('keydown', (e) => {
      if (e.key === 'Escape') closeLightbox();
    });

    grid.querySelectorAll('.video-expand-btn').forEach((btn, i) => {
      btn.addEventListener('click', () => {
        const card = btn.closest('.video-card');
        const wrapper = card.querySelector('.video-embed-wrapper');
        const inner = lightbox.querySelector('.video-lightbox-content');
        inner.innerHTML = wrapper.outerHTML;
        // For iframes, re-set src to start fresh
        const iframe = inner.querySelector('iframe');
        if (iframe) iframe.src = iframe.src;
        // For native videos, reset and play
        const video = inner.querySelector('video');
        if (video) { video.currentTime = 0; video.play(); }
        lightbox.classList.add('active');
      });
    });
  }

  // ─── Luau Syntax Highlighter ─────────────────
  function highlightLuau(code) {
    // Escape HTML first
    let html = escapeHTML(code);

    // Order matters: comments first, then strings, then others

    // Multi-line comments --[[ ... ]]
    html = html.replace(/(--\[\[[\s\S]*?\]\])/g, '<span class="luau-comment">$1</span>');

    // Single-line comments
    html = html.replace(/(--(?!\[\[)[^\n]*)/g, '<span class="luau-comment">$1</span>');

    // Strings (double and single quoted)
    html = html.replace(/(&quot;(?:[^&]|&(?!quot;))*?&quot;|&#39;(?:[^&]|&(?!#39;))*?&#39;)/g, '<span class="luau-string">$1</span>');

    // Luau types after colons  e.g. `: Player`, `: number`
    html = html.replace(/:\s*\b(string|number|boolean|nil|any|never|unknown|thread|buffer)\b/g, ': <span class="luau-type">$1</span>');

    // Type annotations with custom types
    html = html.replace(/:\s*\b([A-Z][A-Za-z0-9]*)\b/g, ': <span class="luau-type">$1</span>');

    // Keywords
    const keywords = ['local', 'function', 'end', 'if', 'then', 'else', 'elseif', 'for', 'while', 'do', 'repeat', 'until', 'return', 'break', 'continue', 'in', 'not', 'and', 'or', 'type', 'export'];
    const kwRegex = new RegExp('\\b(' + keywords.join('|') + ')\\b', 'g');
    html = html.replace(kwRegex, '<span class="luau-keyword">$1</span>');

    // Booleans & nil
    html = html.replace(/\b(true|false|nil)\b/g, '<span class="luau-bool">$1</span>');

    // Numbers
    html = html.replace(/\b(\d+\.?\d*)\b/g, '<span class="luau-number">$1</span>');

    // Global services/builtins
    const globals = ['game', 'workspace', 'script', 'warn', 'print', 'error', 'typeof', 'require', 'pcall', 'xpcall', 'select', 'unpack', 'rawget', 'rawset', 'setmetatable', 'getmetatable', 'ipairs', 'pairs', 'next', 'tostring', 'tonumber', 'coroutine', 'task', 'table', 'string', 'math', 'debug', 'Instance', 'Enum', 'Vector3', 'CFrame', 'Color3', 'UDim2', 'UDim', 'TweenInfo', 'Ray', 'Region3', 'BrickColor', 'NumberRange', 'NumberSequence', 'ColorSequence'];
    const globRegex = new RegExp('\\b(' + globals.join('|') + ')\\b', 'g');
    html = html.replace(globRegex, '<span class="luau-global">$1</span>');

    // self
    html = html.replace(/\b(self)\b/g, '<span class="luau-self">$1</span>');

    // Function calls  name(
    html = html.replace(/\b([a-zA-Z_]\w*)\s*\(/g, '<span class="luau-function">$1</span>(');

    // Property access after . or :
    html = html.replace(/([.:])([a-zA-Z_]\w*)/g, '$1<span class="luau-property">$2</span>');

    return html;
  }

  // ─── Render Code Snippets ───────────────────
  async function renderSnippets(snippets) {
    if (!snippets) return;

    document.getElementById('snippets-title').textContent = snippets.sectionTitle || 'Code Snippets';
    document.getElementById('snippets-subtitle').textContent = snippets.sectionSubtitle || '';

    const grid = document.getElementById('snippets-grid');
    if (!snippets.items || !snippets.items.length) return;

    // Load code from files (or fall back to inline "code" field)
    const loadedItems = await Promise.all(snippets.items.map(async (snippet) => {
      let code = snippet.code || '';
      if (snippet.codeFile) {
        try {
          const resp = await fetch(snippet.codeFile);
          if (resp.ok) code = await resp.text();
        } catch (e) {
          console.warn('Failed to load snippet file:', snippet.codeFile, e);
        }
      }
      return { ...snippet, code };
    }));

    grid.innerHTML = loadedItems.map((snippet, index) => {
      const highlighted = highlightLuau(snippet.code);
      const lang = escapeHTML(snippet.language || 'luau').toUpperCase();

      return `
        <div class="snippet-card reveal">
          <div class="snippet-header">
            <div class="snippet-info">
              <h3 class="snippet-title">${escapeHTML(snippet.title)}</h3>
              <p class="snippet-description">${escapeHTML(snippet.description)}</p>
            </div>
            <span class="snippet-lang">${lang}</span>
          </div>
          <div class="snippet-code-wrapper">
            <button class="snippet-copy-btn" data-snippet-index="${index}" title="Copy code">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="9" y="9" width="13" height="13" rx="2" ry="2"/><path d="M5 15H4a2 2 0 01-2-2V4a2 2 0 012-2h9a2 2 0 012 2v1"/></svg>
              <span>Copy</span>
            </button>
            <pre class="snippet-code">${highlighted}</pre>
          </div>
        </div>`;
    }).join('');

    // Copy button handler
    grid.addEventListener('click', (e) => {
      const btn = e.target.closest('.snippet-copy-btn');
      if (!btn) return;

      const index = parseInt(btn.dataset.snippetIndex, 10);
      const code = loadedItems[index]?.code;
      if (!code) return;

      navigator.clipboard.writeText(code).then(() => {
        btn.classList.add('copied');
        btn.querySelector('span').textContent = 'Copied!';
        btn.querySelector('svg').innerHTML = '<polyline points="20 6 9 17 4 12"/>';

        setTimeout(() => {
          btn.classList.remove('copied');
          btn.querySelector('span').textContent = 'Copy';
          btn.querySelector('svg').innerHTML = '<rect x="9" y="9" width="13" height="13" rx="2" ry="2"/><path d="M5 15H4a2 2 0 01-2-2V4a2 2 0 012-2h9a2 2 0 012 2v1"/>';
        }, 2000);
      });
    });
  }

  // ─── Render FAQ (Accordion) ─────────────────
  function renderFAQ(faq) {
    if (!faq) return;

    document.getElementById('faq-title').textContent = faq.sectionTitle || 'FAQ';
    document.getElementById('faq-subtitle').textContent = faq.sectionSubtitle || '';

    const list = document.getElementById('faq-list');
    if (!faq.items || !faq.items.length) return;

    list.innerHTML = faq.items.map((item, i) => `
      <div class="faq-item reveal" data-faq="${i}">
        <button class="faq-question" aria-expanded="false">
          <span>${escapeHTML(item.question)}</span>
          <span class="faq-icon">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="6 9 12 15 18 9"/></svg>
          </span>
        </button>
        <div class="faq-answer">
          <div class="faq-answer-inner">${escapeHTML(item.answer)}</div>
        </div>
      </div>`
    ).join('');

    // Accordion toggle
    list.addEventListener('click', (e) => {
      const btn = e.target.closest('.faq-question');
      if (!btn) return;

      const item = btn.parentElement;
      const answer = item.querySelector('.faq-answer');
      const isActive = item.classList.contains('active');

      // Close all
      list.querySelectorAll('.faq-item.active').forEach(el => {
        el.classList.remove('active');
        el.querySelector('.faq-question').setAttribute('aria-expanded', 'false');
        el.querySelector('.faq-answer').style.maxHeight = '0';
      });

      // Open clicked (if wasn't active)
      if (!isActive) {
        item.classList.add('active');
        btn.setAttribute('aria-expanded', 'true');
        answer.style.maxHeight = answer.scrollHeight + 'px';
      }
    });
  }

  // ─── Render Footer ──────────────────────────
  function renderFooter(footer) {
    if (!footer) return;
    const text = document.getElementById('footer-text');
    const backToTop = document.getElementById('back-to-top');

    if (footer.text) text.textContent = footer.text;
    if (!footer.showBackToTop) backToTop.style.display = 'none';
  }

  // ─── Scroll Reveal ──────────────────────────
  function initScrollReveal() {
    const observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          entry.target.classList.add('visible');
        }
      });
    }, { threshold: 0.1, rootMargin: '0px 0px -40px 0px' });

    document.querySelectorAll('.reveal').forEach(el => observer.observe(el));
  }

  // ─── Navbar Scroll Effect ───────────────────
  function initNavScroll() {
    const navbar = document.getElementById('navbar');
    let ticking = false;

    window.addEventListener('scroll', () => {
      if (!ticking) {
        requestAnimationFrame(() => {
          navbar.classList.toggle('scrolled', window.scrollY > 50);
          ticking = false;
        });
        ticking = true;
      }
    });
  }

  // ─── WebGL Dot Grid Shader Background ───────
  function initShader(theme) {
    const canvas = document.getElementById('shader-bg');

    // Detect low-end: reduced motion preference, low device memory, or low core count
    const prefersReduced = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    const lowEnd = prefersReduced || (navigator.deviceMemory && navigator.deviceMemory <= 4) || (navigator.hardwareConcurrency && navigator.hardwareConcurrency <= 4);

    // Low-end: skip shader entirely, use CSS gradient
    if (lowEnd) {
      canvas.style.display = 'none';
      document.body.style.background = `linear-gradient(135deg, rgb(${Math.round(bgColor[0]*255)},${Math.round(bgColor[1]*255)},${Math.round(bgColor[2]*255)}), rgb(${Math.round(bgColor[0]*400)},${Math.round(bgColor[1]*400)},${Math.round(bgColor[2]*400)}))`;
      return;
    }

    const gl = canvas.getContext('webgl', { antialias: false, alpha: false, preserveDrawingBuffer: false }) || canvas.getContext('experimental-webgl');
    if (!gl) {
      canvas.style.background = 'linear-gradient(135deg, #0a0600, #1c1305)';
      return;
    }

    // Config from theme
    const dotColor = theme?.shaderDotColor || [1.0, 0.65, 0.1];
    const bgColor = theme?.shaderBgColor || [0.05, 0.03, 0.0];
    const dotSize = theme?.shaderDotSize || 2.0;
    const gridSpacing = theme?.shaderGridSpacing || 28.0;
    const mouseRadius = theme?.shaderMouseRadius || 200.0;
    const speed = theme?.shaderSpeed || 0.4;
    const baseAlpha = theme?.shaderBaseAlpha || 0.12;
    const mouseAlpha = theme?.shaderMouseAlpha || 0.8;
    const pulseIntensity = theme?.shaderPulseIntensity || 0.08;

    // Cap DPR: 1 on low-end, max 1.5 otherwise
    const maxDPR = lowEnd ? 1.0 : Math.min(window.devicePixelRatio, 1.5);

    // Mouse tracking (throttled)
    let mouseX = -9999, mouseY = -9999;
    canvas.style.pointerEvents = 'none';

    let mouseMoveRaf = 0;
    document.addEventListener('mousemove', (e) => {
      if (mouseMoveRaf) return;
      mouseMoveRaf = requestAnimationFrame(() => {
        mouseX = e.clientX * maxDPR;
        mouseY = (window.innerHeight - e.clientY) * maxDPR;
        mouseMoveRaf = 0;
      });
    });

    document.addEventListener('mouseleave', () => {
      mouseX = -9999;
      mouseY = -9999;
    });

    function resize() {
      canvas.width = window.innerWidth * maxDPR;
      canvas.height = window.innerHeight * maxDPR;
      gl.viewport(0, 0, canvas.width, canvas.height);
    }
    resize();
    let resizeTimer;
    window.addEventListener('resize', () => {
      clearTimeout(resizeTimer);
      resizeTimer = setTimeout(resize, 150);
    });

    // Vertex shader
    const vsSource = `
      attribute vec2 a_position;
      void main() {
        gl_Position = vec4(a_position, 0.0, 1.0);
      }
    `;

    // Fragment shader — hash+sin animation (no interpolated noise), 4-edge connectivity
    const fsSource = `
      precision mediump float;
      uniform float u_time;
      uniform vec2 u_resolution;
      uniform vec2 u_mouse;
      uniform vec3 u_dotColor;
      uniform vec3 u_bgColor;
      uniform float u_dotSize;
      uniform float u_gridSpacing;
      uniform float u_mouseRadius;
      uniform float u_speed;
      uniform float u_baseAlpha;
      uniform float u_mouseAlpha;
      uniform float u_pulseIntensity;

      float hash(vec2 p) {
        return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
      }

      vec2 getDotPos(vec2 c) {
        vec2 base = (c + 0.5) * u_gridSpacing;
        float h1 = hash(c + vec2(50.0, 0.0));
        float h2 = hash(c + vec2(0.0, 80.0));
        vec2 off = vec2(
          sin(u_time * u_speed * 0.3 + h1 * 6.2832),
          sin(u_time * u_speed * 0.25 + h2 * 6.2832)
        ) * u_gridSpacing * 0.275;
        vec2 pos = base + off;
        float md = length(pos - u_mouse);
        float mi = 1.0 - smoothstep(0.0, u_mouseRadius, md);
        mi *= mi;
        vec2 dir = (md > 0.001) ? normalize(pos - u_mouse) : vec2(0.0);
        return pos + dir * mi * u_gridSpacing * 0.4;
      }

      float getDotAlpha(vec2 c, vec2 pos) {
        float h = hash(c + vec2(200.0, 150.0));
        float a = u_baseAlpha + sin(u_time * u_speed * 0.2 + h * 6.2832) * u_pulseIntensity;
        float md = length(pos - u_mouse);
        float mi = 1.0 - smoothstep(0.0, u_mouseRadius, md);
        mi *= mi;
        return clamp(mix(a, u_mouseAlpha, mi), 0.0, 1.0);
      }

      float segDist(vec2 p, vec2 a, vec2 b) {
        vec2 pa = p - a, ba = b - a;
        float t = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
        return length(pa - ba * t);
      }

      void main() {
        vec2 fc = gl_FragCoord.xy;
        vec2 cell = floor(fc / u_gridSpacing);

        float dotMask = 0.0;
        float bestAlpha = 0.0;

        // 3x3 dots
        for (int dy = -1; dy <= 1; dy++) {
          for (int dx = -1; dx <= 1; dx++) {
            vec2 nb = cell + vec2(float(dx), float(dy));
            vec2 p = getDotPos(nb);
            float d = 1.0 - smoothstep(u_dotSize - 0.8, u_dotSize + 0.8, length(fc - p));
            float al = getDotAlpha(nb, p);
            float v = d * al;
            if (v > dotMask) { dotMask = v; bestAlpha = al; }
          }
        }

        // 4 edges: current→right, current→up, left→current, below→current
        float eMask = 0.0;
        float ew = 0.6;

        vec2 pC = getDotPos(cell);
        float aC = getDotAlpha(cell, pC);
        vec2 pR = getDotPos(cell + vec2(1.0, 0.0));
        float aR = getDotAlpha(cell + vec2(1.0, 0.0), pR);
        vec2 pU = getDotPos(cell + vec2(0.0, 1.0));
        float aU = getDotAlpha(cell + vec2(0.0, 1.0), pU);
        vec2 pL = getDotPos(cell + vec2(-1.0, 0.0));
        float aL = getDotAlpha(cell + vec2(-1.0, 0.0), pL);
        vec2 pD = getDotPos(cell + vec2(0.0, -1.0));
        float aD = getDotAlpha(cell + vec2(0.0, -1.0), pD);

        float e1 = 1.0 - smoothstep(ew - 0.3, ew + 0.3, segDist(fc, pC, pR));
        float e2 = 1.0 - smoothstep(ew - 0.3, ew + 0.3, segDist(fc, pC, pU));
        float e3 = 1.0 - smoothstep(ew - 0.3, ew + 0.3, segDist(fc, pL, pC));
        float e4 = 1.0 - smoothstep(ew - 0.3, ew + 0.3, segDist(fc, pD, pC));

        eMask = max(eMask, e1 * (aC + aR) * 0.15);
        eMask = max(eMask, e2 * (aC + aU) * 0.15);
        eMask = max(eMask, e3 * (aL + aC) * 0.15);
        eMask = max(eMask, e4 * (aD + aC) * 0.15);

        float combined = max(dotMask, eMask);

        float mgd = length(fc - u_mouse);
        float mg = 1.0 - smoothstep(0.0, u_mouseRadius, mgd);
        mg *= mg;
        vec3 col = mix(u_dotColor * 0.6, u_dotColor, mg * 0.8 + bestAlpha * 0.3);

        vec3 fin = mix(u_bgColor, col, combined);

        vec2 uv = fc / u_resolution;
        vec2 vu = uv * (1.0 - uv);
        fin *= mix(0.7, 1.0, pow(vu.x * vu.y * 15.0, 0.2));

        gl_FragColor = vec4(fin, 1.0);
      }
    `;

    function compileShader(src, type) {
      const shader = gl.createShader(type);
      gl.shaderSource(shader, src);
      gl.compileShader(shader);
      if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
        console.error('Shader compile error:', gl.getShaderInfoLog(shader));
        gl.deleteShader(shader);
        return null;
      }
      return shader;
    }

    const vs = compileShader(vsSource, gl.VERTEX_SHADER);
    const fs = compileShader(fsSource, gl.FRAGMENT_SHADER);
    if (!vs || !fs) return;

    const program = gl.createProgram();
    gl.attachShader(program, vs);
    gl.attachShader(program, fs);
    gl.linkProgram(program);

    if (!gl.getProgramParameter(program, gl.LINK_STATUS)) {
      console.error('Program link error:', gl.getProgramInfoLog(program));
      return;
    }

    gl.useProgram(program);

    // Full-screen quad
    const vertices = new Float32Array([-1, -1, 1, -1, -1, 1, 1, 1]);
    const buffer = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
    gl.bufferData(gl.ARRAY_BUFFER, vertices, gl.STATIC_DRAW);

    const aPosition = gl.getAttribLocation(program, 'a_position');
    gl.enableVertexAttribArray(aPosition);
    gl.vertexAttribPointer(aPosition, 2, gl.FLOAT, false, 0, 0);

    // Uniforms
    const uTime = gl.getUniformLocation(program, 'u_time');
    const uResolution = gl.getUniformLocation(program, 'u_resolution');
    const uMouse = gl.getUniformLocation(program, 'u_mouse');
    const uDotColor = gl.getUniformLocation(program, 'u_dotColor');
    const uBgColor = gl.getUniformLocation(program, 'u_bgColor');
    const uDotSize = gl.getUniformLocation(program, 'u_dotSize');
    const uGridSpacing = gl.getUniformLocation(program, 'u_gridSpacing');
    const uMouseRadius = gl.getUniformLocation(program, 'u_mouseRadius');
    const uSpeed = gl.getUniformLocation(program, 'u_speed');
    const uBaseAlpha = gl.getUniformLocation(program, 'u_baseAlpha');
    const uMouseAlpha = gl.getUniformLocation(program, 'u_mouseAlpha');
    const uPulseIntensity = gl.getUniformLocation(program, 'u_pulseIntensity');

    gl.uniform3fv(uDotColor, new Float32Array(dotColor));
    gl.uniform3fv(uBgColor, new Float32Array(bgColor));
    gl.uniform1f(uDotSize, dotSize);
    gl.uniform1f(uGridSpacing, gridSpacing);
    gl.uniform1f(uMouseRadius, mouseRadius);
    gl.uniform1f(uSpeed, speed);
    gl.uniform1f(uBaseAlpha, baseAlpha);
    gl.uniform1f(uMouseAlpha, mouseAlpha);
    gl.uniform1f(uPulseIntensity, pulseIntensity);

    const startTime = performance.now();
    const frameInterval = 33; // ~30fps cap
    let lastFrame = 0;
    let isVisible = true;

    // FPS monitoring: disable shader if sustained low FPS
    let fpsSamples = [];
    const FPS_CHECK_INTERVAL = 3000; // check every 3s
    const FPS_THRESHOLD = 18; // disable below this
    let lastFpsCheck = performance.now();

    function disableShader() {
      canvas.style.display = 'none';
      document.body.style.background = `linear-gradient(135deg, rgb(${Math.round(bgColor[0]*255)},${Math.round(bgColor[1]*255)},${Math.round(bgColor[2]*255)}), rgb(${Math.round(bgColor[0]*400)},${Math.round(bgColor[1]*400)},${Math.round(bgColor[2]*400)}))`;
      gl.getExtension('WEBGL_lose_context')?.loseContext();
    }

    document.addEventListener('visibilitychange', () => {
      isVisible = !document.hidden;
      if (isVisible) { lastFrame = 0; fpsSamples = []; lastFpsCheck = performance.now(); }
    });

    function render(now) {
      if (!isVisible) { requestAnimationFrame(render); return; }
      if (now - lastFrame < frameInterval) { requestAnimationFrame(render); return; }

      // FPS tracking
      fpsSamples.push(now);
      if (now - lastFpsCheck > FPS_CHECK_INTERVAL && fpsSamples.length > 10) {
        const duration = (fpsSamples[fpsSamples.length - 1] - fpsSamples[0]) / 1000;
        const avgFps = fpsSamples.length / duration;
        if (avgFps < FPS_THRESHOLD) {
          console.warn(`Shader FPS too low (${avgFps.toFixed(1)}), disabling for performance.`);
          disableShader();
          return; // stop render loop
        }
        fpsSamples = [];
        lastFpsCheck = now;
      }

      lastFrame = now;

      const elapsed = (now - startTime) / 1000;
      gl.uniform1f(uTime, elapsed);
      gl.uniform2f(uResolution, canvas.width, canvas.height);
      gl.uniform2f(uMouse, mouseX, mouseY);
      gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);
      requestAnimationFrame(render);
    }

    requestAnimationFrame(render);
  }

  // ─── Start ──────────────────────────────────
  document.addEventListener('DOMContentLoaded', init);
})();
