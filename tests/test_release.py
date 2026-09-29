"""Verify release contents, reproducibility, Lua syntax, and behavior."""
from pathlib import Path
import importlib.util, os, shutil, subprocess, tempfile, unittest, re, xml.etree.ElementTree as ET
ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('builder',ROOT/'scripts/build.py')
builder=importlib.util.module_from_spec(spec); spec.loader.exec_module(builder)
def lua():
    if os.environ.get('LUA'):
        p=os.environ['LUA']; return [p]+(['--luaonly'] if 'tex' in Path(p).name else [])
    for name in ('luajit','lua5.1','lua'):
        if shutil.which(name): return [shutil.which(name)]
    for p in sorted(Path('/usr/local/texlive').glob('*/bin/*/luajittex'),reverse=True): return [str(p),'--luaonly']
    raise RuntimeError('Install LuaJIT / Lua 5.1 or set LUA')
def run(script,*args,cwd=ROOT):
    result=subprocess.run(lua()+[str(script)]+list(map(str,args)),cwd=cwd,text=True,capture_output=True)
    if result.returncode: raise AssertionError(result.stdout+result.stderr)
    return result.stdout
class ReleaseTests(unittest.TestCase):
    def test_package(self):
        with tempfile.TemporaryDirectory() as t:
            a=builder.build(Path(t)/'a.mpackage'); b=builder.build(Path(t)/'b.mpackage')
            self.assertEqual(a.read_bytes(),b.read_bytes())
            self.assertEqual(a.read_bytes(),(ROOT/builder.ARTIFACT).read_bytes())
            files=builder.package_files()
            self.assertEqual(set(files),{builder.PACKAGE+'.xml','config.lua','README.md'})
            for name,data in files.items():
                for forbidden in (b'/Users/',b'/home/'):
                    self.assertNotIn(forbidden,data,name)
            xml=ET.fromstring(files[builder.PACKAGE+'.xml'])
            self.assertFalse(xml.findall('.//Variable'))
            paths=[]
            for i,s in enumerate(xml.iter('script')):
                if s.text:
                    p=Path(t)/f'script{i}.lua';p.write_text(s.text);paths.append(p)
            check=Path(t)/'compile.lua';check.write_text('for _,p in ipairs(arg) do assert(loadfile(p)) end\n')
            run(check,*paths)
    def test_behavior(self):
        with tempfile.TemporaryDirectory() as folder:
            doc=ET.fromstring(builder.package_files()[builder.PACKAGE+'.xml'])
            script=Path(folder)/'bootstrap.lua'
            script.write_text(doc.findtext('./ScriptPackage/Script/script'))
            print(run(ROOT/'tests/behavior.lua',script))

    def test_aliases_and_upgrade_identity(self):
        files=builder.package_files()
        self.assertIn(b'mpackage = [[le-examine]]',files['config.lua'])
        self.assertIn(b'LotJ Vendor Manager',files['config.lua'])
        doc=ET.fromstring(files[builder.PACKAGE+'.xml'])
        patterns=[re.compile(n.text) for n in doc.findall('./AliasPackage/Alias/regex')]
        self.assertEqual(len(patterns),3)
        for command in ('le','le 3','LE 3','le help','givevendor','givevendor sample 100',
                        'givevendor sample 100 2','GIVEVENDOR sample 100 2','vendormgr','vendormgr help'):
            self.assertEqual(sum(bool(p.fullmatch(command)) for p in patterns),1,command)
        for command in ('list','give sample vendor','priceclanvendor sample 100','vendor',
                        'vendor help','givevendorx sample 100','lex 3'):
            self.assertFalse(any(p.fullmatch(command) for p in patterns),command)
