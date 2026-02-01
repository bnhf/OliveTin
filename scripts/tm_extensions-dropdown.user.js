// ==UserScript==
// @name         Extensions Dropdown for CDVR WebUI
// @namespace    local
// @version      2026.01.26.1526
// @description  Adds an Extensions dropdown with container tools (live status detection)
// @author       bnhf
// @match        http*://*/admin/*
// @run-at       document-idle
// @grant        GM_xmlhttpRequest
// @connect      ${PORTAINER_HOST}
// ==/UserScript==
/* eslint-disable no-multi-spaces */

(() => {
  "use strict";

  // ============================================================
  // CONFIGURATION
  // ============================================================

  const NAV_ITEM_ID = "tm-extensions-nav-item";
  const TOGGLE_ID   = "tm-extensions-nav-dropdown";
  const MENU_ID     = "tm-extensions-dropdown-menu";

  // OliveTin base URL for API calls
  const OLIVETIN_BASE = "http://${PORTAINER_HOST}:1337";
  const EXTENSIONS_HOST = "${PORTAINER_HOST}";

  // Extension definitions with id (must match listactivewebuis output) and default port
  const extensions = [
    { id: "adbtuner", label: "ADBTuner", defaultPort: "5592" },
    { id: "ah4c", label: "ah4c", defaultPort: "7654" },
    { id: "eplustv", label: "EPlusTV", defaultPort: "8000" },
    { id: "espn4cc4c", label: "ESPNcc4c", defaultPort: "8094" },
    { id: "filebot", label: "FileBot", defaultPort: "5800" },
    { id: "frndlytv-for-channels", label: "FrndlyTV-for-Channels", defaultPort: "80" },
    { id: "fruitdeeplinks", label: "FruitDeepLinks", defaultPort: "6655" },
    { id: "mediainfo", label: "MediaInfo", defaultPort: "5800" },
    { id: "mlbserver", label: "mlbserver", defaultPort: "9999" },
    { id: "olivetin", label: "OliveTin-for-Channels", defaultPort: "1337" },
    { id: "organizr", label: "Organizr", defaultPort: "80" },
    { id: "plex-for-channels", label: "Plex-for-Channels", defaultPort: "7777" },
    { id: "pluto-for-channels", label: "Pluto-for-Channels", defaultPort: "7777" },
    { id: "portainer-ce", label: "Portainer", defaultPort: "9000" },
    { id: "prismcast", label: "PrismCast", defaultPort: "5589" },
    { id: "channels-remote-plus", label: "Remote+", defaultPort: "5000" },
    { id: "roku-ecp-tuner", label: "Roku Tuner Bridge", defaultPort: "5000" },
    { id: "samsung-tvplus-for-channels", label: "Samsung-TVPlus-for-Channels", defaultPort: "80" },
    { id: "stream-link-manager-for-channels", label: "Streamlink-Manager-for-Channels", defaultPort: "5000" },
    { id: "tubi-for-channels", label: "Tubi-for-Channels", defaultPort: "7777" },
    { id: "tv-logo-manager", label: "TV Logo Manager", defaultPort: "8084" },
    { id: "vlc-bridge-fubo", label: "VLC-Bridge-Fubo", defaultPort: "7777" },
    { id: "vlc-bridge-pbs", label: "VLC-Bridge-PBS", defaultPort: "7777" },
    { id: "vlc-bridge-uk", label: "VLC-Bridge-UK", defaultPort: "7777" },
  ];

  // ============================================================
  // API FUNCTIONS
  // ============================================================

  // Fetch active WebUIs from OliveTin API
  // Returns a Map of id -> port (e.g., { "portainer": "9000", "olivetin": "1337" })
  async function fetchActiveWebUIs() {
    return new Promise((resolve) => {
      GM_xmlhttpRequest({
        method: "GET",
        url: `${OLIVETIN_BASE}/api/StartActionByGetAndWait/listactivewebuis`,
        timeout: 5000,
        onload: (resp) => {
          if (resp.status >= 200 && resp.status < 300) {
            try {
              const obj = JSON.parse(resp.responseText);
              const output = obj?.logEntry?.output ?? "";
              // Parse space-separated id:port pairs
              const activeMap = new Map();
              const pairs = output.trim().split(/\s+/).filter(s => s.length > 0);
              for (const pair of pairs) {
                const colonIndex = pair.indexOf(":");
                if (colonIndex > 0) {
                  const id = pair.substring(0, colonIndex);
                  const port = pair.substring(colonIndex + 1);
                  activeMap.set(id, port);
                }
              }
              resolve(activeMap);
            } catch {
              resolve(new Map());
            }
          } else {
            resolve(new Map());
          }
        },
        onerror: () => resolve(new Map()),
        ontimeout: () => resolve(new Map()),
      });
    });
  }

  // Update extension menu items with live status and ports
  function updateExtensionIndicators(menu, activeMap) {
    menu.querySelectorAll(".dropdown-item[data-extension-id]").forEach(item => {
      const extId = item.dataset.extensionId;
      const label = item.dataset.extensionLabel;
      const defaultPort = item.dataset.defaultPort;
      const isActive = activeMap.has(extId);
      const port = isActive ? activeMap.get(extId) : defaultPort;
      const href = `http://${EXTENSIONS_HOST}:${port}`;

      // Store the computed href for click handling
      item.dataset.href = href;

      if (isActive) {
        item.innerHTML = `<span style="color: #4CAF50; margin-right: 6px;">●</span><span style="color: #fff;">${label}</span>`;
        item.title = `Running - ${href}`;
        item.style.opacity = "1";
      } else {
        item.innerHTML = `<span style="color: #999; margin-right: 6px;">○</span><span style="color: rgba(255,255,255,0.6);">${label}</span>`;
        item.title = `Not detected - default port ${defaultPort}`;
        item.style.opacity = "0.6";
      }
    });
  }

  // ============================================================
  // MENU HELPERS
  // ============================================================

  function isOpen(wrapper, menu) {
    return wrapper.classList.contains("show") || menu.classList.contains("show");
  }

  function setOpen(wrapper, toggle, menu, open) {
    wrapper.classList.toggle("show", open);
    menu.classList.toggle("show", open);
    toggle.setAttribute("aria-expanded", String(open));
  }

  function closeAllExcept(exceptWrapperId) {
    document.querySelectorAll(".nav-item.dropdown").forEach(w => {
      const menu = w.querySelector(":scope > .dropdown-menu");
      const toggle = w.querySelector(":scope > .nav-link.dropdown-toggle");
      if (!menu || !toggle) return;

      if (w.id === exceptWrapperId) return;

      // Close all dropdowns (both native and custom)
      w.classList.remove("show");
      menu.classList.remove("show");
      toggle.setAttribute("aria-expanded", "false");
    });
  }

  // ============================================================
  // INJECTION
  // ============================================================

  function inject() {
    if (document.getElementById(NAV_ITEM_ID)) return true;

    const navRow = document.querySelector("nav.navbar .navbar-collapse .navbar-nav");
    if (!navRow) return false;

    const settingsItem =
      document.querySelector("#settings-nav-dropdown")?.closest(".nav-item");

    const wrapper = document.createElement("div");
    wrapper.id = NAV_ITEM_ID;
    wrapper.className = "nav-item dropdown";
    wrapper.dataset.tmDropdown = "1";

    const toggle = document.createElement("a");
    toggle.id = TOGGLE_ID;
    toggle.href = "#";
    toggle.className = "dropdown-toggle nav-link";
    toggle.setAttribute("role", "button");
    toggle.setAttribute("aria-haspopup", "true");
    toggle.setAttribute("aria-expanded", "false");

    toggle.innerHTML = `<svg aria-hidden="true" focusable="false" data-prefix="fas" data-icon="cube" class="svg-inline--fa fa-cube fa-w-16 mr-1" role="img" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512"><path fill="currentColor" d="M234.5 5.7c13.9-5.5 29.1-5.5 43 0l192 76.8C487 89.4 512 106.3 512 128l0 256c0 21.7-25 38.6-42.5 45.5l-192 76.8c-13.9 5.5-29.1 5.5-43 0l-192-76.8C25 422.6 0 405.7 0 384l0-256c0-21.7 25-38.6 42.5-45.5l192-76.8zM256 416l0-166.9L96 192l0 170.4L256 416zm0-233.1l156.6-62.7L256 57.2 99.4 120.2 256 182.9zM416 192l-128 51.2 0 166.9 128-51.3 0-166.8z"/></svg><span>Extensions</span>`;

    const menu = document.createElement("div");
    menu.id = MENU_ID;
    menu.className = "dropdown-menu";
    menu.setAttribute("aria-labelledby", TOGGLE_ID);
    menu.style.margin = "0px";

    // Add header descriptor
    const header = document.createElement("h6");
    header.className = "dropdown-header";
    header.style.fontSize = "inherit";
    header.textContent = "Go to Project WebUI:";
    menu.appendChild(header);

    // Add divider line
    const divider = document.createElement("div");
    divider.className = "dropdown-divider";
    menu.appendChild(divider);

    // Build menu items from extensions config (initially in "loading" state)
    for (const ext of extensions) {
      const item = document.createElement("a");
      item.className = "dropdown-item";
      item.href = "#"; // prevent default navigation
      item.dataset.extensionId = ext.id;
      item.dataset.extensionLabel = ext.label;
      item.dataset.defaultPort = ext.defaultPort;
      item.dataset.href = `http://${EXTENSIONS_HOST}:${ext.defaultPort}`; // initial default

      // Initial state: show as inactive until we fetch live status
      item.innerHTML = `<span style="color: #999; margin-right: 6px;">○</span><span style="color: rgba(255,255,255,0.6);">${ext.label}</span>`;
      item.title = `Checking status...`;
      item.style.opacity = "0.6";

      item.addEventListener("click", (e) => {
        e.preventDefault();
        e.stopPropagation();
        setOpen(wrapper, toggle, menu, false);
        // Navigate to the dynamically-determined URL
        const targetHref = item.dataset.href;
        if (targetHref) {
          window.location.href = targetHref;
        }
      });

      menu.appendChild(item);
    }

    // Toggle open/close on click - now async to fetch live status
    toggle.addEventListener("click", async (e) => {
      e.preventDefault();
      e.stopPropagation();

      const wasOpen = isOpen(wrapper, menu);
      closeAllExcept(wrapper.id);

      if (!wasOpen) {
        // Fetch active WebUIs and update indicators before opening
        const activeMap = await fetchActiveWebUIs();
        updateExtensionIndicators(menu, activeMap);
      }

      setOpen(wrapper, toggle, menu, !wasOpen);
    });

    // Close when clicking anywhere outside the dropdown
    document.addEventListener("click", (e) => {
      if (!isOpen(wrapper, menu)) return;
      if (wrapper.contains(e.target)) return;
      setOpen(wrapper, toggle, menu, false);
    }, { capture: true });

    wrapper.appendChild(toggle);
    wrapper.appendChild(menu);

    // Insert after One-Click dropdown if present, otherwise after settings
    const oneClickItem = document.getElementById("tm-oneclick-nav-item");
    if (oneClickItem?.parentElement === navRow) {
      oneClickItem.after(wrapper);
    } else if (settingsItem?.parentElement === navRow) {
      settingsItem.after(wrapper);
    } else {
      navRow.appendChild(wrapper);
    }

    return true;
  }

  // Initial + SPA-safe retries
  if (inject()) return;

  const obs = new MutationObserver(() => inject());
  obs.observe(document.documentElement, { childList: true, subtree: true });
  setTimeout(() => obs.disconnect(), 30000);
})();
