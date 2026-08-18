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
        "b-1": 3, "b-2": 3, "b-3": 3, "b-4": 3, "b-5": 3, "b-6": 4, "b-7": 4, "b-8": 4, "b-9": 4, "b-10": 4,
        "b-11": 3, "b-12": 3, "b-13": 3, "b-14": 3, "b-15": 4, "b-16": 4, "b-17": 4, "b-18": 5, "b-19": 5, "b-20": 5,
        "b-21": 4, "b-22": 4, "b-23": 4, "b-24": 4, "b-25": 5, "b-26": 5, "b-27": 5, "b-28": 6, "b-29": 6, "b-30": 6,
    ]

    /// In play order: one pond per stage, gentlest first.
    static let bonus: [BonusDraft] = [
        BonusDraft("b-1", ["..O...", ".D.D..", "O..D..", "..O..~"]),
        BonusDraft("b-2", [".....~", ".D.DD.", ".D..O.", "....TO", "~~OO.."]),
        BonusDraft("b-3", [".....O", "OD..D.", "...DD.", ".#OO.."]),
        BonusDraft("b-4", ["...O..", "..#...", "T...O.", ".DODD.", "......"]),
        BonusDraft("b-5", ["..#...", "O...O.", "..DDDO", "......"]),
        BonusDraft("b-6", ["O.....", "..D...", ".DDO..", ".TD#..", "..O.O."]),
        BonusDraft("b-7", ["#.....", ".DD.O.", "......", "..OTD.", "~~...O"]),
        BonusDraft("b-8", ["~.O..#", ".D..D.", "...DD.", "OO.O.."]),
        BonusDraft("b-9", ["....O~", "..DO.O", ".DD...", "......"]),
        BonusDraft("b-10", [".O..T.", "OD.D..", "#..D..", "~~..O~"]),
        BonusDraft("b-11", ["~.....", ".D...#", ".ODDDO", "#...OO", "<<...."]),
        BonusDraft("b-12", ["T..OOv", "T#...#", "OO.D..", ".DDD..", "....~~"]),
        BonusDraft("b-13", [".....~", "O.D.T.", "O..D^#", "..DD^#", ".OO..."]),
        BonusDraft("b-14", ["..<..T", "..OD..", "...D#.", ".DO.D.", "O.OT.."]),
        BonusDraft("b-15", ["T...O.", "..#D..", ".DD...", "..D.<.", "O.TO.O"]),
        BonusDraft("b-16", ["......", ".OO.O.", "#..DDT", "...DD.", ".v.T.O"]),
        BonusDraft("b-17", ["..T...", ".O#DDT", ".O.DD.", "#O..O.", "......"]),
        BonusDraft("b-18", ["......", "...O..", "TD..D.", ".DD...", "O..O.O"]),
        BonusDraft("b-19", ["..OO.O", "..#.D.", "..D.D.", "OTD.D.", "~~.OT."]),
        BonusDraft("b-20", [".O...~", "OO.D..", "..DDv.", ".D..v.", "~.O..."]),
        BonusDraft("b-21", ["...O..", "#..DO#", ".BD...", "OD.D..", "T>.Ob."]),
        BonusDraft("b-22", ["~~...T", "rO.DO.", ".^#D..", ".R.DT#", "~.O..."]),
        BonusDraft("b-23", ["....br", ".BR...", ".DD.#O", "......", "~~O.#."]),
        BonusDraft("b-24", ["bT...O", "..D.DO", "O.B.D.", "....DO", "......"]),
        BonusDraft("b-25", ["O>..T.", ".DDD..", "...G..", ".OD...", "TOg..O"]),
        BonusDraft("b-26", [".O....", "g.GDD^", "O...D.", "...#..", "....O."]),
        BonusDraft("b-27", ["......", "..RDr.", ".D....", "OD#Dv.", "O..O.O"]),
        BonusDraft("b-28", ["g...T~", "Ov...#", ".D.RDO", "r.G..T", "~~...."]),
        BonusDraft("b-29", ["..r...", "...O..", "v...D.", ".D#DRT", "OO...."]),
        BonusDraft("b-30", [".#..~~", ".OD...", "...#R.", "ODD...", "..rO.~"]),
    ]
}
