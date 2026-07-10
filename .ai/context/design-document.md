# Townling — Game Design & Product Requirements Document
*Name selected July 2026 (second iteration). "Townling" — a coined word (town + -ling, "a little citizen") — replaced "Savvyburg" after review: -burg is not universally understood and "savvy" is a spelling trap. Townling is spell-as-said, pronounceable for Dutch and international children (no th, no silent letters), and effectively unowned in search. Verified via GoDaddy: townling.app and townling.nl available (register immediately); townling.com is held (no visible business — run WHOIS, consider backorder). Web screening found only one long-dead iOS game once using the word — flag for attorney. Pending before launch: EUIPO/TMview + BOIP search (Nice classes 9, 41, 28), app-store exact-name checks, formal attorney clearance. Prior candidates eliminated: "MoneyTown" (existing games, descriptive-name EU registrability problem per the Cash App EUIPO precedent), "Savvyburg" (pronunciation/spelling/search), Thrivo and Kaboodle (domains fully occupied), Earnling (.app taken, .com premium — likely existing project).*

---

## 1. Vision

Townling is a privacy-first, ad-free financial life simulator for children, built as one economic engine with three age-tuned experiences. Players pick a profession, build skills, earn income, pay for daily life, survive realistic shocks, and learn banking and investing — not through lectures, but because financial cause-and-effect *is* the game engine. Learning is earning. Parents pay for insight, never for in-game advantage. Schools are the second act.

The product in one sentence: *a genuinely fun, mobile-native, kid-safe life simulator where the money model underneath is realistic and the experience on top is easy to understand.*

### Why this and why now

Financial literacy is measurably poor (roughly 57% of US adults qualify as financially literate) and money habits form early — much of the pattern is set by around age 7. Regulation is pushing the same direction: 21 US states now require a personal finance course for high-school graduation, with European equivalents growing, meaning schools and parents are actively searching for tools. Meanwhile the entertainment market has proven the core mechanic: BitLife and its clones demonstrate a massive appetite for profession-income-consequence life simulation — their own users literally request teen jobs, ownable businesses, and earn-money mini-games in App Store reviews. Nobody has combined the mechanic with the mission.

---

## 2. Market Validation Summary

The competitive landscape splits into three camps, and none occupies our position.

**Camp 1 — classroom and web financial simulations** (Get a Life, Payback, Finance 101, Financial Skills Challenge, CFPB games). Closest to us mechanically: pick a career, budget against its salary, make decisions. But they are browser-based classroom tools, often dated (some ran on Flash), short-session, pedagogy-first and fun-last. Kids use them because a teacher said so, never by choice.

**Camp 2 — entertainment life simulators** (BitLife, AltLife, ReLife, Age Sim, The Sims Mobile). They own the fun: choices stack year over year across education, career, and relationships, and the genre is hugely popular on mobile. But money is a scoreboard rather than a lesson, much of the content (crime, drinking, scandal) is not kid-appropriate, and the clones are notorious for aggressive, forced advertising — the number-one complaint in the genre.

**Camp 3 — real-money kids' banking apps** (Greenlight, Acorns Early/GoHenry, RoosterMoney, BusyKid, Zogo). Strong products proving that parents pay monthly subscriptions (~$5/month per child) for children's financial education. But they are fintech, not simulation: they require real money, bank partnerships, and can never simulate a career, a job loss, or a market crash.

**A fourth model, observed in the field (July 2026, from a review of competitor materials):** institutionally-financed, ministry-partnered school programmes — exemplified by Oh Bear!/FLITE, running national pilots in Guyana and Barbados as the Ministry of Education's implementing partner, funded by development banks (~$22/student/year) with teacher-led curriculum sessions, a WhatsApp parent bot fronted by their mascot, and a government oversight dashboard. It is a modern, well-engineered evolution of Camp 1 — still curriculum-first (teach-then-apply pedagogy), still chosen by institutions rather than children, with no simulation, economy, or voluntary-play loop. It does not collide with Townling's category, buyer, geography, or age center, and its own positioning forecloses the consumer space. What it proves for us: the primary-age gap and the parent-engagement layer are recognized by others; deep single-market localization is a winning argument elsewhere too; and this mission attracts institutional money. What it warns us: when Townling's school channel opens (Phase 4), the procurement bar is an institutional documentation stack — signed MOUs, data-protection impact assessment, safeguarding policy, independent pre-registered evaluation — and we will meet players like this there.

**The gap:** the intersection — a genuinely fun, mobile-native, kid-safe simulator where skill→income→shock cause-and-effect is the core loop. The classroom sims have pedagogy without game feel; BitLife has game feel without pedagogy or kid-safety; fintech apps have real stakes without simulation depth.

**The three failure patterns to design against**, learned from incumbents: ad-stuffed experiences (kills the clones' ratings and is a regulatory minefield with children anyway), boring education-first wrappers (a quiz in a game costume), and privacy violations (a 2021 study found 67% of educational kids' apps shared data with third-party advertisers).

**Our protected differentiator:** the skill→income feedback loop with realistic, recoverable shocks, kept kid-readable at every age.

---

## 3. Product Principles

These are the non-negotiables that every later decision must pass through.

