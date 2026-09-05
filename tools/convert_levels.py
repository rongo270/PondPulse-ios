#!/usr/bin/env python3
"""Convert PondPulse's Kotlin level data (LevelMaps1to10 / 11to20 / 21to30,
plus BonusLevels.kt) into generated Swift (LevelMaps1/2/3.swift, BonusMaps.swift).
Mirrors ids, slack, rows and tips 1:1.

The three map files were called Levels.kt / MoreLevels.kt / NewLevels.kt until
Android's "order part 1" split the pack assembly out of them; the Swift file
names did not follow, because they are what the Xcode project references."""
import re
import sys

SRC = "/Users/rongo/AndroidStudioProjects/PondPulse/app/src/main/java/com/rongo/pondpulse/levels"
DST = "/Users/rongo/Desktop/ios/PondPulse/PondPulse/Levels"

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


levels_pars, levels_packs = parse_file(f"{SRC}/LevelMaps1to10.kt")
more_pars, more_packs = parse_file(f"{SRC}/LevelMaps11to20.kt")
new_pars, new_packs = parse_file(f"{SRC}/LevelMaps21to30.kt")

emit(levels_pars, levels_packs, f"{DST}/LevelMaps1.swift", "Hand-drawn packs 1-10 (LevelMaps1to10.kt)")
emit(more_pars, more_packs, f"{DST}/LevelMaps2.swift", "Generated packs 11-20 (LevelMaps11to20.kt)")
emit(new_pars, new_packs, f"{DST}/LevelMaps3.swift", "Generated packs 21-30 (LevelMaps21to30.kt)")

# sanity: every draft has a par
all_pars = {**levels_pars, **more_pars, **new_pars}
missing = [d[0] for packs in (levels_packs, more_packs, new_packs) for ds in packs.values() for d in ds if d[0] not in all_pars]
if missing:
    print("MISSING PARS:", missing)
    sys.exit(1)
total = sum(len(ds) for packs in (levels_packs, more_packs, new_packs) for ds in packs.values())
print(f"total levels: {total}")


# ---------------------------------------------------------------- bonus ponds

# `bonusDraft(` on Android since the golden ponds got a draft type of their own -
# and capital-D `Draft` is why a case-sensitive `draft\(` stopped matching.
BONUS_DRAFT_RE = re.compile(r'bonusDraft\(\s*"(b-\d+)",\s*((?:"[^"]*",\s*)+)\)', re.S)


def emit_bonus():
    """BonusLevels.kt -> BonusMaps.swift. One golden pond per stage, all with the
    same generous slack, so only ids, pars and rows travel."""
    text = open(f"{SRC}/BonusLevels.kt").read()
    slack = int(re.search(r"const val SLACK = (\d+)", text).group(1))
    pars_block = re.search(r"private val pars = mapOf\((.*?)\n    \)", text, re.S).group(1)
    pars = {m.group(1): int(m.group(2))
            for m in re.finditer(r'"(b-\d+)"\s+to\s+(\d+)', pars_block)}

    drafts = []
    for m in BONUS_DRAFT_RE.finditer(text):
        rows = re.findall(r'"([^"]*)"', m.group(2))
        drafts.append((m.group(1), rows))

    if len(drafts) != len(pars):
        print(f"BONUS DRAFTS: parsed {len(drafts)} for {len(pars)} pars - the "
              "Kotlin shape moved; fix BONUS_DRAFT_RE before writing.")
        sys.exit(1)
    missing = [d for d, _ in drafts if d not in pars]
    if missing:
        print("MISSING BONUS PARS:", missing)
        sys.exit(1)

    lines = [
        "//",
        "//  BonusMaps.swift",
        "//  PondPulse",
        "//",
        "//  GENERATED from the Android BonusLevels.kt - do not edit by hand.",
        "//  Regenerate with tools/convert_levels.py.",
        "//",
        "//  The 30 bonus ponds, one closing every stage. Wide open water, a whole",
        "//  brood to bring home, and a budget nobody runs out of.",
        "//",
        "",
        "extension LevelMaps {",
        f"    /// Bonus ponds are meant to be splashed around in, so the budget is huge.",
        f"    static let bonusSlack = {slack}",
        "",
        "    static let bonusPars: [String: Int] = [",
    ]
    for i in range(0, len(drafts), 10):
        chunk = drafts[i:i + 10]
        lines.append("        " + " ".join(f'"{d}": {pars[d]},' for d, _ in chunk))
    lines.append("    ]")
    lines.append("")
    lines.append("    /// In play order: one pond per stage, gentlest first.")
    lines.append("    static let bonus: [BonusDraft] = [")
    for lid, rows in drafts:
        row_lits = ", ".join(f'"{swift_escape(r)}"' for r in rows)
        lines.append(f'        BonusDraft("{lid}", [{row_lits}]),')
    lines.append("    ]")
    lines.append("}")
    lines.append("")
    open(f"{DST}/BonusMaps.swift", "w").write("\n".join(lines))
    print(f"{DST}/BonusMaps.swift: {len(drafts)} bonus ponds, {len(pars)} pars, slack {slack}")


emit_bonus()


# ---------------------------------------------------------------- toughness

def emit_toughness():
    """Levels.kt's `toughness` map -> Toughness.swift.

    Measured bluff@2 per pond: the chance a player who taps sensibly but never
    plans ahead wins anyway. Lower is harder. This, not par, is what orders the
    ponds inside a stage and what grades a stage's difficulty chip."""
    text = open(f"{SRC}/Levels.kt").read()
    # Android renamed this map `toughness` -> `feel` (2026-08); accept either.
    m = re.search(r"private val (?:toughness|feel) = mapOf<String, Double>\((.*?)\n    \)", text, re.S)
    if m is None:
        raise SystemExit("convert_levels: no toughness/feel map found in Levels.kt")
    block = m.group(1)
    entries = re.findall(r'"([\d-]+)"\s+to\s+([\d.]+)', block)

    lines = [
        "//",
        "//  Toughness.swift",
        "//  PondPulse",
        "//",
        "//  GENERATED from the Android Levels.kt `toughness` map - do not edit by hand.",
        "//  Regenerate with tools/convert_levels.py.",
        "//",
        "",
        "extension LevelMaps {",
        "    /// Measured `bluff@2` for every pond: the chance a player who taps sensibly",
        "    /// but never plans ahead wins anyway. **Lower is harder**, and this - not par",
        "    /// - is what decides a pond's place in the game.",
        "    static let toughness: [String: Double] = [",
    ]
    for i in range(0, len(entries), 5):
        chunk = entries[i:i + 5]
        lines.append("        " + " ".join(f'"{k}": {v},' for k, v in chunk))
    lines.append("    ]")
    lines.append("}")
    lines.append("")
    open(f"{DST}/Toughness.swift", "w").write("\n".join(lines))
    print(f"{DST}/Toughness.swift: {len(entries)} measurements")


emit_toughness()
