# Project One-Click Action — Integration Checklist

This document describes every file and section that must be created or updated when adding a new
Project One-Click Action, and is intended as a step-by-step checklist for moving a new Action from
the working/testing version of OliveTin-for-Channels into this main repo.

All paths below are relative to the **`scripts/`** directory unless noted otherwise.

---

## 1. Source Files (created in working version, copied here)

These three files are written for the new Action and must be present before anything else is updated.

| File | Purpose |
|------|---------|
| `<action-id>.sh` | Main shell script — receives positional args from OliveTin, builds the env file, calls `portainerstack.sh` |
| `<action-id>.yaml` | Docker Compose service definition used by Portainer |
| `<action-id>.env` | Default env-var values; copied to `/tmp` at runtime and overwritten by the `.sh` |

**Checklist:**
- [ ] `<action-id>.sh` exists and positional args match the `shell:` line in `config.yaml`
- [ ] `<action-id>.yaml` service name and `container_name` match `<action-id>` exactly (case-sensitive)
- [ ] `<action-id>.env` lists every variable injected by the `.sh`, with sensible defaults
- [ ] Default port in the `.env` is consistent with the port used throughout all files below

---

## 2. `config.yaml` — Action Block

The Action's own block defines the OliveTin button and its argument form. Arguments vary widely
per action — there are no universally required arguments. Use the working version as the source
of truth for which arguments a given action needs.

**Location:** sorted alphabetically by `title:` within the main action list.

**Structural requirements** (the fields that are always present regardless of arguments):
```yaml
- title: Create a <Name> Stack in Portainer        # used verbatim in Dashboard block
  icon: '<img src = "..." width = "48px"/>'         # comment: #<action-id> icon
  shell: /config/<action-id>.sh "{{ arg1 }}" ...    # arg order must match .sh positional args
  id: <action-id>                                   # comment: #project-one-click
  popupOnStart: execution-dialog-stdout-only
  arguments:
    # ... action-specific arguments from the working version
  timeout: 40
```

**Notes on specific conventions:**
- If the action takes a `dvr` argument, it is conventionally first, with comments:
  `description: Channels DVR server to use. #<action-id> dvr description`
  `default: none #<action-id> default`
- The `dvr` arg `default:` comment (e.g. `#fastchannels default`) is the hook used by the
  OliveTin-for-Channels startup process to inject the real DVR address at install time.
- Integer arguments (like `HOST_PORT`) use `type: int`; all others use `type: very_dangerous_raw_string`.

**Checklist:**
- [ ] Block is present and sorted alphabetically by `title:`
- [ ] `id:` equals `<action-id>` with `#project-one-click` comment
- [ ] `icon:` line ends with `#<action-id> icon` comment (used by `listrunningprojects.sh`)
- [ ] `shell:` arg count and order match positional `$1`, `$2`, … in the `.sh`
- [ ] If a `dvr` arg is present: `description:` has `#<action-id> dvr description` comment and `default:` has `#<action-id> default` comment
- [ ] `timeout:` is set (typically 40)

---

## 3. `config.yaml` — Project One-Click Actions Debug Log Viewer

**Location:** search for `id: debuglogs`. Add an entry to its `choices:` list.

**Format:**
```yaml
          - title: Create a <Name> Stack in Portainer
            value: <action-id>
```

**Checklist:**
- [ ] Entry added, sorted alphabetically within the choices list
- [ ] `value:` matches the `.sh` script name (without `.sh`) and the `id:` field in the Action block

---

## 4. `config.yaml` — Docker-Compose Examples for CDVR & Related Extensions

**Location:** search for `id: dockercompose`. Add an entry to its `choices:` list.

**Format:**
```yaml
          - title: <Name>
            value: <action-id>
```

**Checklist:**
- [ ] Entry added, sorted alphabetically within the choices list
- [ ] `value:` matches the `<action-id>.yaml` filename (without `.yaml`)
- [ ] The `<action-id>.yaml` file is present in `scripts/` so `dockercompose.sh` can serve it

