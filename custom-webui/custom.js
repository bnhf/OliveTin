// OliveTin-for-Channels Custom JavaScript
// Place this file in custom-webui/custom.js
// Enable with: enableCustomJs: true in config.yaml
// 2026.01.19-5

console.log('OliveTin custom.js loaded');

// 1. Prevent action dialog from auto-opening on config changes
(function() {
  // Track if config just changed to prevent auto-triggering
  let configChangeInProgress = false;
  let urlCleanupTimer = null;

  // Function to clear the action parameter from URL
  function clearActionParameter() {
    const url = new URL(window.location.href);
    if (url.searchParams.has('action')) {
      console.log('Clearing action parameter from URL:', url.searchParams.get('action'));
      url.searchParams.delete('action');
      window.history.replaceState({}, '', url.toString());
      return true;
    }
    return false;
  }

  // Clear on initial load
  window.addEventListener('load', clearActionParameter);

  // Also try clearing early, before load event
  window.addEventListener('DOMContentLoaded', clearActionParameter);

  // Listen for config change events
  window.addEventListener('EventConfigChanged', function() {
    console.log('Config changed - preventing action auto-trigger');
    configChangeInProgress = true;

    // Clear the action parameter immediately
    clearActionParameter();

    // Keep blocking auto-triggers for 2 seconds after config change
    clearTimeout(urlCleanupTimer);
    urlCleanupTimer = setTimeout(function() {
      configChangeInProgress = false;
      console.log('Config change cooldown expired');
    }, 2000);
  });

  // Intercept the checkAndTriggerActionFromQueryParam function
  // This runs as soon as the script loads, before marshaller.js functions run

  // Poll until the function exists, then wrap it
  function interceptCheckFunction() {
    if (typeof window.checkAndTriggerActionFromQueryParam === 'function') {
      const original = window.checkAndTriggerActionFromQueryParam;

      window.checkAndTriggerActionFromQueryParam = function() {
        if (configChangeInProgress) {
          console.log('Blocked auto-trigger due to recent config change');
          clearActionParameter();
          return false;
        }
        return original.apply(this, arguments);
      };

      console.log('✓ Successfully intercepted checkAndTriggerActionFromQueryParam');
    } else {
      // Function doesn't exist yet, try again shortly
      setTimeout(interceptCheckFunction, 50);
    }
  }

  // Start trying to intercept immediately
  interceptCheckFunction();

  // Also periodically clean up the URL parameter as a safety net
  setInterval(function() {
    if (configChangeInProgress) {
      clearActionParameter();
    }
  }, 200);
})();

// 2. Apply horizontal scrolling fix to xterm terminal
function applyHorizontalScrollFix() {
  const xtermDiv = document.getElementById('execution-dialog-xterm');

  if (!xtermDiv) {
    console.log('xterm div not found yet');
    return false;
  }

  console.log('✓ xterm.js terminal found');
  console.log('Terminal element:', xtermDiv);
  console.log('Terminal offsetWidth:', xtermDiv.offsetWidth);
  console.log('Terminal scrollWidth:', xtermDiv.scrollWidth);

  // Find all xterm sub-elements
  const viewport = xtermDiv.querySelector('.xterm-viewport');
  const screen = xtermDiv.querySelector('.xterm-screen');
  const rows = xtermDiv.querySelector('.xterm-rows');

  console.log('Viewport element:', viewport);
  console.log('Screen element:', screen);
  console.log('Rows element:', rows);

  if (viewport) {
    console.log('Viewport offsetWidth:', viewport.offsetWidth);
    console.log('Viewport scrollWidth:', viewport.scrollWidth);
  }

  if (screen) {
    console.log('Screen offsetWidth:', screen.offsetWidth);
    console.log('Screen scrollWidth:', screen.scrollWidth);
  }

  if (rows) {
    console.log('Rows offsetWidth:', rows.offsetWidth);
    console.log('Rows scrollWidth:', rows.scrollWidth);
    console.log('First few row divs:', rows.querySelectorAll(':scope > div').length);
  }

  return true;
}

// Watch for when execution dialog is shown
const observer = new MutationObserver(function(mutations) {
  mutations.forEach(function(mutation) {
    if (mutation.type === 'attributes' && mutation.attributeName === 'open') {
      const dialog = mutation.target;
      if (dialog.id === 'execution-results-popup' && dialog.open) {
        console.log('Execution dialog opened - checking terminal');
        setTimeout(function() {
          applyHorizontalScrollFix();
        }, 100);
      }
    }
  });
});

// Start observing the dialog
window.addEventListener('DOMContentLoaded', function() {
  const dialog = document.querySelector('dialog#execution-results-popup');
  if (dialog) {
    observer.observe(dialog, { attributes: true });
    console.log('Observing execution dialog for open state');
  }
});

