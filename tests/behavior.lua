local sent,output={},{}
function send(t) sent[#sent+1]=t end
function echo(t) output[#output+1]=t end
function resetFormat() end
function setFgColor() end
function setBold() end
function setUnderline() end
function setItalics() end
dofile('src/core.lua');assert(#sent==0)
leExamine.command('');leExamine.command('help');assert(#sent==0)
assert(table.concat(output):find('le <number>',1,true))
leExamine.command('3');assert(sent[1]=='list #3 examine')
for _,v in ipairs({'0','-1','1.5','3;;quit','all','999999999999999'}) do leExamine.command(v) end
assert(#sent==1)
print('LE Examine help, numeric command, and invalid input checks passed.')
