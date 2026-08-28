//
//  BonusMaps.swift
//  PondPulse
//
//  GENERATED from the Android BonusLevels.kt - do not edit by hand.
//  Regenerate with tools/convert_levels.py.
//
//  The 30 bonus ponds, one closing every stage. Wide open water, a whole
//  brood to bring home, and a budget nobody runs out of.
//

extension LevelMaps {
    /// Bonus ponds are meant to be splashed around in, so the budget is huge.
    static let bonusSlack = 6

    static let bonusPars: [String: Int] = [
        "b-1": 3, "b-2": 3, "b-3": 3, "b-4": 5, "b-5": 3, "b-6": 4, "b-7": 3, "b-8": 4, "b-9": 3, "b-10": 4,
        "b-11": 3, "b-12": 4, "b-13": 3, "b-14": 3, "b-15": 4, "b-16": 4, "b-17": 3, "b-18": 5, "b-19": 5, "b-20": 3,
        "b-21": 5, "b-22": 4, "b-23": 5, "b-24": 3, "b-25": 4, "b-26": 5, "b-27": 4, "b-28": 7, "b-29": 5, "b-30": 5,
    ]

    /// In play order: one pond per stage, gentlest first.
    static let bonus: [BonusDraft] = [
        BonusDraft("b-1", ["..O...", ".D.D..", "OT.D..", "..O..~"]),
        BonusDraft("b-2", [".....~", ".D.DD.", ".D.TO.", ".....O", "~~OO.."]),
        BonusDraft("b-3", ["O....O", ".D..D.", "...DD.", "..OO.."]),
        BonusDraft("b-4", ["...O..", "..#...", "T...O.", ".D.DD.", ".....O"]),
        BonusDraft("b-5", ["......", "O...O.", "..DDDO", "......"]),
        BonusDraft("b-6", ["O.....", ".OD...", ".DDO..", ".TD...", "..O..."]),
        BonusDraft("b-7", ["......", "TDD.O.", "......", "..O.D.", "~~...O"]),
        BonusDraft("b-8", ["~.O...", ".D..D.", "...DD.", "OO.O.."]),
        BonusDraft("b-9", ["...O.~", "..DO.O", ".DD...", "......"]),
        BonusDraft("b-10", [".O....", "OD.D..", "...D..", "~~..O~"]),
        BonusDraft("b-11", ["~.....", ".D.O..", ".ODDDO", ".....O", "<<...."]),
        BonusDraft("b-12", ["...OOv", "......", "OO.D..", ".DDD..", "...#~~"]),
        BonusDraft("b-13", [".....~", "O.D.T.", "O..D^.", "..DD^.", ".OO<.."]),
        BonusDraft("b-14", ["..<...", "..OD..", "...D..", ".DO.D#", "O.OT.."]),
        BonusDraft("b-15", ["....O.", "...D..", ".DD...", "..D.<.", "O..O.O"]),
        BonusDraft("b-16", ["......", ".OO.O.", "...DDT", "...DD.", ".v...O"]),
        BonusDraft("b-17", ["..T.O.", ".O#DDT", ".O.DD.", "....O.", "......"]),
        BonusDraft("b-18", ["......", "...O..", ".D..D.", ".DD...", "O..O.O"]),
        BonusDraft("b-19", ["..OO.O", "...D..", "..D.D.", "O.D.D.", "~~.O.."]),
        BonusDraft("b-20", [".....~", "OO.D..", "O.DDv.", ".D..v.", "~.O..."]),
        BonusDraft("b-21", ["...OO.", "#..DO.", ".BD...", "OD.D..", ".>..b."]),
        BonusDraft("b-22", ["~~#...", "rO.DO.", ".^.D..", ".R.D..", "~.O..."]),
        BonusDraft("b-23", ["....br", ".BR...", ".DD..O", "......", "~~O.#."]),
        BonusDraft("b-24", ["bT...O", "..D.DO", ".OB.D.", "....DO", "......"]),
        BonusDraft("b-25", ["O>....", ".D.D..", ".O.GD.", "..D...", "TOg..O"]),
        BonusDraft("b-26", [".O....", "g.GDD^", "O...D.", "....O.", "......"]),
        BonusDraft("b-27", ["......", "..RDr.", ".D....", "OD.Dv.", "O..O.O"]),
        BonusDraft("b-28", ["...gT~", "Ov....", ".D.RDO", "r.G...", "~~T..."]),
        BonusDraft("b-29", ["..r...", "..OO..", "v...D.", ".D#DRT", "O....."]),
        BonusDraft("b-30", [".#..~~", ".OD...", "O...R.", "ODD...", "..r..~"]),
    ]
}
