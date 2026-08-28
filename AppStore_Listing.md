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

**Five products, and only five.** PondPulse used to sell every theme, pond friend
and lily pad as its own $0.49–$0.99 non-consumable — 23 products. It does not any
more: **cosmetics are bought with coins**, and coins are earned by playing (every
clear, every three-star, every golden pond, the Daily Pond, Splash Rush and the
pond's four mini games all pay in). The coin packs below are a shortcut for people
who would rather not wait, never a gate.

All prices USD; Apple maps them to local price points. Reference names and ids must
match `PondPulse/Products.storekit` (already in the project) and `Catalog.swift`.

| Product ID | Type | Reference name | Price |
|---|---|---|---|
| `premium` | Non-consumable | PondPulse Premium | **$2.99** |
| `hints_50` | **Consumable** | Hint Pack (50) | **$0.99** |
| `coins_100` | **Consumable** | 100 Coins | **$0.99** |
| `coins_250` | **Consumable** | 250 Coins | **$1.99** |
| `coins_500` | **Consumable** | 500 Coins | **$3.49** |

### Display names and descriptions

| Product | Display name | Description |
|---|---|---|
| `premium` | PondPulse Premium | 150 more ponds, every pond open instantly, unlimited hints, and nine exclusive pond friends, lily pads and a theme — one purchase, yours forever. |
| `hints_50` | Hint Pack (50) | 50 extra hints for tricky ponds. |
| `coins_100` | 100 Coins | 100 coins to spend on pond friends, lily pads, themes and decorations. |
| `coins_250` | 250 Coins | 250 coins to spend on pond friends, lily pads, themes and decorations. |
| `coins_500` | 500 Coins | 500 coins to spend on pond friends, lily pads, themes and decorations. |

> **Nothing else is created in App Store Connect.** Every friend, lily pad, theme,
> decoration, sky and pond seat is priced in coins inside the app (`CoinBank`), or
> handed out for reaching a level, clearing golden ponds, or holding a daily
> streak. The nine premium exclusives (Royal Lagoon, Baby Dragon, Narwhal, Beaver,
> Phoenix Duckling, Unicorn Duck, Royal Crown, Aurora, Sunburst) come with
> `premium` and are not separately purchasable.

**Review note for every IAP:** attach the Shop screenshot from
`AppStore_Screenshots/` (Apple requires an IAP review screenshot). For the three
coin packs, the same screenshot is fine — it shows the coin balance and the packs.

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

**Keywords** (≤100, comma-separated, no spaces) — 98 chars
```
duck,pond,ripple,water,splash,logic,brain,zen,relaxing,casual,offline,kids,puzzles,turtle,lily,tap
```

**Promotional Text** (≤170, editable anytime without review) — 169 chars
```
450 solver-proven ripple puzzles. One tap makes a splash and every floater drifts. Earn coins, build a pond of your own, and keep the ducklings company. No ads, offline.
```

**Description** (≤4000)
```
Tap the pond. Ripples do the rest.

PondPulse is a gentle one-finger puzzle game. Every tap makes a splash, and every splash pushes each floating duckling one step away from it. Banks, rocks and other floaters block the drift; currents carry everything one extra step. Guide every duckling onto a lily pad before your splashes run out — sounds simple, plans beautifully.

ONE FINGER, REAL DEPTH
No timers in the campaign, no move-by-move pressure — just you, the water, and that lovely "aha" when the whole pond falls into place. Solve in par for three stars.

450 PONDS, 9 PACKS, 30 STAGES
From First Splashes to Legend Lagoon: turtles that squat on pads, colored ducklings that want matching pads, currents that drag the whole pond, and rock mazes that bend your ripples. Every single pond is solver-proven — a solution always exists, and a pond that can no longer be won says so and offers you the move back.

30 GOLDEN PONDS
Every stage is closed by a golden pond, and each one pays out a prize you can see coming: a new pond friend, a lily pad, a theme or a decoration for your own pond.

MY POND
Once you own three friends, they get somewhere to live. Tap the water and it answers — they glide, bump and settle wherever the ripples leave them. Choose who swims, buy more seats, and arrange the place yourself: 16 decorations to drag exactly where you want them, on the bank or on the water, under any of 6 skies from bright day to falling snow.

FOUR LITTLE GAMES
Ripple Chain, Duckling Round-up, Hide & Seek and Splash Target — small, quiet things to do with the friends you have earned, each paying a few coins.

DAILY POND
One pond a day, the same for everyone, and a streak worth keeping. Three pond friends are only ever earned by holding one.

⚡ SPLASH RUSH
A timed dash through random ponds, easy to hard. Bank stars in 1, 3 or 5 minute runs and chase your best score.

SMART HINTS
Stuck? The built-in solver finds the actual next move of a shortest solution and glows where to tap. You start with 150 free hints, and a pond only ever spends one — replaying its hint is free forever.

COINS, EARNED BY PLAYING
Clears, three-stars, golden ponds, the Daily Pond, Splash Rush and the pond's games all pay coins, and coins buy everything cosmetic: 36 pond friends, 22 lily pad styles, 12 hand-tuned themes, 16 decorations and 6 skies. Coin packs exist if you would rather not wait. Nothing is on a timer and nothing expires.

PREMIUM, ONCE
A single optional purchase adds 150 more ponds (301–450), opens every pond instantly in any order, grants unlimited hints, and includes nine exclusive pond friends, lily pads and a theme. No subscription, no ads, ever.

ALSO
• Fully offline — planes, trains, bathtubs
• 16 languages, switchable in-app, with full right-to-left Hebrew and Arabic
• Progress saved on your device
• A living home pond — splash it, shove the duck around, and maybe leave it napping on the top-left pad for a little surprise

Dive in. The ducklings are waiting.
```

**What's New — v1.0**
> First submission, so App Store Connect asks for the description above rather
> than release notes. Keep this for the 1.1 update.
```
First release: 450 ripple puzzles across 9 packs and 30 stages, 30 golden ponds, Splash Rush, a Daily Pond with streaks, and My Pond — a pond of your own with four little games, 36 friends, 16 decorations and 6 skies. No ads, fully offline.
```

---

## 4. Hebrew (עברית)

**App Name** (≤30)
```
PondPulse
```

**Subtitle** (≤30) — 26 chars
```
פאזל אדוות — ברווזים הביתה
```

**Keywords** (≤100, comma-separated, no spaces)
```
ברווז,אגם,אדוות,מים,פאזל,היגיון,מוח,רגוע,זן,ילדים,צב,חמוד,אופליין,לוגיקה,טאפ
```

**Promotional Text** (≤170)
```
‏450 חידות אדוות מוכחות־פתרון. טאפ אחד יוצר אדווה וכל הצפים נסחפים. צברו מטבעות, בנו אגם משלכם והישארו לחברת הברווזונים. בלי פרסומות, אופליין.
```

**Description** (≤4000)
```
מקישים על האגם. האדוות עושות את השאר.

PondPulse הוא משחק פאזל עדין באצבע אחת. כל הקשה יוצרת אדווה, וכל אדווה דוחפת כל ברווזון צף צעד אחד ממנה והלאה. גדות, סלעים וצפים אחרים חוסמים את הסחיפה; זרמים גוררים הכול צעד נוסף. הביאו כל ברווזון אל עלה נענופר לפני שההתזות נגמרות — נשמע פשוט, מתוכנן נהדר.

אצבע אחת, עומק אמיתי
בלי שעון עצר בקמפיין ובלי לחץ — רק אתם, המים, ורגע ה"אהה" כשהאגם כולו מסתדר. פתרו בפָּאר לשלושה כוכבים.

‏450 אגמים, 9 חבילות, 30 פרקים
מהתזות ראשונות ועד לגונת האגדות: צבים שמתיישבים על עלים, ברווזונים צבעוניים שדורשים עלה תואם, זרמים שגוררים את כל האגם ומבוכי סלעים שמעקמים את האדוות. כל אגם הוכח כפתיר — ואגם שכבר אי אפשר לנצח בו אומר זאת ומציע לכם לחזור צעד אחורה.

‏30 אגמי זהב
כל פרק נחתם באגם זהב, וכל אחד מהם משלם פרס שרואים מראש: חבר אגם חדש, עלה נענופר, ערכת נושא או קישוט לאגם שלכם.

האגם שלי
כשיש לכם שלושה חברים, הם מקבלים מקום לגור בו. הקישו על המים והם עונים — הם גולשים, מתנגשים ונחים היכן שהאדוות משאירות אותם. בחרו מי שוחה, קנו עוד מקומות, וסדרו את המקום בעצמכם: 16 קישוטים לגרירה בדיוק לאן שתרצו, על הגדה או על המים, תחת 6 שמיים שונים — מיום בהיר ועד שלג יורד.

ארבעה משחקונים
שרשרת אדוות, איסוף ברווזונים, מחבואים ומטרת התזה — דברים קטנים ורגועים לעשות עם החברים שהרווחתם, וכל אחד מהם משלם כמה מטבעות.

האגם היומי
אגם אחד ביום, זהה לכולם, ורצף ששווה לשמור עליו. שלושה חברי אגם מגיעים רק ממנו.

⚡ ספלאש ראש
מרוץ נגד הזמן דרך אגמים אקראיים, מקל לקשה. צברו כוכבים בריצות של 1, 3 או 5 דקות ושברו שיאים.

רמזים חכמים
נתקעתם? הפותרן המובנה מוצא את המהלך הבא של פתרון קצר ביותר ומאיר היכן להקיש. מתחילים עם 150 רמזים חינם, וכל אגם מחייב רמז פעם אחת בלבד — הצגה חוזרת חינם לתמיד.

מטבעות, מרוויחים במשחק
פתרונות, שלושה כוכבים, אגמי זהב, האגם היומי, ספלאש ראש והמשחקונים — כולם משלמים מטבעות, והמטבעות קונות כל דבר קוסמטי: 36 חברי אגם, 22 סגנונות עלים, 12 ערכות נושא, 16 קישוטים ו־6 שמיים. יש גם חבילות מטבעות למי שמעדיף לא לחכות. שום דבר לא על שעון ושום דבר לא פג.

פרימיום, פעם אחת
רכישה אופציונלית אחת מוסיפה 150 אגמים (301–450), פותחת כל אגם מיידית בכל סדר, מעניקה רמזים ללא הגבלה וכוללת תשעה חברי אגם, עלים וערכת נושא בלעדיים. בלי מנוי, בלי פרסומות, לעולם.

ועוד
• לגמרי אופליין
• 16 שפות, כולל עברית וערבית מלאות מימין לשמאל
• ההתקדמות נשמרת על המכשיר שלכם
• אגם בית חי — התיזו בו, דחפו את הברווז, ואולי השאירו אותו מנמנם על העלה השמאלי־עליון להפתעה קטנה

קפצו פנימה. הברווזונים מחכים.
```

**What's New — v1.0**
```
גרסה ראשונה: 450 חידות אדוות ב־9 חבילות ו־30 פרקים, 30 אגמי זהב, ספלאש ראש, אגם יומי עם רצפים, והאגם שלי — אגם משלכם עם ארבעה משחקונים, 36 חברים, 16 קישוטים ו־6 שמיים. בלי פרסומות, לגמרי אופליין.
```

---

## 5. Screenshots (in `AppStore_Screenshots/`)

| Size | Device used | Required |
|---|---|---|
| 6.9" iPhone (1320×2868) | iPhone 17 Pro Max simulator | ✅ yes |
| 13" iPad (2064×2752) | iPad Pro 13" simulator | ✅ yes (app supports iPad) |

Order suggestion: Home (living pond) → Game board mid-puzzle → Win card →
**My Pond** → **Decorate** → Pack stages → Shop → Splash Rush.

> ⚠️ The captured set predates My Pond, Decorate, the Daily Pond and the four
> games, and the Shop shot still shows the old $0.49–$0.99 cosmetic cards. Re-run
> the capture before submitting. The debug launch hooks drive straight to each
> screen, e.g.
>
> ```
> SIMCTL_CHILD_PP_PREMIUM=1 SIMCTL_CHILD_PP_COINS=9000 \
>   SIMCTL_CHILD_PP_START_SCREEN=pond \
>   xcrun simctl launch booted com.rongo.pondpulse
> ```
>
> `PP_START_SCREEN` takes `packs|shop|rush|daily|pond|decorate|settings`, and
> `PP_START_GAME` takes `chain|herd|seek|target`.

---

## 6. Submission checklist

- [ ] Create the app record (bundle `com.rongo.pondpulse`, name PondPulse)
- [ ] Create the **5** IAPs from section 2 and attach the shop screenshot to each
- [ ] Paste EN + HE texts
- [ ] Re-capture screenshots (see the warning in section 5), then upload
- [ ] Privacy: "Data Not Collected"; paste hosted privacy + support URLs
- [ ] Archive in Xcode (scheme PondPulse, Any iOS Device) → Organizer → Distribute
- [ ] Submit the IAPs **together with** the 1.0 build for review
