# App Store Connect — PondPulse listing (paste-ready)

Everything you need to fill in App Store Connect. Two localizations: **English (Primary)**
and **Hebrew**. Character counts are within Apple's limits (shown in parentheses).

---

## 1. App information (set once, not per-version)

| Field | Value |
|---|---|
| **Bundle ID** | `com.rongo.pondpulse` |
| **Primary Language** | English (U.S.) |
| **Primary Category** | Games → **Puzzle** |
| **Secondary Category** | Games → **Board** (optional) |
| **Content Rights** | Does not contain, show, or access third-party content |
| **Age Rating** | **4+** (all questionnaire answers = *None*) |
| **Price** | **Free** (monetized by the in-app purchases below) |
| **Support URL** | *required* — host `SUPPORT.md` (see file) and paste its URL |
| **Privacy Policy URL** | *required* — host `PRIVACY.md` (see file) and paste its URL |

Easiest free hosting for both pages: the same public **GitHub Pages** repo used for
Line Quest — add `pondpulse/privacy.md` and `pondpulse/support.md` there.

**App Privacy questionnaire:** select **"Data Not Collected"** (the app is fully
offline; purchases are processed by Apple).

---

## 2. In-app purchases — create these EXACTLY (ids match the Android/Play ids)

All prices in USD; Apple maps them to local price points. Reference names and ids
must match `PondPulse/Products.storekit` (already in the project) and the shop's
`Catalog.swift`.

### The two that matter

| Product ID | Type | Reference name | Price |
|---|---|---|---|
| `premium` | Non-consumable | PondPulse Premium | **$2.99** |
| `hints_50` | **Consumable** | Hint Pack (50) | **$0.99** |

**Premium display name:** "PondPulse Premium" · **description:** "150 more levels,
every level open instantly, unlimited hints, and every exclusive theme, pond friend
and lily pad — one purchase, yours forever."

**Hint pack display name:** "Hint Pack (50)" · **description:** "50 extra hints for
tricky ponds."

### Cosmetic themes — non-consumables, $0.99 each

| Product ID | Reference name |
|---|---|
| `theme_sakura` | Theme: Sakura Pond |
| `theme_neon` | Theme: Midnight Neon |
| `theme_autumn` | Theme: Autumn Gold |
| `theme_frozen` | Theme: Frozen Pond |
| `theme_coral` | Theme: Coral Reef |
| `theme_galaxy` | Theme: Galaxy Night |
| `theme_candy` | Theme: Candy Pop |

### Pond friends (skins) — non-consumables, $0.49 each

| Product ID | Reference name |
|---|---|
| `skin_koi` | Pond Friend: Koi |
| `skin_penguin` | Pond Friend: Penguin |
| `skin_flamingo` | Pond Friend: Flamingo |
| `skin_boat` | Pond Friend: Paper Boat |
| `skin_axolotl` | Pond Friend: Axolotl |
| `skin_otter` | Pond Friend: Otter |
| `skin_jelly` | Pond Friend: Jellyfish |

### Lily pads — non-consumables, $0.49 each

| Product ID | Reference name |
|---|---|
| `pad_ice` | Lily Pad: Ice Floe |
| `pad_shell` | Lily Pad: Seashell |
| `pad_sunflower` | Lily Pad: Sunflower |
| `pad_clover` | Lily Pad: Lucky Clover |
| `pad_gem` | Lily Pad: Crystal Gem |
| `pad_honey` | Lily Pad: Honeycomb |
| `pad_moon` | Lily Pad: Moonlight |

> Not sold separately (so NOT created in App Store Connect): free items, level
> rewards (Jungle Mist, Frog, Swan, Robo Duck, Golden Duck, Lotus, Starlight,
> Rainbow pads) and premium exclusives (Royal Lagoon, Baby Dragon, Narwhal,
> Beaver, Crown, Aurora — included with `premium`).

**Review note for every IAP:** attach the Shop screenshot from
`AppStore_Screenshots/` (Apple requires an IAP review screenshot).

---

## 3. English (Primary)

**App Name** (≤30) — 9 chars
```
PondPulse
```
> If "PondPulse" is taken when you create the record, try: **"PondPulse: Ripple Puzzle"**
> or **"PondPulse — Duck Puzzle"**.

**Subtitle** (≤30) — 28 chars
```
Ripple puzzle. Ducks go home
```

**Keywords** (≤100, comma-separated, no spaces) — 97 chars
```
duck,pond,ripple,water,splash,logic,brain,zen,relaxing,casual,offline,kids,puzzles,turtle,lily,tap
```

**Promotional Text** (≤170, editable anytime without review)
```
450 hand-proven ripple puzzles. One tap makes a splash, every floater drifts — guide each duckling to its lily pad. No ads, fully offline, play at your own pace.
```