1. **Fun first, lesson embedded.** The simulation itself teaches; consequences are the curriculum. Never lecture before the experience — let the experience create the question.
2. **Failure is a story, never a wall.** Every bad state is recoverable, and every recovery is gameplay.
3. **Privacy as a feature.** Collect the absolute minimum. "We know almost nothing about your child" is a headline selling point to the buyer (the parent), not a compliance chore.
4. **Never sell advantage.** No ads, ever. No purchasable in-game money or progress. A game teaching financial responsibility cannot let players swipe a parent's card to escape in-game debt.
5. **Respect the kid's time.** Appointment retention, not slot-machine retention. Natural stopping points every session. "This game respects my kid" keeps subscriptions alive; "my kid can't put it down" cancels them.
6. **One decision per screen.** Complexity lives in the simulation, never in the interface.
7. **The kid is the player; the parent is the customer.** Both must be served explicitly, and the kid must always know what the parent sees.

---

## 4. Age Band Architecture

One simulation engine, three presentation layers. The economic model underneath (income, expenses, savings, shocks) is shared; vocabulary, pacing, visible systems, and content ratings change per band.

| | **Band A: "My Little Shop"** | **Band B: "First Salary"** | **Band C: "Real Life"** |
|---|---|---|---|
| **Age** | ~6–9 | ~10–13 | 14+ (works for adults too) |
| **Time unit** | Days | Weeks/months | Months/years |
| **Money** | Visible coins | Bank account, simple interest | Full accounts, credit, volatility |
| **Professions** | Simple, playful (baker, vet, shopkeeper) | Realistic ladder with skills | Full careers + business ownership |
| **Systems visible** | Earning, wanting, saving up, needs vs wants | Budgeting, banking, saving goals, intro investing ("money that grows slowly but can shrink") | Taxes, credit and debt, investing with volatility, insurance, job loss and re-skilling, rent vs buy, entrepreneurship |
| **Shock intensity** | Gentle ("bike broke — fix or walk?") | Real (phone breaks, pet sick, hobby costs) | Harsh (fired, market crash, inflation, eviction *warning*) |
| **City buildings** | 4 | 6–7 | Full city incl. investment floor and business district |
| **Skill model** | Single "talent stars" per profession | Full skills + experience two-track | Full two-track |
| **Reading support** | Optional voiceover; icons over text | Light text | Normal text; real bank-statement literacy is a goal |

**Graduation is mastery-based, not purely age-based.** Completing the capstone chapters of a band unlocks the next band. Age sets the starting point; mastery sets the ceiling. A capable 12-year-old is never locked out of compound interest. Band C honestly serves adults, quietly doubling the addressable market.

---

## 5. The Game World

### The city diorama hub

The entire game state lives on one fixed, charming, single-screen illustrated town — a diorama, deliberately **not** a scrollable open map. Navigation is not the game; money decisions are. Each building is a large tappable landmark:

**Home** (lifestyle, decorating, rest) · **Workplace** (shifts, promotions) · **Bank** (accounts, savings, later loans and investments) · **School/Library** (skill classes) · **Shop** (groceries, purchases, lifestyle) · **Notice Board** (gigs and missions) · and in Band C, an **investment floor** at the bank and a **business district**.

Forza-style notification badges are the state display: a "!" bounces on the notice board when gigs arrive, a coin glints on the workplace when a shift is ready, the bank pulses when interest was paid. The player reads everything at a glance with zero menus. Tapping a building slides up that building's screen; closing returns to the city. The city is the hub and everything is exactly one level deep — never deeper.

The diorama is also the progress portrait: every achievement must show on it. A better apartment, furniture visible through the window, a shop with the player's name on it, a bike then scooter then car parked outside, trophies from mastered professions (the bakery stays standing, with the character's photo on the wall). This one screen is simultaneously the main menu, the save file made visible, and — critically for the social layer — the thing kids show each other.

The city grows with the age band, doubling as a progression reward: Band A sees four buildings, Band C sees the full skyline.

### Characters

**The player avatar.** Fully customizable within kid-safe bounds. Display names are enforced-fictional for child accounts (no real names). Cosmetic identity (outfits, room decoration, pets) is a core reward channel because it is visible on the diorama and the share card.

**The mentor.** A consistent guide — presented as a warm, slightly quirky figure (a grandparent-like character for Bands B/C; a talking piggy bank for Band A). The mentor's rules: appears *after* consequences, never before; asks reflective questions ("that surprise bill hurt — what could past-you have done?"); delivers the diagnosis after failures; fronts the recovery arcs; and openly tells the kid what the parent can see ("your grown-up gets a postcard about your week"). Reflection is where learning transfers to real life — the mentor is the pedagogical heart of the game.

**NPCs.** Employers, shopkeepers, quiz-night hosts, neighbors who offer gigs. Functional, light, warm. No romance, no antagonists beyond circumstance. The "villain" of this game is always the situation (the broken phone, the interest rate), never a person.

---

## 6. Game Loops and the Time Model

### Four nested loops

**The moment loop (1–3 minutes).** Do one thing — a work shift, a gig, a quiz, a purchase, a class. Every action returns immediate feedback: a result card, money animating into or out of the wallet.

**The day loop (one session, ~5–10 minutes).** The heartbeat: morning plan → spend the day's activity slots → evening summary (earnings in, spending out) → the event slot (shock or opportunity card) → day closes. A natural stopping point ends every session.

**The week loop (the teaching engine).** Every 7th in-game day is **payday**: salary lands, bills auto-deduct, and the player sees the week's net result in one simple picture. The mentor appears here for reflection. Budgeting is learned at the week scale, never the day scale, because a single day never shows the pattern. Payday is also when the parent digest email is generated.

