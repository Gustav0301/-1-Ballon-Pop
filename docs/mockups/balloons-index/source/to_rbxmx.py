import json, sys, itertools
d = json.load(open(sys.argv[1]))
ref = itertools.count(1)
MAT = {'Plastic':256, 'SmoothPlastic':272, 'Neon':288, 'Metal':1088}
SHAPE = {'Ball':0, 'Block':1, 'Cylinder':2}
def f(x): return ('%.4f' % x).rstrip('0').rstrip('.') if abs(x) > 1e-6 else '0'
def cf(name, pos, R):
    return ('<CoordinateFrame name="%s"><X>%s</X><Y>%s</Y><Z>%s</Z>' % (name, f(pos[0]), f(pos[1]), f(pos[2])) +
            ''.join('<R%d%d>%s</R%d%d>' % (i//3, i%3, f(R[i]), i//3, i%3) for i in range(9)) + '</CoordinateFrame>')
def part(p, name='Part'):
    cls = 'WedgePart' if p['shape'] == 'Wedge' else 'Part'
    c = p['color'].lstrip('#'); col = 0xFF000000 | int(c, 16)
    studs = p['mat'] == 'Plastic' and p['transp'] == 0 and p['shape'] in ('Block',)
    s = ['<Item class="%s" referent="RBX%d"><Properties>' % (cls, next(ref)), '<string name="Name">%s</string>' % name,
         cf('CFrame', p['pos'], p['R']),
         '<Vector3 name="size"><X>%s</X><Y>%s</Y><Z>%s</Z></Vector3>' % tuple(f(v) for v in p['size']),
         '<Color3uint8 name="Color3uint8">%d</Color3uint8>' % col,
         '<token name="Material">%d</token>' % MAT[p['mat']],
         '<float name="Transparency">%s</float>' % f(p['transp']),
         '<bool name="Anchored">true</bool><bool name="CanCollide">false</bool><bool name="CanQuery">false</bool><bool name="CanTouch">false</bool><bool name="CastShadow">false</bool>',
         '<token name="TopSurface">%d</token><token name="BottomSurface">%d</token>' % ((3, 4) if studs else (0, 0))]
    if cls == 'Part': s.append('<token name="shape">%d</token>' % SHAPE[p['shape']])
    s.append('</Properties></Item>')
    return ''.join(s)
def model(name, inner): return '<Item class="Model" referent="RBX%d"><Properties><string name="Name">%s</string></Properties>%s</Item>' % (next(ref), name, inner)
out = []
for k, parts in d.items():
    if not isinstance(parts, list) or k == 'Chest_hinge': continue
    groups = {}
    for p in parts: groups.setdefault(p['path'][0] if p['path'] else '', []).append(p)
    inner = ''.join(part(p) for p in groups.get('', []))
    for g, ps in groups.items():
        if not g: continue
        extra = ''
        if g == 'Lid':
            h = d['Chest_hinge']; extra = part({'shape':'Block','pos':h,'R':[1,0,0,0,1,0,0,0,1],'size':[8.2,.2,.2],'color':'#ffffff','mat':'SmoothPlastic','transp':1}, 'Hinge')
        inner += model(g, extra + ''.join(part(p) for p in ps))
    out.append(model(k, inner))
xml = '<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" version="4">' + model('IndexModels', ''.join(out)) + '</roblox>'
open(sys.argv[2], 'w').write(xml); print(len(xml))
