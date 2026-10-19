# LockPort

Easy warlock summoning for World of Warcraft 1.12 / Turtle WoW 1.18.
Originally written by Gurky.

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
| Target is dead | The ritual was interrupted (player goes back on the list) |
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
- Key bindings: *Key Bindings → LockPort*

## Commands

```
/lockport                 show / hide the window
/lockport next            summon the next person in line
/lockport add [name]      add a name (or your target)
/lockport remove <name>   remove a name      /lockport clear   clear the list
/lockport show            print the list
/lockport options         options window
/lockport message <text>  custom /say message, tokens {name} {zone} {shards}  ("message clear" resets)
/lockport zone | whisper | shards | sound | announce | status | flash | autoremove | lock    toggles
/lockport mods            which client mods are in use
/lockport reset           reset window position
```

## Optional client mods

LockPort works on a plain client. If these mods are present it uses them automatically:

| Mod | What LockPort gets from it |
|---|---|
| **SuperWoW** | `UNIT_CASTEVENT` matched by your GUID and the Ritual's spell id, so start/fail detection can't be confused by other spells; Evil Twin detected by spell id; yard distances via `UnitPosition` |
| **UnitXP SP3** | Exact distance for the status column and the "already here" check (instead of the ~28 yd interact check); taskbar flash on new requests while alt-tabbed |
| **Nampower** | `SPELL_FAILED_SELF` as an extra, server-confirmed failure signal |
| **ClassicAPI** | Detected, but nothing it adds is needed by LockPort |

Note: the ritual summons your **current target**, so LockPort targets the player for you. Keep them targeted until the portal is clicked.

## Compatibility

v3 still uses the `RSAdd` / `RSRemove` addon messages, so it syncs lists with older LockPort versions in the same raid. Your v2 settings are kept.
