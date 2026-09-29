-- Vendor tools only: no saved merchant, stock, prices, or character information.
lotjVendorManager={version="1.2.0"}
local V=lotjVendorManager
leExamine=V -- Keep the original Lua entry point and installed package identity.
local colors={heading={255,190,70},command={70,220,235},text={235,240,245},muted={155,170,185},error={255,120,120}}
local function text(tone,value)
  resetFormat(); setBold(false); setUnderline(false); setItalics(false)
  setFgColor(unpack(colors[tone])); echo(value); resetFormat()
end
local function trim(value) return tostring(value or ''):match('^%s*(.-)%s*$') end
local function row(label,description,draft)
  text('command','  '); setFgColor(unpack(colors.command))
  if type(echoLink)=='function' and type(printCmdLine)=='function' then
    echoLink(label,function() printCmdLine(draft or label) end,'Fill the input line; review and press Enter.',true)
  else echo(label) end
  text('muted','  '..description..'\n')
end
local function error(message) text('error','[Vendor] '..message..'\n') end
local function integer(value,minimum)
  return value and #value<=9 and value:match('^%d+$') and tonumber(value)>=minimum
end
local function safe(command)
  local separator=type(getCommandSeparator)=='function' and (getCommandSeparator() or '') or ''
  return not command:find('[%c;]') and (separator=='' or not command:find(separator,1,true))
end
local function submit(command)
  local ok,result,reason=pcall(send,command)
  if not ok or result==false or (result==nil and reason~=nil) then error('Command could not be sent. Check your connection.'); return false end
  return true -- Older Mudlet send implementations may return nil on success.
end
function V.legacyGivingActive()
  -- Mudlet returns a COUNT, including numeric zero, not a boolean.
  return type(isActive)=='function' and isActive('Vendor Giving','alias')>0
end
function V.help()
  text('heading','\n  VENDOR MANAGER  v'..V.version..'\n')
  row('le <number>','Examine a list entry','le ')
  row('givevendor <item> <price> [amount]','Stock + price','givevendor ')
  row('vendormgr help','Show this guide')
  text('muted','  Example: givevendor sample 100 2\n')
  text('muted','  Click to edit; Enter runs it. Check the game response.\n')
  if V.legacyGivingActive() then
    text('error','  Old Vendor Giving alias is active; disable it first.\n')
    row('lua disableAlias("Vendor Giving")','Disable old alias')
  end
end
function V.command(value)
  value=trim(value)
  if value=='' or value:lower()=='help' then V.help(); return end
  if not integer(value,1) or not safe('list #'..value..' examine') then
    error('Use le <positive number>, for example le 3.'); return
  end
  submit('list #'..value..' examine')
end
function V.give(value)
  local raw=tostring(value or '')
  value=trim(raw)
  if value=='' or value:lower()=='help' then V.help(); return end
  if V.legacyGivingActive() then
    error('Disable the old alias: lua disableAlias("Vendor Giving")')
    return -- That standalone alias may still run; do not send a second copy.
  end
  local item,price,amount=value:match('^(%S+)%s+(%d+)%s+(%d+)$')
  if not item then item,price=value:match('^(%S+)%s+(%d+)$') end
  if raw:find('[%c]') or not item or #item>120 or item:find('["\']')
      or not integer(price,0) or (amount and not integer(amount,1)) then
    error('Use givevendor <item keyword> <price> [positive amount].'); return
  end
  local giving='give '..(amount and (amount..' ') or '')..item..' vendor'
  local pricing='priceclanvendor '..item..' '..price
  if not safe(giving) or not safe(pricing) then
    error('Item or price conflicts with the command separator.'); return
  end
  -- Same two-command sequence as the original alias. A successful send only
  -- means the command was queued, not that the game accepted the transfer.
  if submit(giving) then submit(pricing) end
end
function V.menu(value)
  value=trim(value):lower()
  if value=='' or value=='help' then V.help()
  else error('Use vendormgr help.') end
end