**The chapter loop (weeks, the season structure).** A self-contained story with a goal, an obstacle, a deadline, and an ending: "Save 500 for the school trip before the deadline," "Your bakery's oven died — survive the month and replace it," "You got fired — land a better job within eight weeks." Chapters provide the reason to open the app today (the ticking deadline), the safe container for failure (a failed chapter restarts as "attempt 2" — costing pride, not progress), and the renewable content stream that justifies a subscription. Chapter endings host the biggest unlocks, the mode graduations, and the permanent diorama trophies.

### Inside a day: energy slots, not clock time

Each in-game day grants **3 activity slots** (morning/afternoon/evening for Bands B/C; three "energy stars" for Band A). A work shift consumes one slot and resolves via a single tap or an optional 30–60 second mini-game — the character works "offscreen" and a result card shows the outcome. Remaining slots go to a class, gigs, shopping, or **rest**, which refills the wellbeing meter — deliberately teaching that rest is a resource, not laziness. Nobody ever watches an 8-hour workday; a full in-game day is a 5–10 minute session, and "how the day passed" is really "how you chose to spend three slots" — a time-budgeting lesson wearing a game mechanic's clothes.

### Across days: one real day = one in-game day

Game time anchors to real time, tamagotchi-style. Rationale: it creates the appointment habit ("my life is waiting for me tomorrow") that drives retention without addiction mechanics; it makes payday a genuine weekly ritual synchronized with the parent digest; it makes saving *feel* like waiting — the actual emotional skill behind saving; and it naturally caps session length, which the paying parent values.

Rules attached to the model: missing real days is always safe — the character runs gentle autopilot (attends work, pays bills, buys nothing) and the game warmly recaps on return, never punishes absence. Chapters and weekly challenges may locally compress time when the story needs it ("three weeks later…"). The eager player is served with *depth per day* — extra gigs, quiz gigs, decorating, visiting friends' cities — never with more days per sitting.

---

## 7. Economy Design

### Jobs vs. business: both, sequenced — the sequencing is the lesson

Business is not a character-creation choice; it is the **earned second act**. A job comes first: predictable salary, budgeting learned on stable income, low cognitive load. After demonstrated mastery (a savings buffer, a survived shock, built skills), the game offers the leap: quit or go part-time and start a business. Business inverts every rule the player has internalized — income becomes variable, money must be spent to make money (stock, equipment), and profit responds to decisions rather than hours. That felt contrast (salary = stability; business = risk and upside) is the finance lesson itself. Band A gets the miniature version: a weekend lemonade stand alongside the job. Band C gets the full path — pricing, hiring, the real possibility of failure, and returning to employment framed explicitly as a smart move, never a defeat.

### Full-time jobs vs. gigs: two design roles

The **full-time job is the economy anchor** — baseline income ticking with the calendar. It requires no grinding: showing up is one tap or a short optional mini-game, and *skill level, not repetition,* sets the salary. Its purpose is stability and a meaningful payday.

**Gigs and missions are the active gameplay** — 1–3 minute optional tasks from the notice board, paid instantly: dog-walking, fixing a neighbor's bike, and the knowledge gigs (see Learning Design). Gigs answer "I want more money *now*," mirroring real life: salary is slow, safe, automatic; hustle is fast, effortful, capped. **Hard balance rule: gigs must never out-earn a good salary long-term** — otherwise the game accidentally teaches the wrong lesson.

### Skills vs. experience: two different things, because they are in real life

**Skill = what you can do** (baking, coding, communication, driving). Raised deliberately through classes at the school building, practice, and skill-tagged gigs. Skills *gate job entry* and set the salary ceiling. Skills are partially transferable — communication helps every career; baking doesn't help a mechanic — and that transferability is itself taught.

**Experience = proof you've done it.** Accrues automatically with every shift. Experience gates *promotion*, not entry. Changing careers carries skills partially but largely resets experience — the real-world cost of switching fields, felt rather than explained.

**Nobody is ever locked out of earning.** Entry-level jobs and basic gigs (paper route, dishwasher, dog walking) are always open. But good jobs require skills and great positions require skills plus experience, so the ladder is discovered naturally: *learning raises your ceiling; showing up raises your position.* This single sentence is the most valuable thing the game teaches.

Feedback flows: shifts give experience plus a sliver of on-the-job skill; classes give skill; skill-tagged gigs give a little of both plus cash. Band A collapses the two-track system into one visible "talent stars" meter per profession; the full model unlocks at Band B.

---

## 8. The Purpose Economy — What Money Buys and Why Players Earn

The design law that keeps the economy honest: **every unit of in-game money spent must buy one of six things, and they are the same six things money buys in real life.** If money becomes a mere score and purchases mere decoration, the game teaches that money is for decoration — the exact wrong lesson.

**1. Survival (the treadmill).** Groceries, rent, phone bill, transport drain automatically and sustain the wellbeing meter. This is *why the player must earn*: the character's life has running costs, and payday exists in tension with them. No treadmill, no stakes.

**2. Security (the buffer).** Savings and, in Band C, insurance exist because of the evening event card. A player who has felt a shock land on an empty wallet understands the savings jar viscerally — and chooses the buffer voluntarily next time. The game makes sleep-at-night safety a felt experience.

**3. Capability (functional assets — houses and vehicles are mechanics, not trophies).** Big purchases must change what the player can *do*. A bike reaches two gigs per energy slot instead of one; a laptop unlocks the freelance gig category; a car unlocks higher-paying jobs across town — **and carries running costs** (fuel, insurance, maintenance events). A fancier car does the same job with higher upkeep plus status: the total-cost-of-ownership and asset-vs-liability lessons taught through play. Homes work identically: better rest (faster energy refill), a kitchen that unlocks the baking business, a garage for the shop, and in Band C a spare room rentable for passive income. In Band C, property becomes a full asset class — rent vs. buy with a real mortgage, moving values, and selling at a profit *or a loss* — because a home is the largest financial decision most adults ever face and nobody teaches it.

