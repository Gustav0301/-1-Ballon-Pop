import json, os
here = os.path.dirname(os.path.abspath(__file__))
bs = json.load(open(here + "/balloons.json"))
s = open(here + "/src.html").read()
s = s.replace("__DATA__", json.dumps({"balloons": bs}, separators=(",", ":")).replace("</", "<\\/"))
app = open(here + "/app.js").read()
s = s.replace('<script src="app.js"></script>', "<script>\n" + app.replace("</script", "<\\/script") + "\n</script>")
open(here + "/index.html", "w").write(s); print(len(s))
