// ==UserScript==
// @name         Manage Lineup Helper for CDVR WebUI
// @namespace    http://tampermonkey.net/
// @version      2026.01.21.1755
// @description  Adapted from bookmarklet for ChannelsDVR Manage Lineup modal (sort/filter/block/favorite)
// @author       Kenneth Scott
// @match        http*://*/admin/*
// @run-at       document-idle
// @grant        GM_xmlhttpRequest
// @connect      api.pluto.tv
// ==/UserScript==
/* eslint-disable no-multi-spaces */

(function () {
  'use strict';

  // ---- Bookmarklet code (minimally modified for TM) ----
  (async () => {

    const dropdownId = 'channels-helper-commands';
    const filterId   = 'channels-helper-filter';
    const spinnerId  = 'channels-helper-spinner';

    const baseSelectors = {
      modalDialog:   '.modal-dialog',
      modalCard:     '.modal-body > .card',
      listGroup:     '.list-group',
      listGroupItem: '.list-group-item',
      visibleListGroupItem: '.list-group-item:not(.d-none)'
    };

    const selectors = {
      toolbar:         `${baseSelectors.modalCard} > .card-header`,
      channelRow:      `${baseSelectors.modalCard} > ${baseSelectors.listGroup} > ${baseSelectors.listGroupItem}`,
      channelContent:  '.row > .col-sm-6 > span',  // within channelRow
      favorites:       `${baseSelectors.modalCard} ${baseSelectors.visibleListGroupItem} [aria-label="favorited"]>.glyphicon-heart`,
      allFavorites:    `${baseSelectors.modalCard} [aria-label="favorited"]>.glyphicon-heart`,
      unfavorites:     `${baseSelectors.modalCard} ${baseSelectors.visibleListGroupItem} [aria-label="not favorited"]>.glyphicon-heart-empty`,
      allUnfavorites:  `${baseSelectors.modalCard} [aria-label="not favorited"]>.glyphicon-heart-empty`,
      blocked:         `${baseSelectors.modalCard} ${baseSelectors.visibleListGroupItem} [aria-label="hidden"]>.glyphicon-ban-circle`,
      allBlocked:      `${baseSelectors.modalCard} [aria-label="hidden"]>.glyphicon-ban-circle`,
      unblocked:       `${baseSelectors.modalCard} ${baseSelectors.visibleListGroupItem} [aria-label="not hidden"]>.glyphicon-ban-circle`,
      allUnblocked:    `${baseSelectors.modalCard} [aria-label="not hidden"]>.glyphicon-ban-circle`,
    };

    function getToolbar()      { return document.querySelector(selectors.toolbar); }
    function getModalDialog()  { return document.querySelector(baseSelectors.modalDialog); }
    function getChannelRows()  { return document.querySelectorAll(selectors.channelRow); }
    function getDropdown()     { return document.querySelector(`#${dropdownId}`); }
    function getSpinner()      { return document.querySelector(`#${spinnerId}`); }

    function loading(show) {
      const sp = getSpinner();
      if (sp) sp.style.display = show ? 'block' : 'none';
      const ddl = getDropdown();
      if (ddl) ddl.disabled = !!show;
    }

    // Private helper functions
    function sortItems(compareFunction) {
      return function() {
        const channelRows = getChannelRows();
        if (!channelRows || channelRows.length === 0) return;

        loading(true);

        const items = Array.from(channelRows);
        items.sort(compareFunction);

        const container = channelRows[0].parentNode;
        if (!container) { loading(false); return; }
        const containerParent = container.parentNode;
        if (!containerParent) { loading(false); return; }

        containerParent.removeChild(container);
        container.innerHTML = '';

        const fragment = document.createDocumentFragment();
        items.forEach(item => fragment.appendChild(item));

        container.appendChild(fragment);
        containerParent.appendChild(container);

        loading(false);
      };
    }

    function getChannelContent(channelRow) {
      return channelRow.querySelector(selectors.channelContent);
    }

    function getChannelName(channelRow) {
      const content = getChannelContent(channelRow);
      return content?.childNodes?.[2]?.textContent?.trim() ?? '';
    }

    function getChannelNumber(channelRow) {
      const content = getChannelContent(channelRow);
      return content?.childNodes?.[0]?.textContent?.trim() ?? '';
    }

    function getChannelCategory(channelRow) {
      const content = getChannelContent(channelRow);
      return content?.querySelector('.category')?.textContent?.trim();
    }

    function compareByName(a, b) {
      const textA = getChannelName(a).toLowerCase();
      const textB = getChannelName(b).toLowerCase();
      return textA.localeCompare(textB);
    }

    function compareByNumber(a, b) {
      const textA = getChannelNumber(a);
      const textB = getChannelNumber(b);
      return textA.localeCompare(textB, 'en', { numeric: true });
    }

    function compareByCategoryThenName(a, b) {
      const categoryA = getChannelCategory(a)?.toLowerCase() ?? "";
      const categoryB = getChannelCategory(b)?.toLowerCase() ?? "";

      const categoryComparison = categoryA.localeCompare(categoryB);
      if (categoryComparison !== 0) return categoryComparison;

      const nameA = getChannelName(a).toLowerCase();
      const nameB = getChannelName(b).toLowerCase();
      return nameA.localeCompare(nameB);
    }

    function compareByCategoryThenNumber(a, b) {
      const categoryA = getChannelCategory(a)?.toLowerCase() ?? "";
      const categoryB = getChannelCategory(b)?.toLowerCase() ?? "";

      const categoryComparison = categoryA.localeCompare(categoryB);
      if (categoryComparison !== 0) return categoryComparison;

      const numberA = getChannelNumber(a);
      const numberB = getChannelNumber(b);
      return numberA.localeCompare(numberB, 'en', { numeric: true });
    }

    function showHideThem(selector) {
      return function() {
        Array.from(document.querySelectorAll(selector)).forEach((el, i) => {
          if (i % 2 !== 0) return;
          const elRow = el.closest(selectors.channelRow);
          if (!elRow) return;
          elRow.classList.toggle('d-none');
        });
      };
    }

    function showThemAll() {
      return function() {
        Array.from(document.querySelectorAll(selectors.channelRow)).forEach(row => {
          row.classList.remove('d-none');
        });
      };
    }

    function clickThem(selector, confirmationMessage) {
      return function() {
        if (confirmationMessage && !confirm(confirmationMessage)) return;

        const elements = Array.from(document.querySelectorAll(selector));
        let index = 0;

        function processNext() {
          if (index < elements.length) {
            if (index % 2 === 0) elements[index].click();
            index++;
            setTimeout(processNext, 0);
          } else {
            loading(false);
          }
        }

        loading(true);
        processNext();
      };
    }

    async function augmentChannels() {
      const channelRows = getChannelRows();
      if (!channelRows || channelRows.length === 0) return;

      let plutoChannels = {};
      try { plutoChannels = await fetchPlutoChannels() ?? {}; } catch (ex) {}

      for (const channelRow of channelRows) {
        const channelNumber = getChannelNumber(channelRow);
        if (!channelNumber) continue;

        const content = getChannelContent(channelRow);
        if (!content) continue;

        const category = window.DVR?.channels?.[channelNumber]?.Categories?.toString?.() ?? "";
        if (category && !content.querySelector('.category')) {
          const span = document.createElement('span');
          span.className = 'badge badge-primary mx-1 category';
          span.textContent = category;
          content.appendChild(span);
        }

        const stationId = window.DVR?.channels?.[channelNumber]?.Station;

        let description = window.DVR?.channels?.[channelNumber]?.Description;

        if (!description && stationId) {
          description = plutoChannels?.[stationId]?.summary;
        }

        if (description && !content.querySelector('.tooltip-target.glyphicon-info-sign')) {
          const span = document.createElement('span');
          span.classList.add("tooltip-target", "glyphicon", "glyphicon-info-sign", "mx-1");
          span.title = String(description);
          content.appendChild(span);
        }
      }
    }

    function createDropdown() {
      const commands = {
        '': 'Select a command...',
        'block': 'Block Channels',
        'unblock': 'Unblock Channels',
        'showHideBlocked': 'Show/Hide Blocked Channels',
        'showHideUnblocked': 'Show/Hide Unblocked Channels',
        'favorite': 'Favorite Channels',
        'unfavorite': 'Unfavorite Channels',
        'showHideFavorites': 'Show/Hide Favorites',
        'showHideUnfavorites': 'Show/Hide Unfavorites',
        'sortByCategoryThenChannelName': 'Sort by Category then Channel Name',
        'sortByCategoryThenChannelNumber': 'Sort by Category then Channel Number',
        'sortByChannelName': 'Sort by Channel Name',
        'sortByChannelNumber': 'Sort by Channel Number',
        'showThemAll': 'Show all Channels'
      };

      const ddl = document.createElement('select');
      ddl.id = dropdownId;
      ddl.name = ddl.id;
      ddl.classList.add('form-control', 'form-control-sm', 'py-0');
      ddl.style.cssText = 'width: 200px; height: 1.75rem;';

      ddl.addEventListener('change', function() {
        const action = this.value;
        if (action && ChannelsHelper[action]) {
          ChannelsHelper[action]();
          this.value = '';
        }
      });

      for (const key in commands) {
        const option = document.createElement("option");
        option.value = key;
        option.text = commands[key];
        ddl.appendChild(option);
      }

      return ddl;
    }

    function createFilter() {
      const filter = document.createElement('input');
      filter.id = filterId;
      filter.name = filter.id;
      filter.type = 'search';
      filter.classList.add('form-control', 'form-control-sm');
      filter.style.cssText = 'width: 200px; height: 1.75rem;';
      filter.placeholder = 'Type to filter...';

      filter.addEventListener('input', function(e) {
        const filterText = (e.target.value ?? '').toLowerCase();
        filterChannels(filterText);
      });

      return filter;
    }

    function filterChannels(filterText) {
      const channelRows = getChannelRows();
      channelRows.forEach(channelRow => {
        const text = (channelRow.textContent ?? '').toLowerCase();
        if (text.includes(filterText)) channelRow.classList.remove('d-none');
        else channelRow.classList.add('d-none');
      });
    }

    function createSpinner() {
      const spinner = document.createElement('div');
      spinner.id = spinnerId;
      spinner.classList.add('spinner-border', 'spinner-border-sm', 'float-right');
      spinner.style.cssText = 'margin-right: .5rem; margin-top: .2rem; display: none;';
      return spinner;
    }

    // CORS-safe Pluto fetch for Tampermonkey
    async function fetchPlutoChannels() {
      return await new Promise((resolve) => {
        GM_xmlhttpRequest({
          method: "GET",
          url: "http://api.pluto.tv/v2/channels",
          onload: (resp) => {
            try {
              const data = JSON.parse(resp.responseText);
              const lookupTable = data.reduce((acc, channel) => {
                if (channel._id && channel.name && channel.summary) {
                  acc[channel._id] = { name: channel.name, summary: channel.summary };
                }
                return acc;
              }, {});
              resolve(lookupTable);
            } catch (e) {
              console.error("Problem parsing pluto channels listing:", e);
              resolve({});
            }
          },
          onerror: (e) => {
            console.error("Problem fetching pluto channels listing:", e);
            resolve({});
          }
        });
      });
    }

    const ChannelsHelper = {

      block: clickThem(selectors.unblocked, 'Are you sure you want to block all channels shown? This may take a minute...'),

      unblock: clickThem(selectors.blocked, 'Are you sure you want to unblock all channels shown? This may take a minute...'),

      showHideBlocked: showHideThem(selectors.allBlocked),

      showHideUnblocked: showHideThem(selectors.allUnblocked),

      favorite: clickThem(selectors.unfavorites, 'Are you sure you want to favorite all channels shown? This may take a minute...'),

      unfavorite: clickThem(selectors.favorites, 'Are you sure you want to unfavorite all channels shown? This may take a minute...'),

      showHideFavorites: showHideThem(selectors.allFavorites),

      showHideUnfavorites: showHideThem(selectors.allUnfavorites),

      sortByCategoryThenChannelName: sortItems(compareByCategoryThenName),

      sortByCategoryThenChannelNumber: sortItems(compareByCategoryThenNumber),

      sortByChannelName: sortItems(compareByName),

      sortByChannelNumber: sortItems(compareByNumber),

      showThemAll: showThemAll(),

      init: async function() {
        const modal = getModalDialog();
        const toolbar = getToolbar();
        if (!modal || !toolbar) return;

        modal.style.cssText = 'max-width: 1000px;';

        if (toolbar && !getDropdown()) {
          // Create a flex container for the controls (centered between title and Scan button)
          const controlsWrapper = document.createElement('div');
          controlsWrapper.style.cssText = 'display: flex; align-items: center; justify-content: center; gap: 10px;';

          const filter = createFilter();
          const ddl = createDropdown();
          const spinner = createSpinner();

          controlsWrapper.append(filter);
          controlsWrapper.append(ddl);
          controlsWrapper.append(spinner);

          // Make toolbar a flex container with space-between
          toolbar.style.cssText = 'display: flex; align-items: center; justify-content: space-between; gap: 10px;';

          // Find the existing Scan button (if any) to insert controls before it
          const scanButton = toolbar.querySelector('a[href*="scan"], button');
          if (scanButton) {
            toolbar.insertBefore(controlsWrapper, scanButton);
          } else {
            toolbar.append(controlsWrapper);
          }
        }

        loading(true);
        await augmentChannels();
        loading(false);
      }
    };

    // --- Key Tampermonkey adaptation: watch for Manage Lineup modal ---
    function watchForManageLineupModal() {
      // Try immediately (in case modal is already open)
      if (getModalDialog() && getToolbar() && !getDropdown()) {
        ChannelsHelper.init();
      }

      // Keep watching for modal opening/reopening (don't disconnect)
      const obs = new MutationObserver(() => {
        // Only init if modal exists, toolbar exists, but our dropdown doesn't yet
        if (getModalDialog() && getToolbar() && !getDropdown()) {
          ChannelsHelper.init();
        }
      });

      obs.observe(document.body, { childList: true, subtree: true });
    }

    watchForManageLineupModal();

  })();
})();