---

## 5. `config.yaml` — Delete a Project One-Click Channels DVR Extension

**Location:** search for `id: one-click-delete`. Add an entry to its `choices:` list.

**Format:**
```yaml
          - title: <Name>
            value: <action-id>+<image-name>:<tag>[+<CustomChannelsSourceName>...]
```

The `value` is a `+`-delimited string consumed by `one-click_delete.sh`:
- Field 1: Portainer stack name (`<action-id>`)
- Field 2: Docker image name and tag used in `<action-id>.yaml`
- Fields 3+: Any Channels DVR Custom Channels source names to remove (omit if none)

**Examples:**
```yaml
# No custom channels source:
value: fastchannels+fastchannels:latest

# With one custom channels source:
value: prismcast+prismcast:latest+PrismCast

# With multiple custom channels sources:
value: eplustv+eplustv:latest+EPlusTV+EPlusTV-Linear
```

**Checklist:**
- [ ] Entry added, sorted alphabetically within the choices list
- [ ] Image name in field 2 matches the `image:` line in `<action-id>.yaml`
- [ ] Custom channels source names (fields 3+) exactly match source names in Channels DVR (if applicable)

---

## 6. `config.yaml` — Project One-Click Dashboard Block

**Location:** search for `- title: Project One-Click` (the dashboard `contents:` section).

Add the Action's title to the `contents:` list:
```yaml
        - title: Create a <Name> Stack in Portainer
```

**Checklist:**
- [ ] Entry added, sorted alphabetically within the contents list
- [ ] Title matches exactly the `title:` field of the Action block in section 2 above

---

## 7. `tm_olivetin-dropdown.user.js` — ACTIONS Array

Drives the OliveTin dropdown in the Channels DVR WebUI. Arguments here must mirror the
Action's arguments in `config.yaml` — use the working version as the source of truth.

**Location:** `ACTIONS` array, sorted alphabetically by `label:`.

**Format:**
```javascript
{
  id: "<action-id>",
  label: "<Display Name>",
  title: "Create a <Name> Stack in Portainer",
  arguments: [
    // getDvrArgument(),  ← include if action takes a dvr arg
    // ... remaining arguments matching config.yaml, in the same order as the .sh positional args
  ],
},
```

**Argument object structure:**
```javascript
// Simple text/string argument:
{ name: "ARG_NAME", label: "Display Label", default: "default-value", description: "Help text" }

// Dropdown argument:
{
  name: "ARG_NAME",
  label: "Display Label",
  description: "Help text",
  default: "option1",
  options: [
    { display: "Label 1", value: "option1" },
    { display: "Label 2", value: "option2" },
  ]
}
```

**Checklist:**
- [ ] Entry added to ACTIONS array, sorted alphabetically by `label:`
- [ ] `id:` matches the OliveTin Action `id:` in `config.yaml`
- [ ] `getDvrArgument()` included as first arg if the action uses a `dvr` argument
- [ ] All arguments present, in the same order as in `config.yaml` / the `.sh`
- [ ] `default:` values match those in `config.yaml` and `<action-id>.env`
- [ ] Script `@version` date updated at the top of the file

---

## 8. `tm_extensions-dropdown.user.js` — extensions Array

Drives the Extensions dropdown showing live WebUI status for running containers.

**Location:** `extensions` array, sorted alphabetically by `id:`.

**Format:**
```javascript
{ id: "<action-id>", label: "<Display Name>", defaultPort: "<container-port>" },
```

- `id:` must match the Docker `container_name:` in `<action-id>.yaml`
- `defaultPort:` is the container's *internal* port (right-hand side of the `->` mapping in `docker ps`)

**Checklist:**
- [ ] Entry added, sorted alphabetically
- [ ] `defaultPort:` matches the container-side port in `<action-id>.yaml`
- [ ] Script `@version` date updated at the top of the file

---

## 9. `listactivewebuis.sh` — imagesPlusPorts Array