// 3. Restore "always use config defaults" behavior for argument forms
(function() {
  console.log('Setting up argument form default value fix...');

  // Clear all argument-related query parameters when action buttons are clicked
  // This ensures forms always load with config defaults, not sticky values
  function clearArgumentParameters() {
    const url = new URL(window.location.href);
    let hasParams = false;
    const paramsToDelete = [];

    // Collect all non-action parameters (these are argument values)
    for (const [key, value] of url.searchParams.entries()) {
      if (key !== 'action') {
        paramsToDelete.push(key);
        hasParams = true;
      }
    }

    // Delete all argument parameters
    if (hasParams) {
      paramsToDelete.forEach(param => url.searchParams.delete(param));
      window.history.replaceState({}, '', url.toString());
      console.log('Cleared argument parameters:', paramsToDelete);
      return true;
    }
    return false;
  }

  // Intercept ArgumentForm.setup() to clear parameters before form is created
  function interceptArgumentForm() {
    // Wait for the custom element to be defined
    if (typeof window.customElements.get('argument-form') === 'undefined') {
      setTimeout(interceptArgumentForm, 50);
      return;
    }

    const originalSetup = window.customElements.get('argument-form').prototype.setup;

    if (originalSetup && !originalSetup._intercepted) {
      window.customElements.get('argument-form').prototype.setup = function(json, callback) {
        // Clear argument parameters when form is being set up
        clearArgumentParameters();

        // Call original setup
        return originalSetup.call(this, json, callback);
      };

      window.customElements.get('argument-form').prototype.setup._intercepted = true;
      console.log('✓ Successfully intercepted ArgumentForm.setup()');
    }
  }

  // Start intercepting
  interceptArgumentForm();

  // Also override the updateUrlWithArg function to prevent saving values to URL
  function disableUrlUpdates() {
    // Poll until ArgumentForm is available
    if (typeof window.customElements.get('argument-form') === 'undefined') {
      setTimeout(disableUrlUpdates, 50);
      return;
    }

    const ArgumentFormClass = window.customElements.get('argument-form');

    if (ArgumentFormClass && ArgumentFormClass.prototype.updateUrlWithArg) {
      // Replace with a no-op function to prevent sticky behavior
      ArgumentFormClass.prototype.updateUrlWithArg = function(ev) {
        // Do nothing - don't save argument values to URL
        console.log('Prevented sticky value save for:', ev.target.name);
      };

      console.log('✓ Disabled sticky argument values (updateUrlWithArg)');
    }
  }

  // Disable URL updates to prevent sticky behavior
  disableUrlUpdates();

  // Clear parameters when EventConfigChanged fires (belt and suspenders)
  window.addEventListener('EventConfigChanged', function() {
    clearArgumentParameters();
  });
})();

// 4. Prevent pop-ups from showing for executions not triggered by this browser
(function() {
  console.log('Setting up execution dialog filter...');

  // Track execution IDs that were triggered by THIS browser session
  const myExecutions = new Set();

  // Intercept ActionButton.startAction() to track our own executions
  function interceptActionButton() {
    if (typeof window.customElements.get('action-button') === 'undefined') {
      setTimeout(interceptActionButton, 50);
      return;
    }

    const ActionButtonClass = window.customElements.get('action-button');

    if (ActionButtonClass && ActionButtonClass.prototype.startAction) {
      const originalStartAction = ActionButtonClass.prototype.startAction;

      if (!originalStartAction._intercepted) {
        ActionButtonClass.prototype.startAction = function(actionArgs) {
          // Generate the tracking ID (copied from original logic)
          const trackingId = this.getUniqueId();

          // Store it as "my execution"
          myExecutions.add(trackingId);
          console.log('Tracking my execution:', trackingId);

          // Clean up old tracking IDs after 5 minutes
          setTimeout(function() {
            myExecutions.delete(trackingId);
          }, 5 * 60 * 1000);

          // Call original with modified arguments to use our tracking ID
          if (actionArgs === undefined) {
            actionArgs = [];
          }

          const startActionArgs = {
            actionId: this.actionId,
            arguments: actionArgs,
            uniqueTrackingId: trackingId
          };

          this.onActionStarted(startActionArgs.uniqueTrackingId);

          window.fetch(window.restBaseUrl + 'StartAction', {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json'
            },
            body: JSON.stringify(startActionArgs)
          }).then((res) => {
            if (res.ok) {
              return res.json();
            } else {
              throw new Error(res.statusText);
            }
          }).then((json) => {
            // Fire & forget
          }).catch(err => {
            throw err;
          });
        };

        ActionButtonClass.prototype.startAction._intercepted = true;
        console.log('✓ Successfully intercepted ActionButton.startAction()');
      }
    }
  }

  // Start intercepting action button
  interceptActionButton();

  // Intercept at the EventExecutionFinished handler level
  // We need to catch this BEFORE the marshaller processes it
  window.addEventListener('EventExecutionFinished', function(evt) {
    // This runs BEFORE the main handler since we register it earlier
    const logEntry = evt.payload ? evt.payload.logEntry : null;

    if (!logEntry) {
      return;
    }

    // Check both possible field names
    const trackingId = logEntry.executionTrackingId || logEntry.uuid;

    if (!trackingId) {
      console.log('EventExecutionFinished: No tracking ID found');
      return;
    }

    if (!myExecutions.has(trackingId)) {
      console.log('EventExecutionFinished: External execution detected, will suppress dialog:', trackingId);

      // Mark the action button to prevent popup
      const actionButton = window.actionButtons ? window.actionButtons[logEntry.actionTitle] : null;

      if (actionButton) {
        // Temporarily change popupOnStart to prevent dialog
        const originalPopupOnStart = actionButton.popupOnStart;

        if (originalPopupOnStart === 'execution-dialog' ||
            originalPopupOnStart === 'execution-dialog-stdout-only' ||
            originalPopupOnStart === 'execution-dialog-output-html') {

          console.log('Temporarily disabling popup for:', logEntry.actionTitle);
          actionButton.popupOnStart = 'execution-button';

          // Restore it after the event has been processed
          setTimeout(() => {
            actionButton.popupOnStart = originalPopupOnStart;
            console.log('Restored popup setting for:', logEntry.actionTitle);
          }, 100);
        }
      }
    } else {
      console.log('EventExecutionFinished: My execution, allowing dialog:', trackingId);
    }
  }, true); // Use capture phase to run before other handlers

  console.log('✓ Successfully registered EventExecutionFinished interceptor');

  // Also expose the myExecutions set for debugging
  window.myExecutions = myExecutions;
})();
