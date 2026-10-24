# LockPort

Easy warlock summoning for World of Warcraft 1.12 / Turtle WoW 1.18.
Originally written by Gurky.

Current version: **3.7.4**. Optional companion client mod: **LockPort.dll 1.2.1**.

## Installation

Download this repository and copy its `LockPort` folder into `Interface/AddOns`.
For manual summoning, the addon alone is sufficient. To use Auto Summon, follow
[the client mod installation instructions](native/README.md).

## Changes in 3.7.4

- Optional Auto Summon for parties and raids, using LockPort.dll.
- Completed summons no longer announce a failure solely because the channel ended with an interruption event.
- Auto Summon waits for two nearby helpers and a ready candidate for two seconds.
- Auto Summon turns off when leaving the group. Turning it off also disables availability announcements.
- Both Auto Summon and availability announcements start off after login or `/reload`, including manually enabled announcements.
- All outgoing chat uses `[LockPort]`, including custom messages and summon whispers.
- Wider options window, button-style Auto Summon toggle, and ClassicAPI/LockPort detection.

Summoning works in-game with DLL 1.2.1 on their 1.18.1 client.

## Auto Summon

Install the compatible client mod, join a party or raid on a warlock, and turn on
**Auto Summon** below Add Target and Options. It also enables availability
announcements and posts once immediately. Requests are processed automatically
when the target is eligible, two helpers are nearby, and you have Soul Shards.
Helpers still need to click the portal, and the target must accept the summon.

ClassicAPI, when present, supplies movement and live cast/channel information.
The toggle appears only when LockPort.dll 1.2.1 is detected. Use `/lockport debug`
to inspect recent automatic attempts.

## How it works

- Be a warlock in a party or raid.
- When a group member starts a message with **123** (say, yell, whisper, party, raid), they're added to the summon list on every LockPort user in the group.
- Click a name to summon. The /say announcement and whisper only go out once the ritual has **actually started**.
- If the summon can't happen, LockPort **tells the party/raid why** and whispers the player, e.g.
  `[LockPort] Can't summon Bob: Bob is in combat.`
  The player stays on the list so you can try again.

### Failure reasons that are announced

| Checked before casting | Reported after casting |
|---|---|
| Target is offline | Any error the server/client gives for the cast (e.g. *Target is in combat*, *You must be standing to do that*, *Invalid target*) |
| Target is dead | Confirmed cast failures; interruption alone is treated as an uncertain result |
| Target is in combat | The ritual didn't start |
| Target is inside an instance you're not in (raids only) | |
| Target has Evil Twin (removed from list) | |
| You are in combat | |
| You are out of Soul Shards | |

Repeated identical failures are throttled (10 s) so the raid isn't spammed.