**4. Growth (money making money).** Education raises the salary ceiling; investments (Band B's "grows slowly but can shrink," Band C's genuine volatility) and the business path transform the player from worker into owner. Deliberately a mid-to-late-game discovery.

**5. Identity (status — real but honest).** Decorations, outfits, the nice car's shine: visible on the diorama and the share card, genuinely motivating (the comparison currency of the social layer). The design tells the truth about it: status spending advances nothing in the simulation. A player who blows three paydays on decor and then can't absorb a shock has experienced lifestyle inflation from the inside. Never scolded — allowed to teach.

**6. Giving (the forgotten purpose).** Fundable town projects — a playground, cleaning the park, the animal shelter — visibly improve the city and draw NPC reactions, completing the classic spend/save/give triad of children's financial education.

### The dream system (the emotional engine)

Every character has a **dream**, chosen by the player early and rendered on the diorama as a faded, dotted-outline version of itself: the treehouse, the bakery with their name on it, the trip to the ocean, adopting the dog. Chapters are stepping stones toward it; money is explicitly the bridge between work and the dream. Players don't ultimately earn to *have* money — they earn so their little person gets the life imagined for them (the nurture loop's deepest hook). A completed dream turns solid on the diorama permanently, and a new, bigger dream is chosen.

### The freedom endgame (Band C)

When assets and passive income cover lifestyle costs, the game names the moment — **financial independence** — and the state changes meaningfully: the character no longer *has* to work, and every energy slot becomes truly the player's own. The truest definition of what money is for, and a fitting mastery state: reaching it proves the player has internalized the entire curriculum — earn, protect, invest, own.

### The motivational chain, end to end

Treadmill creates urgency → shocks create the need for security → capability purchases create acceleration → the dream creates pull → status creates pride along the way → giving creates meaning → freedom is the horizon. Each link is simultaneously a game incentive and a true statement about money.

---

## 9. Progression — When Kids Level Up

There is deliberately **no generic XP bar** (see Discarded Ideas). Leveling happens through four concrete channels, each with its own rhythm, and always at **ritual moments** — end of class, payday, chapter end — never as random mid-play popups. Progress must always feel earned and *explainable* ("I got promoted because I studied and showed up"), because attribution is the lesson.

**Skill levels — the fast loop (every few days).** Completing a class or enough practice earns a skill star, immediately, with fanfare.

**Promotions — the medium loop (every week or two).** Experience threshold + skill requirement met → a promotion *event* arrives (a letter, an interview scene). New title, new salary, visible next payday.

**Chapter completions — the big loop (every few weeks).** The major ceremony: a big unlock (new profession, the business path, a city upgrade) and a permanent trophy on the diorama.

**Mode graduation — the rare, huge one.** Mastery-based band promotion: completing a band's capstone chapters literally opens the next version of the city.

---

## 10. Consequence Design — What Happens When Players Do Badly

Failure must be a story, never a wall. A kid stuck in an unrecoverable state doesn't learn; they delete the app and feel worse about money — the exact opposite of the mission. Consequences form a visible, recoverable ladder:

**Stage 1 — lifestyle drops (the main consequence, environmental not numerical).** Skipped bills and overspending *show*: the fridge empties, the phone screen cracks, the character's room dims, wardrobe options shrink. Kids read environmental storytelling instantly; it stings exactly enough; recovery is always one good week away.

**Stage 2 — the wellbeing meter dips.** Neglect (bad food, no fun spending, overworking gigs) lowers an energy/happiness meter, which reduces work performance and therefore income — a gentle spiral teaching "money problems compound" without saying it. Framed as **tiredness/energy, never sickness** (see Discarded Ideas). Band C may go slightly further: a skipped insurance decision means a bigger repair bill later.

**Stage 3 — the debt path, with a floor.** Continued failure triggers a bank loan offer — deliberately, because experiencing interest working *against* you is among the most valuable lessons in the game. But before anything catastrophic, the mentor intervenes with a **"fresh start" plan**: a structured recovery arc (downsized lifestyle, a budget plan, week-by-week debt paydown) that is itself gameplay. Climbing out of debt must genuinely feel like a comeback story.

