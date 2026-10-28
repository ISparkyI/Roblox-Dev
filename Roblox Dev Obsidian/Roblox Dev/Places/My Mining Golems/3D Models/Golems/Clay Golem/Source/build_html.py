"""Вставляє clay_golem_blocks.json у шаблон -> ../clay_golem.html"""
import json, os
H = os.path.dirname(os.path.abspath(__file__)); O = os.path.dirname(H)
d = json.load(open(os.path.join(O, "clay_golem_blocks.json"), encoding="utf-8"))
t = open(os.path.join(H, "clay_golem_template.html"), encoding="utf-8").read()
open(os.path.join(O, "clay_golem.html"), "w", encoding="utf-8").write(t.replace("/*DATA*/null", json.dumps(d, ensure_ascii=False, separators=(",", ":"))))
print("ok")