The instance check uses the zone from the raid roster, so it only works in raids (1.12 doesn't share zones in 5-man parties). Instance names are matched in English; vanilla dungeons, raids, battlegrounds and the Turtle WoW instances are included.

### Status whispers

When someone types 123 and there's nothing new to do, they get a whisper explaining why:

- **Already here:** `You're already here (12 yd from me) - no summon needed.` (removed from the list)
- **Typing 123 again while waiting:** their place in line plus what's holding it up:
  - `Summoning you now - waiting for helpers to click the portal (1/2 near me).`
  - `You're #2 in line - I'm summoning Bob right now.`
  - `You're #1 in line - waiting on helpers: I need 2 people near me to click the portal (0 here).`
  - `You're #3 in line, but you're in combat - drop combat first.`
  - `You're #1 in line, but you're inside Molten Core - zone out first.`
  - also: dead, I'm in combat, I'm out of Soul Shards, `N ahead of you`, `you're next!`
- **Typing 123 again right after being summoned:** `I cast your summon 30s ago - accept the prompt if you still see it.` and they're put back on the list in case it expired.

Only one warlock replies even if several run LockPort. The one summoning that player answers first, the others back off.

## The window

Classic dialog style built from stock Blizzard art: class icons, class-coloured names, and a live status column (`Here`, `In combat`, `Dead`, `Offline`, distance in yards, or zone). The footer shows your Soul Shards and how many helpers are close enough to click the portal.

- **Left-click** a name: summon · **Ctrl+click**: target · **Right-click**: remove
- **Summon** button: next in line (warlocks first, then oldest request; skips offline/dead/in-combat/inside an instance)
- **Add Target**: put your current target on the list
- Drag to move (position is saved), or lock it in Options.
- **Window style** (Options or `/lockport style`): *Classic* (Blizzard dialog) or *pfUI* (flat and dark like the original LockPort, with its pink "LockPort" title; uses pfUI's own skin and font when pfUI is installed). Needs a /reload.

## Summon Next

The **Summon Next** button (or its hotkey) always picks the right person. It skips anyone who is offline, dead, in combat, inside an instance, being summoned by another LockPort warlock, or who failed 3 times in a row (for a minute).

The line under the title tells you whether a summon would work right now, e.g. `Ready: Bob` (green) or `Waiting for helpers (1/2)`, `You're in combat`, `No Soul Shards`. The button text turns green when ready, and LockPort plays the ready-check chime the moment a summon becomes possible (and flashes the taskbar if you have UnitXP SP3). So on raid night you can sit at the stone and press your key each time it chimes.

**Hotkey:** Options → *Summon Next key*. Click it, press a key or combo, right-click to clear. It's a normal WoW key binding, also under *Key Bindings → LockPort*.

## Asking for helpers

If someone is waiting (or your portal is up) and fewer than 2 group members are near you, LockPort asks the raid for help after about 8 seconds:

- `[LockPort] Need 1 more person at Blackrock Mountain to help summon - 3 players waiting.`
- `[LockPort] Need 2 more people at Blackrock Mountain to click the summoning portal for Bob!`

At most every 2 minutes, never while you're in combat, and only one LockPort warlock posts. On by default; toggle in Options or with `/lockport helpers`.

## "Summons are available" announcements

Turn on *Post "summons are available" to the raid every N min* in Options (or `/lockport available`) and LockPort posts `[LockPort] Summons are available - type 123 to get summoned. (2 in line)` on that timer, using your first request word. It's skipped while you're in combat, and with several LockPort warlocks in the raid only one posts each round. Off after login or `/reload`. `/lockport open` remains an alias for `/lockport available`.

## Commands

```
/lockport                 show / hide the window
/lockport next            summon the next person in line
/lockport available            toggle the "summons are available" raid posts
/lockport add [name]      add a name (or your target)
/lockport remove <name>   remove a name      /lockport clear   clear the list
/lockport show            print the list
/lockport options         options window
/lockport message <text>  custom /say message, tokens {name} {zone} {shards}  ("message clear" resets)
/lockport zone | whisper | shards | sound | announce | status | helpers | flash | autoremove | lock    toggles
/lockport mods            which client mods are in use
/lockport style           switch window style (Classic / pfUI)
/lockport reset           reset window position
```

## Optional client mods

LockPort works on a plain client. If these mods are present it uses them automatically:

| Mod | What LockPort gets from it |
|---|---|
| **SuperWoW** | `UNIT_CASTEVENT` matched by your GUID and the Ritual's spell id, so start/fail detection can't be confused by other spells; Evil Twin detected by spell id; yard distances via `UnitPosition` |
| **UnitXP SP3** | Exact distance for the status column and the "already here" check (instead of the ~28 yd interact check); taskbar flash on new requests while alt-tabbed |
| **LockPort 1.2.1** | Optional native casting support for Auto Summon; install through VanillaFixes |
| **ClassicAPI** | Movement and live casting/channel information when available |
| **Nampower** | `SPELL_FAILED_SELF` as an extra, server-confirmed failure signal |

Manual summoning targets the player through the Lua API. Auto Summon passes the group member's GUID directly to the client spellbook function.

## Compatibility

v3 still uses the `RSAdd` / `RSRemove` addon messages, so it syncs lists with older LockPort versions in the same raid. Your v2 settings are kept.