**Homelessness: never as a state; only as a near-miss, only in Band C.** An eviction warning letter is a legitimate, powerful wake-up event for 14+, but the game always intercepts before the fall (the mentor's couch, the emergency plan). Bands A/B never see the concept.

**Every failure gets a diagnosis.** Each recovery arc opens with the mentor showing a simple picture of *why* it happened ("these three purchases, plus no buffer when the phone broke"). Consequence without diagnosis is punishment; consequence with diagnosis is education.

---

## 11. Learning Design

**Layer 1 — the simulation teaches (primary).** Consequences are the curriculum. The player who skips insurance and then eats a shock learns insurance permanently. The design never lectures before the experience; the experience creates the question, then the game answers it.

**Layer 2 — knowledge gigs (the "freelancing" mechanic).** Side quests where answering money questions or solving small financial puzzles earns in-game cash, framed diegetically: "The bank is running a quiz night," "A neighbor pays you to explain interest to them." Knowledge literally becomes income — which is itself the meta-lesson. Gig difficulty and payout scale with the player's in-game skill level, reinforcing the core skill→income loop.

**Layer 3 — in-game courses as the skill system.** Since skills drive salary, gaining a skill *is* a 90-second interactive micro-lesson at the school building. The game mechanic and the pedagogy are the same object. Leveling the "financial literacy" skill means actually doing financial-literacy lessons.

**Layer 4 — the mentor and reflection.** Post-consequence reflective questioning (established learning science: reflection is where transfer to real life happens), diagnosis after failure, celebration after milestones.

**Anti-pattern, banned: quizzes as gates** ("answer to continue"). That is homework in a game costume and the reason Camp 1 competitors are boring. All knowledge content is opt-in and paid (in-game).

**Pedagogy validation (pre-development task):** learning goals per band must be sanity-checked with educators or a financial-literacy curriculum body — in the Netherlands, Nibud / Wijzer in geldzaken; EU/OECD financial-literacy competence frameworks more broadly. This also unlocks the school channel later, since schools buy curriculum-endorsed tools.

---

## 12. Events and Shocks

**Fixed slots, unpredictable content.** Shocks never interrupt missions and never ambush mid-play (see Discarded Ideas). They arrive only in two ritual slots: the **evening event card** and **payday**. Content is unpredictable; timing is ritual. The player internalizes "every evening, something might happen — am I prepared?", which is the emergency-fund lesson embodied as rhythm.

**Frequency:** roughly one shock per 2–3 in-game days, mixed with **positive events** (a bonus, a gift, a discount, a windfall with a save-or-spend choice) so the event slot is anticipated, not dreaded.

**Structure of a shock card:** the situation, a visible cost, and 2–3 choices with price tags (repair now / cheap temporary fix / ignore and risk worse). Ignored problems return worse in a later evening slot — deferred problems compound, felt rather than told.

**The catalog is age-rated.** Every event carries a band rating. Band A: broken bicycle, lost lunchbox. Band B: broken phone, sick pet, expensive hobby. Band C: job loss, market dip, inflation, rent increase, eviction warning. **"War" as a shock event is explicitly cut** (see Discarded Ideas) — job loss, breakage, and inflation deliver the same lesson without the emotional and store-review risk.

**The weekly community challenge** (see Social) is a special globally-shared event: every player worldwide faces the identical scenario that week.

---

## 13. Screens and UX

### The hard law: one decision per screen

Complexity lives in the simulation, never in the interface. The interface reveals exactly one slice of the model at a time, and how big that slice is scales with the age band.

### Screen map

**City diorama (hub).** The only "dense" screen, and dense in a kid-friendly way: big pictorial landmarks with notification badges, not text or numbers. Everything else is one tap deep.

**Building screens.** Slide up over the city; closing returns to it. Workplace (shift button, promotion track), Bank (balance, savings jar/account, later loans and investments), School (class catalog as cards), Shop (purchase cards with visible prices), Home (decorating, rest), Notice Board (gig cards).

**Cards everywhere else.** One question, two or three big buttons, one number that matters. Shock cards, gig results, purchase confirmations, promotion letters.

**Result card** after every shift/gig: earnings, coin animation into the wallet, optional one-line skill tick. Fast, satisfying, done.

**Evening summary:** three lines with icons — earned ↑, spent ↓, wallet = . Never a spreadsheet.

**Payday screen:** Band A sees a jar filling; Band B a simple weekly picture; Band C a real statement — because learning to read one is, by then, the point.

### Interaction rules

Minimum ~64px touch targets. Icons + numbers over sentences everywhere. Optional voiceover for Band A (many players can't yet read fluently). No persistent HUD clutter: the wallet balance is the single always-visible number (top corner), and even it hides during story moments. Sessions end at natural stopping points — the day closes, the summary is read, done.

---

## 14. Social Layer

### The insight and the constraint

Kids play what their friends play; the currency is comparable, talkable status ("what level are you," "I got the rare one") — the Roblox engine. But open social features and a children's product are nearly incompatible: friend discovery, free chat, and UGC for minors mean heavy COPPA/GDPR-K consent flows, store-policy restrictions, moderation staffing, and predator-risk liability. We do not compete there. What kids actually need is *comparability and talkability*, both achievable with zero contact between strangers.

### The features (phased)

**Phase 1 — shareable artifacts (launch).** An auto-generated "My City" card / "Life Report": character, city snapshot, net worth, professions mastered, chapters survived — exported as an image the kid shows across the lunch table or sends through channels the family already uses. Comparison happens in real life, where it is safest and where it was going to happen anyway.

**Phase 2 — the weekly community challenge (early; it's cheap).** The Wordle mechanic: every player worldwide gets the identical scenario each week ("everyone's fridge breaks on day 2 — who ends the week richest?"). Shared context makes the game *discussable at school* — "did you do fridge week? I took the loan, huge mistake" — and the game never connected any two children to create it. Anonymous aggregate results only ("you did better than most players this week").

**Phase 3 — friend codes, not friend discovery (v1.x).** Kids who already know each other exchange a short code in person (the Nintendo model). Afterward they see each other's city snapshots and stats and can visit towns in read-only mode. No chat, no messaging, no strangers, parental toggle required for Bands A/B. Passes store review.

**Phase 4 — classroom leagues (with the B2B channel).** Teacher-managed class leaderboards: full competitive social inside an already-supervised group — the safest possible social graph and a selling point to schools.

### Why kids will play (the honest answer)

Because their life in the game is growing and visibly theirs (the nurture loop — the same psychological engine as Tamagotchi, Animal Crossing, and half of Roblox's hits); because there's a story with a deadline (chapters); because everyone at school faced the same fridge-week and they want to compare notes (shared challenge); and because their best friend's city has a car and theirs doesn't yet (friend codes). Four overlapping reasons to open the app — none requiring an ad, a loot box, or a stranger.

---

## 15. Guardian (Parent) System

The parent's email is already required for the consent flow, so the parent channel costs nothing extra to establish — and it is the core value proposition to the person who pays.

### Setup flow

Parent receives the consent request (COPPA/GDPR-K verified parental consent), confirms the child's age band, sets toggles (friend codes on/off for Bands A/B, email preferences), and gets the dashboard. Child accounts get enforced-fictional display names.

### The email channel (three tiers)

**Weekly digest (default on).** Sent after each in-game payday: what the child learned this week, milestones, and one dinner-table conversation starter ("Milan's character just took his first loan — ask him whether the interest was worth it!"). Makes the subscription feel worth paying for every single week. Delivered by email, with **WhatsApp as an opt-in alternative channel** — Dutch parents live in WhatsApp, and the field evidence from Oh Bear!'s Caribbean pilots (71% parent activation over WhatsApp vs. a 23% school-email benchmark, self-reported) suggests channel choice may be the single biggest lever on parent engagement. GDPR requirements (consent, EU processing, WhatsApp Business API terms) must be cleared before this channel ships. All parent communications are **signed in-character by the mentor** — the "postcard from Aunt Vera" — which keeps the coach-not-informant tone and matches what the child is told in-game.

**Teachable-moment alerts (opt-in).** Triggered by meaningful struggles — first debt spiral, failed chapter, ignored bills. A supportive one-pager: what happened in the game, the real-world concept behind it, two questions to ask your kid, one 5-minute activity to do together. The product equips the parent, who usually feels underequipped for money conversations.

**Milestone celebrations.** First profession mastered, first successful emergency fund. Parents forward these to grandparents — organic marketing.

### Guardrails

**Coach, never informant.** Tone is "here's what Milan is learning," never "here's what Milan did wrong." **Transparent to the kid:** the mentor tells the player "your grown-up gets a postcard about your week" — kids accept a known postcard and resent a hidden report. **Alerts never shame:** a kid whose parent got angry about an in-game mistake stops taking in-game risks, and risk-taking in the sandbox is the entire point of the sandbox.

### The parent dashboard (subscription feature)

Progress overview, concepts learned, conversation starters, settings. Parents pay for *insight*, never for in-game advantage.

---

## 16. Data and Privacy

**Principle: collect the absolute minimum and market that fact.** The game generates better personalization data than any signup form ever could — which profession the player chooses, purchase patterns, risk appetite, save-vs-splurge behavior — and it stays inside the game where it belongs. Personalize from behavior, never from PII.

**The complete collection list:** age *band* (never date of birth), country/region (coarse, for currency and localization — never GPS), and one parent email (consent + recovery). That is the entire list.

**Explicitly not collected:** real names (enforced), hobbies, friends' identities, precise location, birth dates, third-party analytics identifiers.

**Regulatory frame:** COPPA (US) and GDPR-K (EU — the company is Netherlands-based, so this applies from day one) require verified parental consent for under-13/under-16 data collection; every collected field is liability and audit surface. Apple's Kids Category restricts third-party analytics and data practices; Google Play Families is similar — violations mean removal from the store, so **store policies are a design constraint to be read before building accounts, purchases, and outbound links, not a retrofit.**

Backend implications: minimal-data schema, parental consent flows, no third-party trackers, EU data residency.

---

## 17. Monetization

**No ads, ever.** Ethically cleaner, practically necessary (advertising to children is heavily restricted; ad-stuffing is the genre's top complaint), and strategically aligned (the parent is the buyer).

**The absolute rule: never sell in-game money or advantage.** Whatever is sold must never touch the economic simulation. A financial-responsibility game where a parent's card buys your way out of in-game debt teaches the exact opposite of its mission and would be — rightly — crucified by parents and reviewers.

**Revenue streams, in order of priority:**

**1. Family subscription (B2C core, launch).** Free tier: the first age band or first chapters fully playable — genuinely fun, not crippled. Family subscription (~€4–7/month, all kids in the household): full progression, all professions, monthly chapters, the parent dashboard and email channel. Greenlight and Acorns Early prove parents pay ~$5/month per child for financial education; our family-wide price undercuts per-child pricing.

**2. School/institution licensing (B2B, year 1–2).** Teacher dashboard + classroom mode + class leagues on the same engine. 21 US states mandate personal finance for graduation; European equivalents growing; schools actively search for curriculum-endorsed tools. Lumpier revenue, much larger per deal. Architecture must keep classroom mode cheap to add. Two patterns adopted from the institutional-programme field: **classroom join-codes instead of student accounts** (teacher-approved entry, zero student PII — the COPPA/GDPR-K-friendly pattern), and an **institutional documentation pack** prepared before the first procurement conversation: safeguarding and child-protection policy, data-protection impact assessment, independent evaluation design, theory of change. That stack is the entry ticket to school and ministry deals.

**3. Bank/credit-union sponsorship or white-label (year 2+, business development).** Financial institutions already fund literacy tools (Bank of America runs a school simulation; credit unions publish game roundups) as CSR and future-customer pipeline. A bank paying to distribute the game to customers' children is high-margin, zero-ad revenue. Guardrail: sponsor branding, never sponsor influence over content.

**4. Cosmetics only, kept small.** Avatar outfits, room decorations, pet skins — purchasable with real money *or earnable with in-game money* (earning them in-game reinforces the lesson; a parent buying one is a tip jar). Apple's kids rules constrain IAP flows; this stream stays minor by design.

---

## 18. Technical Architecture

### Client: Godot Engine, GDScript

**Decision: Godot** (open source, no revenue cut, lightweight, excellent 2D) with **GDScript** as the primary language. The game is architecturally a 2D hub-and-card UI experience — exactly Godot's sweet spot.

**The deciding factor is the development workflow.** Development will be driven through **Claude Code** on macOS, which operates by reading/writing repository files and running terminal commands. Godot is built around that model: scripts (`.gd`), scenes (`.tscn`), and project config (`project.godot`) are all human-readable text files, so the AI-assisted workflow can create scenes, wire nodes, write logic, edit configuration, and run headless builds/exports (`godot --headless --export-release ...`) end to end. GDScript is chosen over Godot's C# variant for the tightest loop with Claude Code — concise, well-represented in training data, seamlessly integrated with the scene system — though C# remains available if ever needed.

**Cross-platform targets:** iOS (iPhone + iPad) and Android (phones + tablets) from one codebase. A Mac is available; Xcode is required for final iOS build/signing (any-engine requirement, not Godot-specific). Apple Developer account $99/year; Google Play one-time $25.

### Backend: Python / Django

Django (with Django REST Framework) serves the server side. The split is deliberately thin-server:

**Server-side:** accounts and the parental-consent flow; parent dashboard and the email channel (digests, alerts, milestones); weekly challenge definitions and anonymous aggregate results; chapter/content delivery (new chapters ship monthly without app updates); subscription state; friend-code linking and read-only city snapshots; later, the school/teacher layer.

**Client-side:** the entire economic simulation runs on-device. Rationale: offline play (kids don't have reliable connectivity), no latency in the core loop, and radical data minimization — gameplay detail stays on the device; the server sees only what its features strictly need.

**Client↔server:** Godot's `HTTPRequest` against DRF endpoints; WebSockets available later if any live feature needs it. EU-hosted (data residency), minimal-data schema, no third-party trackers.

### Development approach

Claude Code drives both sides (Godot client + Django backend) in the same repository/workflow. Pipeline: Godot headless exports for Android; iOS export → Xcode for signing. Persistent game state on-device with an encrypted local save; server sync limited to the minimal profile.

---

## 19. Localization Strategy

Money systems are national: Dutch kids should meet euros, iDEAL-style payments, and Dutch tax intuitions; American kids need credit scores and checking accounts. **Decision: v1 does one market deeply** (Netherlands or one English-speaking market — to be finalized) rather than a generic "nowhere-land" economy, because the generic economy teaches weaker lessons. The simulation data model must be built localization-ready from day one (currency, institutions, price levels, and event catalogs as data, not code), since retrofitting this is expensive. This is a pre-code decision because it shapes the data model.

---

## 20. Content Pipeline (Production Reality)

The chapter loop and the weekly challenge create a **permanent content obligation**: chapters ship monthly (they justify the subscription), weekly challenges ship weekly (they drive the social conversation), and the shock catalog grows continuously with age-band ratings on every card. This is a real recurring production cost — writing, localization, pedagogy review — and must be planned as an operating expense, not a launch task. The Django content-delivery path exists precisely so this content ships without app-store review cycles.

---

## 21. Discarded Ideas — and Why

A record of every path considered and rejected, so future contributors don't relitigate them without new information.

**Advertising (any form).** Rejected. Top complaint against every genre incumbent; heavily restricted for child audiences anyway; incompatible with the parent-pays trust position. Also rejected: "rewarded ads" — they monetize attention exactly the way we're teaching kids not to sell it.

**Selling in-game currency, boosts, or progress.** Rejected as a mission contradiction: a financial-responsibility game must never let real money bypass in-game consequences. Cosmetics-only is the permitted exception, kept deliberately small.

**Open social: chat, friend discovery, user-generated content.** Rejected. Predator-risk liability, moderation staffing, COPPA/GDPR-K complexity, and Kids Category store restrictions. Replaced by share cards, friend codes (known-in-person only), the weekly shared challenge, and later teacher-managed classroom leagues — which deliver the comparability and talkability kids actually want with zero stranger contact.

**Collecting profile data for personalization (hobbies, friends, date of birth, precise location).** Rejected and inverted into a selling point. Each field is legal liability and parental distrust; the game's own behavioral signals personalize better than any form. Collection list is frozen at: age band, coarse region, one parent email.

**Homelessness as a reachable game state.** Rejected for all bands: cruel for the audience and pedagogically useless once stuck. Replaced by the near-miss (eviction *warning*, Band C only) with guaranteed interception and a recovery arc.

**Sickness as a failure consequence.** Rejected: emotionally heavy for young kids, app-review risk. Replaced by the tiredness/energy framing, which delivers the identical "neglect compounds" lesson safely.

**"War" as a sudden-expense event.** Rejected from the shock catalog despite appearing in the original concept: unnecessary emotional weight and store-review risk for a kids' product; job loss, breakage, and inflation teach the same lesson.

**Random mid-play shock ambushes.** Rejected: frustrates kids and muddies the lesson. Replaced by fixed event slots (evening card, payday) with unpredictable content — ritual timing, surprising substance.

**Big purchases as pure trophies (houses/cars as cosmetics).** Rejected: if the better house or car only looks nicer, money becomes decoration and the game teaches lifestyle spending as the goal. Replaced by the Purpose Economy rule — major assets must change capability and carry upkeep; pure status items exist but are honest about advancing nothing.

**A generic XP bar / levels.** Rejected as the lazy default that teaches nothing. Replaced by four attributable channels (skill stars, promotions, chapters, mode graduation) landing only at ritual moments.

**Quizzes as gates ("answer to continue").** Rejected: homework in a game costume, the reason Camp 1 competitors are boring. All knowledge content is opt-in and paid (in-game) via knowledge gigs and courses.

**Real-time or grindy workdays.** Rejected (nobody stares at an 8-hour office shift). Replaced by the 3-slot day with one-tap/mini-game shifts.

**Unlimited day-skipping / binge time.** Rejected in favor of one-real-day-=-one-game-day: appointment retention, genuine weekly payday ritual, saving that feels like waiting, parent-friendly session caps. Eager players get more depth per day, not more days.

**Addiction-driven retention mechanics (streak pressure, FOMO timers, loot boxes).** Rejected ethically and strategically: the parent is the customer, and "respects my kid's time" retains subscriptions while "can't put it down" cancels them.

**Scrollable open-world city map (the full Forza model).** Rejected: navigation isn't the game and open maps overwhelm small screens and young kids. Kept the good part (notification pins/badges) on a single-screen diorama hub.

**One adaptive UI instead of three presentation layers.** Rejected: a single interface that "adjusts" satisfies no band. One simulation engine, three deliberate presentation layers, mastery-based graduation between them.

**Unity as the engine.** Rejected *for this workflow*, not on general quality: too much essential Unity work lives in the editor GUI (prefab wiring, Inspector references) stored as fragile YAML/GUID files impractical for a file-and-terminal AI workflow; licensing/revenue-share also noted. Godot's all-text project format lets Claude Code drive nearly the whole job.

**Unreal Engine.** Rejected: heavy 3D engine; wrong scale for a 2D hub-and-card mobile game.

**Flutter / React Native.** Rejected: app frameworks, not game engines; viable only for the simplest casual games and would fight us on animation, scenes, and game feel.

**Native dual codebase (Swift + Kotlin).** Rejected: building and maintaining the game twice defeats the single-codebase goal.

**Fictional "nowhere-land" economy for v1.** Rejected (weaker teaching); v1 goes deep on one real market, with the data model localization-ready from day one.

---

## 22. Risks and Open Questions

**The fun test — the single biggest risk.** Every failed competitor failed here. Gate: before real development, build a disposable web prototype of the core loop (~a week with Claude Code) and put it in front of 5–10 kids in the target band. The only metric: do they ask to keep playing when the session ends? If the skill→income→spend/save→shock loop isn't compelling with placeholder art, no polish will save it.

**Pedagogy validation.** Learning goals per band reviewed by educators / a curriculum body (Nibud, Wijzer in geldzaken, OECD frameworks). Also unlocks the school channel.

**Store compliance as design input.** Apple Kids Category and Google Play Families policies read *before* designing accounts, purchases, and outbound links.

**Name and trademark.** "Townling" passed web-level conflict screening (one defunct iOS game once used the word; no company, store presence, or mark found). townling.app and townling.nl verified available — register now; townling.com is held with no visible business (WHOIS + backorder). Remaining: EUIPO/TMview and BOIP searches in Nice classes 9, 41, 28; exact-name app-store checks; formal trademark-attorney clearance (flag the defunct app) and EU filing.

**Content-pipeline sustainability.** Monthly chapters and weekly challenges are a permanent operating cost; staffing/authoring plan required before launch commits to the cadence.

**Open decisions:** launch market (NL vs. English-speaking); launch band (recommend Band B, "First Salary" — the concept's heart, readers but not yet cynics, clearest parent value); exact price point; mentor character design; whether Band A ships at launch or fast-follows.

---

## 23. MVP Scope and Roadmap

**Phase 0 — validation (now).** Fun-test web prototype; pedagogy review; store-policy read; trademark search; launch-market decision.

**Phase 1 — MVP (Band B only).** City diorama with six buildings; 3-slot day loop; 4–6 professions with the skills/experience two-track; jobs + gig board + knowledge gigs; bank with savings; shock catalog (~30 age-rated cards); evening/payday rituals; consequence ladder stages 1–2; mentor; dream selection + first dream arc; capability assets with upkeep (bike, laptop); 3 launch chapters; share card; parent consent flow + weekly digest; free tier + family subscription. Client-side simulation; thin Django backend (accounts, consent, content delivery, digest emails).

**Phase 2 — retention and social.** Weekly community challenge; teachable-moment alerts + parent dashboard; monthly chapter cadence begins; consequence stage 3 (debt + fresh-start arc); town projects (giving); cosmetics.

**Phase 3 — expansion.** Friend codes and read-only city visits; Band C ("Real Life") with investing, credit, insurance, business path; Band A ("My Little Shop"); second market localization.

**Phase 4 — B2B.** Classroom mode with join-codes (no student accounts), teacher dashboard, class leagues; curriculum-body endorsement; institutional documentation pack (safeguarding policy, DPIA, evaluation design, theory of change); bank-sponsorship business development.

---

## 24. Summary

One engine, three ages, one city. Salary anchors, gigs excite, skills raise the ceiling, showing up raises the position. Shocks arrive on ritual, failure tells a story, the mentor turns every stumble into a lesson, and the parent gets a postcard — never a report. No ads, no sold advantage, almost no data. Kids come back because their life is growing on that one screen, the chapter deadline is ticking, everyone at school did fridge-week, and a dotted-outline dream on the diorama is waiting to be made real. Money in Townling buys what it buys in life — survival, security, capability, growth, identity, generosity — and the horizon is freedom. Built in Godot by way of Claude Code, backed by a thin Django server, shipped first to one market done properly.
