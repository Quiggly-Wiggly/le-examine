local sent,output,links,colors={},{},{},{}
local legacyActive,separator,draft,sendFailure=0,';;',nil,nil
function send(t)
  if sendFailure=='error' then error('disconnected') end
  if sendFailure=='false' then return false end
  if sendFailure=='nil-error' then return nil,'disconnected' end
  sent[#sent+1]=t
  if sendFailure=='nil-success' then return end
  return true
end
function echo(t) output[#output+1]=t end
function echoLink(label,fn,hint,keepFormat)
  assert(type(fn)=='function' and keepFormat==true and hint:find('Enter',1,true))
  links[#links+1]=fn;echo(label)
end
function printCmdLine(t) draft=t end
function resetFormat() end
function setFgColor(r,g,b) colors[r..','..g..','..b]=true end
function setBold() end
function setUnderline() end
function setItalics() end
function getCommandSeparator() return separator end
function isActive(name,kind) assert(name=='Vendor Giving' and kind=='alias');return legacyActive end
local function eq(a,b) assert(a==b,'Expected '..tostring(b)..', got '..tostring(a)) end
local function last() return sent[#sent] end
local function reset() sent={};output={};links={};draft=nil;sendFailure=nil;separator=';;';legacyActive=0 end
local checks=0
local function test(name,fn)
 reset();fn();checks=checks+1;print('PASS '..name)
end
-- Execute the actual packaged bootstrap when supplied by the Python harness.
dofile(arg[1] or 'src/core.lua')
eq(#sent,0);eq(leExamine,lotjVendorManager)
local V=lotjVendorManager

test('install and compact colored help send no game commands',function()
 V.command('');V.command('help');V.give('help');V.menu('')
 eq(#sent,0)
 local t=table.concat(output)
 assert(t:find('VENDOR MANAGER',1,true) and t:find('givevendor <item> <price> [amount]',1,true))
 assert(colors['255,190,70'] and colors['70,220,235'] and colors['155,170,185'])
 output={};V.help();t=table.concat(output)
 local _,lines=t:gsub('\n','');assert(lines<=10)
 for line in t:gmatch('[^\n]+') do assert(#line<=72,line) end
end)
test('all help links prefill input without sending commands',function()
 V.help();for _,fn in ipairs(links) do fn();assert(type(draft)=='string') end
 eq(#sent,0)
end)
test('le preserves the original numbered examination shortcut',function()
 V.command('3');eq(last(),'list #3 examine')
 for _,v in ipairs({'0','-1','1.5','3;;quit','all','999999999999999'}) do V.command(v) end
 eq(#sent,1)
end)
test('giving one item sets the price after the give',function()
 V.give('sample 100');eq(#sent,2)
 eq(sent[1],'give sample vendor');eq(sent[2],'priceclanvendor sample 100')
end)
test('giving an explicit amount preserves original command syntax',function()
 V.give('  sample 100 2  ');eq(#sent,2)
 eq(sent[1],'give 2 sample vendor');eq(sent[2],'priceclanvendor sample 100')
end)
test('zero prices and numbered item keywords remain valid',function()
 V.give('2.sample 0 1');eq(sent[1],'give 1 2.sample vendor');eq(sent[2],'priceclanvendor 2.sample 0')
end)
test('invalid vendor arguments send nothing',function()
 for _,v in ipairs({'sample','sample -1','sample 1.5','sample 100 0','sample 100 -2',
  'sample 100 1.5','sample 100 2 extra','sample 1000000000','sample 100 1000000000',
  'sample;;quit 100','sample 100\nquit','sample\t100','"sample name" 100',
  "'sample' 100",string.rep('x',121)..' 100'}) do
  V.give(v);eq(#sent,0)
 end
end)
test('both generated commands are checked against the active separator',function()
 separator='|';V.give('sample|quit 100');eq(#sent,0)
 separator='1';V.give('sample 100');eq(#sent,0)
 separator='#';V.command('3');eq(#sent,0)
 separator='';V.give('sample 100');eq(#sent,2)
end)
test('failed first send prevents submitting a price command',function()
 for _,failure in ipairs({'false','error','nil-error'}) do
  sendFailure=failure;V.give('sample 100');eq(#sent,0)
 end
 sendFailure='nil-success';V.give('sample 100');eq(#sent,2)
end)
test('known standalone alias is detected without modifying it',function()
 legacyActive=1;V.give('sample 100 2');eq(#sent,0)
 assert(table.concat(output):find('disableAlias("Vendor Giving")',1,true))
 V.help();for _,fn in ipairs(links) do fn() end;eq(draft,'lua disableAlias("Vendor Giving")');eq(#sent,0)
 legacyActive=0;V.give('sample 100');eq(#sent,2)
end)
test('plain help fallback and unknown menu commands remain local',function()
 echoLink=nil;printCmdLine=nil
 V.help();V.menu('buy everything');eq(#sent,0)
 assert(table.concat(output):find('le <number>',1,true))
end)
print(checks..' Vendor Manager behavior checks passed.')
