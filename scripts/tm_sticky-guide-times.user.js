// ==UserScript==
// @name         Sticky Guide Times for CDVR WebUI
// @namespace    local
// @version      2026.03.07.2040
// @description  Keeps the program guide times row visible when scrolling down
// @author       bnhf
// @match        http*://*/admin/*
// @run-at       document-idle
// @grant        none
// ==/UserScript==
/* eslint-disable no-multi-spaces */

// How this works:
// The admin guide (/admin/guide/grid) renders times inside div.guide-rows which has
// overflowX:scroll / overflowY:hidden — making position:sticky impossible on children.
// This script creates a fixed-position clone of the times row that:
//   - Appears only when the original row has scrolled above the navbar
//   - Matches the width/left-offset of div.guide-rows
//   - Mirrors the horizontal scroll of div.guide-rows via CSS translateX
// When a source filter changes, React replaces the .guide-rows element entirely.
// The MutationObserver keeps running and detects the new element via identity check.

(() => {
  "use strict";

  const CLONE_ID       = 'tm-sticky-times-clone';
  let currentGuideRows = null;   // tracks which .guide-rows element we're attached to
  let listenerCleanup  = null;   // removes scroll/resize listeners for the current element
  let domObserver      = null;
  let setupPending     = false;  // rAF throttle for observer

  // ============================================================
  // HELPERS
  // ============================================================

  function isGuidePage() {
    return /\/guide/.test(window.location.href);
  }

  function getNavbarHeight() {
    for (const sel of ['.navbar', 'nav.navbar', 'nav[class]']) {
      const el = document.querySelector(sel);
      if (el) return Math.round(el.getBoundingClientRect().height);
    }
    return 50;
  }

  // ============================================================
  // SETUP — idempotent for the same .guide-rows element;
  //         re-initialises automatically when element is replaced
  // ============================================================

  function setup() {
    const guideRows = document.querySelector('.guide-rows');
    if (!guideRows) return;

    // The times row is the first child div of .guide-rows (no class name)
    const timesRow = guideRows.firstElementChild;
    if (!timesRow || !timesRow.querySelector('.guide-time-cell')) return;

    // Same element already initialised — nothing to do
    if (guideRows === currentGuideRows) return;

    // New element (page load or source-filter re-render) — clean up previous
    if (listenerCleanup) { listenerCleanup(); listenerCleanup = null; }
    document.getElementById(CLONE_ID)?.remove();
    currentGuideRows = guideRows;

    const navbarH = getNavbarHeight();

    // ---- Build the clone ----
    const clone = document.createElement('div');
    clone.id = CLONE_ID;
    clone.style.cssText = [
      'position:fixed',
      `top:${navbarH}px`,
      'left:0',
      'z-index:1001',
      'overflow:hidden',
      'display:none',
      'pointer-events:none',
      'box-shadow:0 2px 6px rgba(0,0,0,0.4)',
    ].join(';');

    // Inner wrapper — translateX mirrors horizontal scroll
    const inner = document.createElement('div');
    inner.style.cssText = 'position:relative;white-space:nowrap;height:25px;';

    // Detect background
    const bg       = window.getComputedStyle(timesRow).backgroundColor;
    const parentBg = window.getComputedStyle(guideRows).backgroundColor;
    clone.style.backgroundColor =
      (bg       && bg       !== 'rgba(0, 0, 0, 0)' && bg       !== 'transparent') ? bg :
      (parentBg && parentBg !== 'rgba(0, 0, 0, 0)' && parentBg !== 'transparent') ? parentBg :
      '#fff';

    function rebuildCells() {
      inner.innerHTML = '';
      Array.from(timesRow.children).forEach(cell => inner.appendChild(cell.cloneNode(true)));
    }
    rebuildCells();

    clone.appendChild(inner);
    document.body.appendChild(clone);

    // ---- Sync helpers ----
    function syncPosition() {
      const rect = guideRows.getBoundingClientRect();
      clone.style.left  = `${rect.left}px`;
      clone.style.width = `${rect.width}px`;
    }

    function syncScroll() {
      inner.style.transform = `translateX(-${guideRows.scrollLeft}px)`;
    }

    function syncVisibility() {
      const rect = timesRow.getBoundingClientRect();
      const scrolledOff = rect.bottom <= navbarH + 2;
      clone.style.display = scrolledOff ? 'block' : 'none';
      if (scrolledOff) { syncPosition(); syncScroll(); }
    }

    // Initial sync
    syncPosition();
    syncScroll();
    syncVisibility();

    // ---- Event listeners ----
    const onScroll  = ()  => syncVisibility();
    const onHScroll = ()  => { syncScroll(); syncVisibility(); };
    const onResize  = ()  => { syncPosition(); syncScroll(); };

    window.addEventListener('scroll',    onScroll,  { passive: true });
    guideRows.addEventListener('scroll', onHScroll, { passive: true });
    window.addEventListener('resize',    onResize,  { passive: true });

    // Refresh clone cells if guide auto-updates its time labels
    const cellObserver = new MutationObserver(rebuildCells);
    cellObserver.observe(timesRow, { childList: true });

    listenerCleanup = () => {
      window.removeEventListener('scroll',    onScroll);
      guideRows.removeEventListener('scroll', onHScroll);
      window.removeEventListener('resize',    onResize);
      cellObserver.disconnect();
      document.getElementById(CLONE_ID)?.remove();
      currentGuideRows = null;
    };

    console.debug('[TM Sticky Guide Times] Initialised for', guideRows);
  }

  // ============================================================
  // DOM OBSERVER — stays running on guide page to catch re-renders
  // ============================================================

  function startObserver() {
    if (domObserver) domObserver.disconnect();
    domObserver = new MutationObserver(() => {
      // Throttle to one setup attempt per animation frame
      if (!setupPending) {
        setupPending = true;
        requestAnimationFrame(() => { setupPending = false; setup(); });
      }
    });
    domObserver.observe(document.body, { childList: true, subtree: true });
  }

  function stopObserver() {
    if (domObserver) { domObserver.disconnect(); domObserver = null; }
  }

  // ============================================================
  // NAVIGATION (SPA)
  // ============================================================

  function teardown() {
    stopObserver();
    if (listenerCleanup) { listenerCleanup(); listenerCleanup = null; }
  }

  function onNavigate() {
    teardown();
    if (isGuidePage()) {
      setup();          // try immediately
      startObserver();  // keep watching for source-filter re-renders
    }
  }

  const _push = history.pushState.bind(history);
  history.pushState = function (...args) { _push(...args); setTimeout(onNavigate, 150); };
  window.addEventListener('popstate',   () => setTimeout(onNavigate, 150));
  window.addEventListener('hashchange', () => setTimeout(onNavigate, 150));

  setTimeout(onNavigate, 600);

})();
