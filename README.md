# LotJ Vendor Manager

Compact vendor helpers for Legends of the Jedi: examine merchant list entries,
stock a vendor, and set clan-vendor prices. Maintained by Quiggly-Wiggly.
This expands the original LE Examine package; its source repository and installed
package ID remain `le-examine` for upgrade compatibility.

## Install and use

Download **LotJ Vendor Manager.mpackage** from [Releases](https://github.com/Quiggly-Wiggly/le-examine/releases/latest)
and install it through Mudlet's Package Manager. Requires Mudlet 4.20+.

When upgrading, uninstall the old `le-examine` package first. Disable or remove
standalone `le` and `givevendor` aliases. For the old alias named **Vendor Giving**,
run this once in Mudlet:

```lua
lua disableAlias("Vendor Giving")
```

The new helper detects that known alias and will not send a second copy of its
commands while it is active. The old alias may still execute until disabled.
Duplicates with other names must be removed manually.

| Command | Action |
| --- | --- |
| `vendormgr` / `vendormgr help` | Compact colored menu |
| `le <number>` | Examine a numbered merchant list entry |
| `givevendor <item> <price> [amount]` | Give stock to `vendor`, then set its clan-vendor price |
| `le help` / `givevendor help` | Same command guide |

Menu links fill the input line for review; Enter runs the command. The native
`vendor`, `list`, `give`, and `priceclanvendor` commands are not intercepted.

## Examples

```text
le 3
givevendor sample 100
givevendor sample 100 2
```

`le 3` sends `list #3 examine`. The two `givevendor` examples use a fictional item
keyword and price; substitute your own. Use a single item keyword, not a quoted
multiword description. Prices are nonnegative whole numbers; an explicit amount
must be a positive whole number. Numeric arguments accept up to nine digits.

`givevendor sample 100 2` sends these separate game commands, in order:

```text
give 2 sample vendor
priceclanvendor sample 100
```

Without an amount, the first command is `give sample vendor`. This preserves the
original alias's two-command behavior: it does **not** wait for the game to confirm
the transfer before requesting the price change. Check the game response. If
Mudlet reports a failed first send, the price command is not submitted. There are
no retries, timers, purchases, saved prices, or background actions.

The package ships no merchant catalog, inventory, character data, or game records.
Installation and help send no game commands. It does not save settings or change
other aliases automatically.

## Development

```sh
python3 scripts/build.py
python3 -m unittest discover -s tests -v
```

Builds use Python's standard library. Tests use LuaJIT/Lua 5.1 and simulated
Mudlet APIs, covering command order, validation, duplicate-alias protection,
click behavior, and reproducible release contents. Native visual and live vendor
checks remain manual.
