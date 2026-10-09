import json, pathlib
d = pathlib.Path(__file__).parent
src = (d/'src.html').read_text()
cfg = json.dumps(json.load(open(d/'zones.json')), separators=(',',':')).replace('</','<\\/')
gb = json.dumps(json.load(open(d/'gumball.json')), separators=(',',':')).replace('</','<\\/')
(d/'index.html').write_text(src.replace('__CFG__', cfg).replace('__GUMBALL__', gb))
print('ok', len(src))
