# LE Examine

A small Legends of the Jedi merchant shortcut, maintained by Quiggly-Wiggly.

## Install and use

Download **LE Examine.mpackage** from [Releases](https://github.com/Quiggly-Wiggly/le-examine/releases/latest)
and install it through Mudlet's Package Manager. Remove an existing `le-examine`
package or standalone `le` alias first. Requires Mudlet 4.20+.

```text
le 3
le help
```

`le 3` sends `list #3 examine`. Use the number from the merchant list you are
viewing. Bare `le` opens the same compact colored help. Invalid input sends
nothing. There are no settings, background commands, merchant catalogs, prices,
or character data; installation sends no game commands.

## Development

```sh
python3 scripts/build.py
python3 -m unittest discover -s tests -v
```

Builds use Python's standard library. Tests use LuaJIT/Lua 5.1 and simulated
Mudlet APIs. Native visual and live merchant checks remain manual.