Used by the Extensions dropdown to detect running containers and report their active host ports.

**Location:** `imagesPlusPorts` array, sorted alphabetically.

**Format:**
```bash
"<image-fragment>:<container-port>"
```

- `<image-fragment>`: matched against `docker ps --format "{{.Image}}\t{{.Ports}}"` with `grep -F`; use the container/image base name
- `<container-port>`: the port *inside* the container (right side of `->` in `docker ps`)

**Checklist:**
- [ ] Entry added, sorted alphabetically
- [ ] Image fragment uniquely identifies the container
- [ ] Container port matches the `ports:` mapping in `<action-id>.yaml`

---

## 10. `listrunningcontainers.sh` — imagesPlusPorts Array

Same format and rules as `listactivewebuis.sh` above.

**Checklist:**
- [ ] Entry added, sorted alphabetically, identical to the entry in `listactivewebuis.sh`

---

## 11. `listrunningprojects.sh` — imagesPlusStacks Array

Controls the green/purple icon toggle on Project One-Click Action buttons. When the container is
running the icon switches from purple (default) to green.

**Location:** `imagesPlusStacks` array, sorted alphabetically.

**Format:**
```bash
"<image-fragment>:<stack-name>"
```

- `<image-fragment>`: same fragment used in the `list*.sh` scripts above
- `<stack-name>`: must match the `#<stack-name> icon` comment on the `icon:` line in `config.yaml`

**Checklist:**
- [ ] Entry added, sorted alphabetically
- [ ] `<stack-name>` matches the comment on the `icon:` line in the `config.yaml` Action block

---

## Quick Reference — FastChannels as a Worked Example

| Location | What was added |
|----------|---------------|
| `fastchannels.sh` | Shell script: args dvr/$1 TAG/$2 DOMAIN/$3 HOST_PORT/$4 TZ/$5 |
| `fastchannels.yaml` | Compose file: image `ghcr.io/kineticman/fastchannels`, container port 5523 |
| `fastchannels.env` | Defaults: TAG=latest, DOMAIN=localdomain, HOST_PORT=5523, TZ=America/New_York |
| `config.yaml` action block | `id: fastchannels`, port 5523, 5 arguments (dvr, TAG, DOMAIN, HOST_PORT, TZ) |
| `config.yaml` Debug Log Viewer | `value: fastchannels` |
| `config.yaml` Docker-Compose Examples | `value: fastchannels` |
| `config.yaml` Delete Extension | `value: fastchannels+fastchannels:latest` (no custom channels source) |
| `config.yaml` Dashboard block | `- title: Create a FastChannels Stack in Portainer` |
| `tm_olivetin-dropdown.user.js` | ACTIONS entry with getDvrArgument(), TAG, DOMAIN, HOST_PORT, TZ |
| `tm_extensions-dropdown.user.js` | `{ id: "fastchannels", label: "FastChannels", defaultPort: "5523" }` |
| `listactivewebuis.sh` | `"fastchannels:5523"` |
| `listrunningcontainers.sh` | `"fastchannels:5523"` |
| `listrunningprojects.sh` | `"fastchannels:fastchannels"` |

---

## General Notes

- **Actions with no DVR argument** (e.g. FileBot, Channels-App-Remote-Plus): omit `getDvrArgument()`
  from the Tampermonkey entry and omit the `dvr` argument from the `config.yaml` block entirely.
- **Actions that add Custom Channels sources**: the Delete dropdown `value` gains `+<SourceName>` fields,
  and the Tampermonkey ACTIONS entry typically includes a `CDVR_START_CHAN` argument.
- **Icon toggle**: the `#<action-id> icon` comment on the `icon:` line is the exact hook `sed` uses in
  `listrunningprojects.sh` — it must be present and correctly spelled.
- **Tampermonkey version dates**: both `tm_olivetin-dropdown.user.js` and `tm_extensions-dropdown.user.js`
  carry a `@version` date at the top; update it whenever either file is modified.
