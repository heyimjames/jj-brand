# Jack & Jill for the terminal

The brand palette — four monochromes, the palette nine, the magic six — spent on a
terminal and on Claude Code, with every colour pair measured rather than assumed.

Two halves, because they are owned by two different things:

- **Claude Code's theme** sets 72 roles (the spinner, bash blocks, skills, permission
  prompts, diffs, eight parallel agents, the context bar). Ships in this plugin.
- **The terminal's own palette** sets the sixteen ANSI slots, the ground, the cursor
  and the selection. Claude Code cannot set those, so the kit carries them for
  Terminal.app, Ghostty, iTerm2, Kitty, Alacritty, WezTerm and VS Code.

Every accent role points at a **slot** rather than carrying a hex, because
Terminal.app renders its own palette exactly and approximates a 24-bit value into
its 256 cube. That indirection is also what makes one theme follow both grounds.

## Install

One command. It sets up the theme, the Terminal profiles, the status line, the
shell palette, git's colours, the Dock toggle and the flashing cursor, and then
selects the theme so there is nothing to pick afterwards.

```
curl -fsSL https://raw.githubusercontent.com/heyimjames/jj-brand/main/bootstrap.sh | sh
```

Then restart Claude Code. That is the whole install.

Add `--no-extras` (`| sh -s -- --no-extras`) to skip the Dock icon and the
cursor. Everything it touches is backed up, it never overwrites a status line or
a git colour you have set yourself, and running it twice changes nothing.

### Or as a plugin

The plugin route adds two things the script does not: the `/jj-brand:ground`
and `/jj-brand:palette` commands, and the Jack & Jill output style. It needs a
restart before its components appear.

```
/plugin marketplace add heyimjames/jj-brand
/plugin install jj-brand@jack-and-jill
```

## What you get

| | |
| --- | --- |
| **Two grounds** | Black `#010101` and Paper `#f9f9f6`, each with its own 16 slots |
| **72 roles** | every colour key Claude Code has, none left on a built-in default |
| **Measured** | 78 pairs per ground against WCAG AA: 4.5:1 text, 3:1 UI, 0 below floor |
| **One click** | a Dock icon flips both halves and every open window at once |
| **A cursor that flashes** | the magic six, a colour per blink |
| **A status line** | model, project, branch, context as mass, spend, the ground |
| **The rest of the shell** | `LS_COLORS`, `bat`, `fzf`, `less`, git, delta, all on the same slots |

## The rules it was built to

- **The brand value is kept whenever it clears its floor**; re-lighting is the
  fallback, and it preserves hue exactly. On Black, 14 of 16 slots are literal
  brand hexes, because the magic six were lit for a dark ground in the first
  place. On Paper nearly all of them move, and the *bright* tier is the darker
  one: on a light ground, stronger means more ink.
- **Body text is Clay, not white.** 18.56:1 on Black is far past the floor, and the
  warm off-white is the brand's own paper rather than a clinical maximum. Pure
  White is kept for bold, so emphasis has somewhere to climb to.
- **A block cursor answers to the text floor**, not the UI one: Terminal draws the
  glyph beneath it in the ground colour.
- **Nothing is hand-copied.** `kit/gen.ts` reads the swatches out of the studio's
  `lib/brand.ts`, re-measures every pair and refuses to write a palette that
  misses a floor; `kit/gen-configs.py` turns that one palette into every
  terminal's syntax.

## Regenerating

```
npx tsx kit/gen.ts          # themes + Terminal.app profiles, re-measured
python3 kit/build-profile.py
python3 kit/gen-configs.py  # every other terminal, plus the shell palette
```
