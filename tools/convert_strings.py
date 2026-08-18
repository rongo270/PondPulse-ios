#!/usr/bin/env python3
"""Convert PondPulse's Android strings.xml (16 locales) into generated Swift
lookup tables (L10nTables.swift). Keys stay identical to Android.
Android positional %n$s becomes iOS %n$@; \' \" \n unescaped."""
import re
import xml.etree.ElementTree as ET

RES = "/Users/rongo/AndroidStudioProjects/PondPulse/app/src/main/res"
OUT = "/Users/rongo/Desktop/ios/PondPulse/PondPulse/Localization/L10nTables.swift"

LOCALES = [
    ("values", "en"), ("values-ar", "ar"), ("values-de", "de"), ("values-es", "es"),
    ("values-fr", "fr"), ("values-hi", "hi"), ("values-in", "id"), ("values-it", "it"),
    ("values-iw", "he"), ("values-ja", "ja"), ("values-ko", "ko"), ("values-pl", "pl"),
    ("values-pt", "pt"), ("values-ru", "ru"), ("values-tr", "tr"), ("values-zh", "zh"),
]


def android_unescape(s):
    s = s.replace("\\'", "'").replace('\\"', '"').replace("\\n", "\n").replace("\\\\", "\\")
    # %1$s -> %1$@ ; bare %s -> %@ (ints %d stay as-is)
    s = re.sub(r"%(\d+\$)s", r"%\1@", s)
    s = re.sub(r"%s", "%@", s)
    return s


def swift_escape(s):
    return (
        s.replace("\\", "\\\\").replace('"', '\\"')
        .replace("\n", "\\n").replace("\t", "\\t")
    )


def load(dirname):
    tree = ET.parse(f"{RES}/{dirname}/strings.xml")
    out = {}
    for node in tree.getroot().iter("string"):
        text = "".join(node.itertext())
        out[node.get("name")] = android_unescape(text)
    return out


tables = {lang: load(d) for d, lang in LOCALES}
en_keys = set(tables["en"])
lines = [
    "// GENERATED from the Android res/values*/strings.xml by tools/convert_strings.py — do not edit by hand.",
    "// Keys are identical to Android; positional %n$s was converted to %n$@.",
    "",
]
for _, lang in LOCALES:
    table = tables[lang]
    extra = set(table) - en_keys
    if extra:
        print(f"WARNING {lang}: keys not in en: {sorted(extra)}")
    lines.append("extension L10n {")
    lines.append(f"    static let {lang}: [String: String] = [")
    for key in sorted(table):
        lines.append(f'        "{key}": "{swift_escape(table[key])}",')
    lines.append("    ]")
    lines.append("}")
    lines.append("")
open(OUT, "w").write("\n".join(lines))
for _, lang in LOCALES:
    missing = en_keys - set(tables[lang])
    tag = f" (missing {len(missing)}: {sorted(missing)[:4]}…)" if missing else ""
    print(f"{lang}: {len(tables[lang])} strings{tag}")
