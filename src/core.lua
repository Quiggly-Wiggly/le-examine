-- A shortcut only: no saved merchant, stock, prices, or character information.
leExamine={version="1.1.0"}
local L=leExamine
local function text(color,value)
  resetFormat(); setBold(false); setUnderline(false); setItalics(false)
  setFgColor(unpack(color)); echo(value); resetFormat()
end
function L.help()
  text({255,190,70},"\n  LE EXAMINE  v"..L.version.."\n")
  text({70,220,235},"  le <number>")
  text({155,170,185},"  Examine a merchant list entry\n")
  text({70,220,235},"  le 3")
  text({155,170,185},"         Sends: list #3 examine\n")
  text({70,220,235},"  le help")
  text({155,170,185},"      Show this guide; no setup needed\n")
end
function L.command(value)
  value=tostring(value or ""):match("^%s*(.-)%s*$")
  if value=="" or value:lower()=="help" then L.help(); return end
  if not value:match("^%d+$") or #value>9 or tonumber(value)<1 then
    text({255,120,120},"  Use le <positive number>, for example le 3.\n"); return
  end
  send("list #"..value.." examine")
end
