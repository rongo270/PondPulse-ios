#!/usr/bin/env python3
"""Convert PondPulse's Kotlin level data (Levels.kt / MoreLevels.kt / NewLevels.kt)
into generated Swift (LevelMaps1/2/3.swift). Mirrors ids, slack, rows and tips 1:1."""
import re
import sys

SRC = "/Users/rongo/AndroidStudioProjects/PondPulse/app/src/main/java/com/rongo/pondpulse/levels"
DST = "/Users/rongo/Desktop/ios/PondPulse/PondPulse"

PACK_RE = re.compile(r"private val pack(\d+) = listOf\(")
DRAFT_RE = re.compile(
    r'draft\(\s*"([^"]+)",\s*(\d+),\s*((?:(?://[^\n]*\s*)*"[^"]*",\s*)+)(?:tipRes = R\.string\.(\w+),?\s*)?\)',
    re.S,
)
PAR_RE = re.compile(r'"(\d+-\d+)"\s+to\s+(\d+)')


def parse_file(path):
    text = open(path).read()
    # pars: only inside the `private val pars = mapOf(...)` block
    pars_block = re.search(r"val pars = mapOf\((.*?)\)\s*\n", text, re.S).group(1)
    pars = {m.group(1): int(m.group(2)) for m in PAR_RE.finditer(pars_block)}

    # walk pack blocks in order; assign drafts to the current pack
    packs = {}
    pack_positions = [(m.start(), int(m.group(1))) for m in PACK_RE.finditer(text)]
    for i, (start, num) in enumerate(pack_positions):
        end = pack_positions[i + 1][0] if i + 1 < len(pack_positions) else len(text)
        chunk = text[start:end]
        drafts = []
        for dm in DRAFT_RE.finditer(chunk):
            level_id, slack, rows_blob, tip = dm.group(1), int(dm.group(2)), dm.group(3), dm.group(4)
            rows = re.findall(r'"([^"]*)"', rows_blob)
            drafts.append((level_id, slack, rows, tip))
        packs[num] = drafts
    return pars, packs


def swift_escape(s):
    return s.replace("\\", "\\\\").replace('"', '\\"')


def emit(pars, packs, out_path, header):
    lines = [
        "// GENERATED from the Android level data by tools/convert_levels.py — do not edit by hand.",
        f"// {header}",
        "",
    ]
    file_tag = re.sub(r"\D", "", out_path.split("/")[-1]) or "1"
    lines.append(f"extension LevelMaps {{")
    lines.append(f"    static let pars{file_tag}: [String: Int] = [")
    for lid in sorted(pars, key=lambda s: (int(s.split("-")[0]), int(s.split("-")[1]))):
        lines.append(f'        "{lid}": {pars[lid]},')
    lines.append("    ]")
    lines.append("}")
    for num in sorted(packs):
        lines.append("")
        lines.append(f"extension LevelMaps {{")
        lines.append(f"    static let pack{num}: [LevelDraft] = [")
        for (lid, slack, rows, tip) in packs[num]:
            row_lits = ", ".join(f'"{swift_escape(r)}"' for r in rows)
            tip_lit = f', tip: "{tip}"' if tip else ""
            lines.append(f'        LevelDraft("{lid}", {slack}, [{row_lits}]{tip_lit}),')
        lines.append("    ]")
        lines.append("}")
    lines.append("")
    open(out_path, "w").write("\n".join(lines))
    n = sum(len(v) for v in packs.values())
    print(f"{out_path}: {len(packs)} packs, {n} levels, {len(pars)} pars")


levels_pars, levels_packs = parse_file(f"{SRC}/Levels.kt")
more_pars, more_packs = parse_file(f"{SRC}/MoreLevels.kt")
new_pars, new_packs = parse_file(f"{SRC}/NewLevels.kt")

emit(levels_pars, levels_packs, f"{DST}/LevelMaps1.swift", "Hand-drawn packs 1-10 (Levels.kt)")
emit(more_pars, more_packs, f"{DST}/LevelMaps2.swift", "Generated packs 11-20 (MoreLevels.kt)")
emit(new_pars, new_packs, f"{DST}/LevelMaps3.swift", "Generated packs 21-30 (NewLevels.kt)")

# sanity: every draft has a par
all_pars = {**levels_pars, **more_pars, **new_pars}
missing = [d[0] for packs in (levels_packs, more_packs, new_packs) for ds in packs.values() for d in ds if d[0] not in all_pars]
if missing:
    print("MISSING PARS:", missing)
    sys.exit(1)
total = sum(len(ds) for packs in (levels_packs, more_packs, new_packs) for ds in packs.values())
print(f"total levels: {total}")
