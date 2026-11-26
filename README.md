<div align="center">

# 🎯 piercer_hitchhunter

**Hitch detector and culprit finder for FiveM servers, with an in-game NUI, an optional web dashboard and crash forensics.**

Catches every `network thread hitch warning` (and `server thread hitch warning`), snapshots the server at that exact moment and ranks the resources most likely to blame, using entity ownership, slow queries, recent starts/stops and the native profiler. Works with **any server framework**.

![FiveM](https://img.shields.io/badge/FiveM-resource-F40552?style=for-the-badge)
![Frameworks](https://img.shields.io/badge/vRP%20%C2%B7%20Creative%20%C2%B7%20ESX%20%C2%B7%20QBCore%20%C2%B7%20Qbox%20%C2%B7%20TNet%20%C2%B7%20standalone-2b2b2b?style=for-the-badge)
![Lua](https://img.shields.io/badge/Lua-5.4-2C2D72?style=for-the-badge&logo=lua&logoColor=white)
![UI](https://img.shields.io/badge/NUI-PT--BR%20%2F%20EN--US-black?style=for-the-badge)
[![Discord](https://img.shields.io/badge/Discord-join-5865F2?style=for-the-badge&logo=discord&logoColor=white)](https://discord.gg/framezerodevelopment)

[![Ler em Português](https://img.shields.io/badge/Ler%20em%20Portugu%C3%AAs-009B3A?style=for-the-badge&logo=googletranslate&logoColor=white)](README.pt-BR.md)

</div>

---

## 🎯 Purpose & Features

The `network thread hitch warning` means the server's network thread was blocked for hundreds of milliseconds. It is rarely "one resource spamming the warning": it is some resource doing something heavy or sending too much **at that instant**, and the console never tells you which one.

Typical causes this tool helps you narrow down:
- **Entity floods:** a script spawning peds, vehicles or objects in bulk (OneSync).
- **Slow database queries:** synchronous or heavy SQL blocking the thread.
- **Heavy start/stop:** resources being started or restarted during peak hours.
- **CPU-hungry handlers and ticks:** found with the native profiler.

**piercer_hitchhunter** records each hitch as an incident with context and a ranked list of suspects, so you know where to look first.

- 🧩 **Auto-Adaptation via framezero_bridge**: permissions and notifications work on any base (vRP traditional, vRPex, Creative v3/v5/Network, TNet, QBCore, Qbox, ESX, OxCore or Standalone ACE).
- 🔎 **Suspect Ranking**: entities per creator resource (`GetEntityScript`) and their growth, slow queries, recent starts/stops, plus real CPU time from the profiler when available.
- 🖥️ **Compact NUI**: open it in-game with `/hitchhunter`, bilingual (PT-BR and EN-US toggle) with the choice remembered per player.
- 🌐 **Optional Web Dashboard**: double-click `tools/start.bat` and watch your server from a browser, even when it is down. No installs, no API, no token.
- 💥 **Crash Forensics**: the state is saved every ~10s; if the next boot finds an unclean shutdown, a `crash?` incident is created with the last known suspects.
- ⚙️ **Remote Actions**: snapshot, profiler, ignore false positives, notes, resolve and an optional resource restart, identical in the NUI and the web dashboard.

---

## 🚀 Installation

1. Ensure the **`framezero_bridge`** resource is installed on your server:
   ```
   resources/[framezero-dev-scripts]/framezero_bridge
   ```
2. Place the `piercer_hitchhunter` folder in your `resources/` directory:
   ```
   resources/[framezero-dev-scripts]/piercer_hitchhunter
   ```
3. Add to your `server.cfg` (ensuring the bridge starts first):
   ```cfg
   ensure framezero_bridge
   ensure piercer_hitchhunter
   ```
4. Give permission to whoever will use it. Any one of these is enough (see `Config.Permissions`):
   - your framework's permission/group (e.g. vRP permission, QBCore/ESX group) listed in `bridge`;
   - ACE: `add_ace group.admin piercer_hitchhunter.use allow`;
   - fixed identifiers (`license:...`, `discord:...`).

Nothing else to configure. It starts recording hitches immediately.

---

## ⌨️ Commands

| Command | Description |
|---|---|
| `/hitchhunter` | Opens or closes the NUI in-game (`Esc` also closes it). Requires permission. |
| `hitch_profile` | Server console: records the native profiler and attaches the result to the latest incident. |
| `hitch_status` | Server console: shows how many incidents, samples and slow queries are in memory. |

---

## 🧰 Actions

Available in both the in-game NUI and the web dashboard:

| Action | What it does |
|---|---|
| **Snapshot** | Takes a sample right now: players, entities and the top creator resources. |
| **Record profiler** | Records the native profiler and attaches the CPU breakdown to the latest incident. |
| **Export** / **Download JSON** | In-game saves `data/report-*.json`; on the web it downloads straight to your browser. |
| **Clear** | Deletes all incidents (asks for a second click). |
| **Ignore** (per suspect) | Hides a resource from the suspect lists, handy for permanent false positives such as `oxmysql`. Undo from the "Ignored" chips. |
| **Note** / **Mark resolved** | Records the cause you found and dims the incident in the list. |
| **Restart** (per suspect) | Restarts that resource. **Disabled by default**, see below. |

> `Restart resource` only appears with `Config.Actions.restartResource = true` and **really restarts the resource**. Anything in `Config.Actions.protected` (bridge, oxmysql, monitor...) and the hitchhunter itself can never be restarted from here.

---

## 🌐 Web Dashboard

Double-click **`tools/start.bat`**. It uses the PowerShell that ships with Windows (nothing to install), opens `http://localhost:8787/` and refreshes every 5s.

**How actions reach the server, with no API exposed on FiveM:** the dashboard writes a request into `data/commands.json`; the resource reads the queue every ~2s, runs only whitelisted actions with validated arguments, and answers in `data/results.json`, which the dashboard displays. Requests older than 60s are discarded so a stale command never fires by surprise after a reboot.

- Runs on the same machine as your FiveM server (or on a shared folder with the same clock).
- Local connections only by default. Actions require the `X-Hitch` header and a `localhost` origin, which stops other web pages in your browser from triggering them.
- To expose it on your network, run `start.bat -Bind +` with PowerShell as Administrator. In that mode **actions** require a random key shown in the `start.bat` window (reading stays open, so only do this on a trusted network).
- Another port: `start.bat -Port 8788`.
- Hosted server without disk access? Download the `data/` folder and run `start.bat -DataFile "C:\path\incidents.json"`. Without the resource reading the queue, actions will have no effect.
- A `Server` card shows `online`, `stopped` or **`no signal for X`**, so you can tell a crash apart from a normal restart.

---

## 💥 Crash Forensics

The in-game NUI disappears along with a crashed server, but the data stays on disk:

- The resource saves `data/last_state.json` every ~10s. It only gets the `clean` flag on a normal shutdown (resource stop or txAdmin shutdown/restart).
- On the next boot, if the previous run was **not** clean, a **`crash?`** incident is created with suspects computed from that last saved state (entities per resource, slow queries, recently started resources).
- Normal txAdmin restarts and `restart piercer_hitchhunter` count as clean shutdowns and do **not** create the incident. Disable the feature with `Config.CrashDetection = false`.
- It is a heuristic. The state can be up to ~10s old, so the suspects are a clue to what was happening right before the crash, not a proven cause. A manual `quit` outside txAdmin may be read as a crash.

---

## ⚙️ Configuration

The `config.lua` file allows complete customization:

- `Language`: language of server messages (notifications and Discord): `pt-BR` or `en-US`. The NUI has its own PT-BR / EN-US toggle.
- `Permissions`: `bridge` (framework permissions/groups/jobs resolved by framezero_bridge), `ace` and fixed `identifiers`.
- `Actions`: `restartResource` (off by default), `protected` resources and the command `commandTtl` / `pollMs`.
- `MinHitchMs`, `MergeWindow`: ignore small hitches and merge consecutive ones into a single incident.
- `SampleInterval`, `SampleHistory`, `MaxEntitiesPerSample`, `ContextSeconds`: how the server is sampled.
- `Profiler`: automatic recording after a hitch (`frames`, `cooldown`, `outputFile`).
- `CrashDetection`: create the `crash?` incident after an unclean shutdown.
- `Discord`: optional webhook alert for severe hitches.

---

## 🔬 How it works

1. Listens to the server console (`RegisterConsoleListener`) and parses each hitch warning. Consecutive hitches inside the merge window become one incident.
2. Samples the server every 10s: players, peds/vehicles/objects and **entities per creator resource**. It also tracks slow-query lines printed by oxmysql and resource starts/stops.
3. When a hitch happens it builds the suspect ranking. If the profiler is enabled it records it automatically and merges the CPU time into the ranking (`profiler+heuristic`).
4. Everything is stored in `data/`, which feeds both the NUI and the web dashboard.

---

## ⚠️ Limitations

- Without the profiler, the ranking is **heuristic**: it points to suspects with evidence, it does not prove a cause.
- A Lua resource cannot see other resources' event handlers, so that kind of cause only shows up if the profiler catches the moment.
- The `profiler record` / `profiler saveJSON` commands and the JSON format depend on your server build. If the profiler ranking comes back empty, adjust `server/profiler.lua` and `Config.Profiler.outputFile`.
- The profiler costs CPU, so it only runs in short windows with a 120s `cooldown` by default.
- The web dashboard is built for Windows (PowerShell). On a Linux host, use the in-game NUI or download `data/incidents.json` and run `start.bat` on a Windows PC.

---

## 📋 Support

Engineered to make hitch hunting on FiveM servers fast and evidence-based. Questions or suggestions? Join our Discord: https://discord.gg/framezerodevelopment