**Description** (≤4000)
```
Tap the pond. Ripples do the rest.

PondPulse is a gentle one-finger puzzle game. Every tap makes a splash, and every splash pushes each floating duckling one step away from it. Banks, rocks and other floaters block the drift; currents carry everything one extra step. Guide every duckling onto a lily pad before your splashes run out — sounds simple, plans beautifully.

ONE FINGER, REAL DEPTH
No timers in the campaign, no move-by-move pressure — just you, the water, and that lovely "aha" when the whole pond falls into place. Solve in par for three stars.

450 LEVELS, 30 STAGES
From First Splashes to Legend Lagoon: turtles that squat on pads, colored ducklings that want matching pads, currents that drag the whole pond, and rock mazes that bend your ripples. Every single level is solver-proven — a solution always exists.

⚡ SPLASH RUSH
A timed dash through random ponds, easy to hard. Bank stars in 1, 3 or 5 minute runs and chase your best score.

SMART HINTS
Stuck? The built-in solver finds the actual next move of a shortest solution and glows where to tap. You start with 150 free hints, and a level only ever spends one hint — replays of its hint are free forever.

MAKE THE POND YOURS
11 hand-tuned themes (from Sakura Pond to Galaxy Night), 15 pond friends to float as (frog, swan, koi, penguin, axolotl, baby dragon...), and 13 lily pad styles. Earn many of them just by playing — level rewards are marked in the shop.

PREMIUM, ONCE
A single optional purchase unlocks stages 21–30 (150 more levels), opens every level instantly in any order, grants unlimited hints, and includes every exclusive cosmetic and every future pack. No subscription, no ads, ever.

ALSO
• Fully offline — planes, trains, bathtubs
• 16 languages, switchable in-app
• Progress saved on your device
• A living home pond — splash it, shove the duck around, and maybe leave it napping on the top-left pad for a little surprise

Dive in. The ducklings are waiting.
```

**What's New — v1.0**
```
First release: 450 ripple puzzles across 30 stages, Splash Rush time attack, smart hints, 11 themes, 15 pond friends and 13 lily pad styles. No ads, fully offline.
```

---

## 4. Hebrew (עברית)

**App Name** (≤30)
```
PondPulse
```

**Subtitle** (≤30)
```
פאזל אדוות: הביאו ברווזים הביתה
```

**Keywords** (≤100, comma-separated, no spaces)
```
ברווז,אגם,אדוות,מים,פאזל,היגיון,מוח,רגוע,זן,ילדים,צב,חמוד,אופליין,לוגיקה,טאפ
```

**Promotional Text** (≤170)
```
‏450 חידות אדוות מוכחות־פתרון. טאפ אחד יוצר אדווה, כל הצפים נסחפים — הובילו כל ברווזון אל עלה הנענופר שלו. בלי פרסומות, לגמרי אופליין.
```

**Description** (≤4000)
```
מקישים על האגם. האדוות עושות את השאר.

PondPulse הוא משחק פאזל עדין באצבע אחת. כל הקשה יוצרת אדווה, וכל אדווה דוחפת כל ברווזון צף צעד אחד ממנה והלאה. גדות, סלעים וצפים אחרים חוסמים את הסחיפה; זרמים גוררים הכול צעד נוסף. הביאו כל ברווזון אל עלה נענופר לפני שההתזות נגמרות — נשמע פשוט, מתוכנן נהדר.

אצבע אחת, עומק אמיתי
בלי שעון עצר בקמפיין ובלי לחץ — רק אתם, המים, ורגע ה"אהה" כשהאגם כולו מסתדר. פתרו בפָּאר לשלושה כוכבים.

450 שלבים, 30 פרקים
מהתזות ראשונות ועד לגונת האגדות: צבים שמתיישבים על עלים, ברווזונים צבעוניים שדורשים עלה תואם, זרמים שגוררים את כל האגם ומבוכי סלעים שמעקמים את האדוות. כל שלב הוכח כפתיר.

⚡ ספלאש ראש
מרוץ נגד הזמן דרך אגמים אקראיים, מקל לקשה. צברו כוכבים בריצות של 1, 3 או 5 דקות ושברו שיאים.

רמזים חכמים
נתקעתם? הפותרן המובנה מוצא את המהלך הבא של פתרון קצר ביותר ומאיר היכן להקיש. מתחילים עם 150 רמזים חינם, וכל שלב מחייב רמז פעם אחת בלבד — הצגה חוזרת חינם לתמיד.

אגם משלכם
11 ערכות נושא, 15 חברי אגם לצוף איתם (צפרדע, ברבור, קוי, פינגווין, אקסולוטל, דרקון קטן...) ו־13 סגנונות עלים. הרבה מהם מרוויחים פשוט ממשחק.

פרימיום, פעם אחת
רכישה אופציונלית אחת פותחת את פרקים 21–30 (עוד 150 שלבים), פותחת כל שלב מיידית בכל סדר, מעניקה רמזים ללא הגבלה וכוללת כל קוסמטיקה בלעדית וכל חבילה עתידית. בלי מנוי, בלי פרסומות, לעולם.

ועוד
• לגמרי אופליין
• 16 שפות, כולל עברית מלאה מימין לשמאל
• ההתקדמות נשמרת על המכשיר שלכם

קפצו פנימה. הברווזונים מחכים.
```

**What's New — v1.0**
```
גרסה ראשונה: 450 חידות אדוות ב־30 פרקים, מצב ספלאש ראש, רמזים חכמים, 11 ערכות נושא, 15 חברי אגם ו־13 סגנונות עלים. בלי פרסומות, לגמרי אופליין.
```

---

## 5. Screenshots (already captured in `AppStore_Screenshots/`)

| Size | Device used | Required |
|---|---|---|
| 6.9" iPhone (1320×2868) | iPhone 17 Pro Max simulator | ✅ yes |
| 13" iPad (2064×2752) | iPad Pro 13" simulator | ✅ yes (app supports iPad) |

Order suggestion: Home (living pond) → Game board mid-puzzle → Win card →
Packs → Shop → Splash Rush.

---

## 6. Submission checklist

- [ ] Create the app record (bundle `com.rongo.pondpulse`, name PondPulse)
- [ ] Create all 23 IAPs from section 2 and attach the shop screenshot to each
- [ ] Paste EN + HE texts, upload screenshots
- [ ] Privacy: "Data Not Collected"; paste hosted privacy + support URLs
- [ ] Archive in Xcode (scheme PondPulse, Any iOS Device) → Organizer → Distribute
- [ ] Submit the IAPs **together with** the 1.0 build for review
