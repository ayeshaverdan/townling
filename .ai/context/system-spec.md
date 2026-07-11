# Townling — Game Systems Specification
*Companion to the Townling Design Document. In-game, "Townling" is both the town's name and what its little citizens are called — the player's character is a Townling. Where the design doc says what and why, this document says exactly how: flows, formulas, numbers, and content tables. Scope: the launch experience (Band B, "First Salary," ages 10–13), which is the MVP per the roadmap. All numbers are launch-tuning defaults, stored as data (JSON), not code — both for playtest tuning and per the localization strategy. Currency shown as € for the Dutch launch market; the symbol and price levels are localization variables.*

**Version:** 1.0 · **Date:** July 2026

---

## 1. The Player Journey — Phases and Milestones

The player's whole arc through Band B, before any daily detail:

| Phase | Real time | What it's about | Exit milestones |
|---|---|---|---|
| **1. Getting Started** | Days 1–7 | Tutorial week: learn the town, earn first money, feel first costs | First shift · first gig · first class · first payday survived |
| **2. Finding Your Path** | Weeks 2–4 | Pick a profession track, discover the skill ladder | First profession job · first promotion (Senior) · first shock survived with savings · €100 saved (Chapter 1 complete) |
| **3. Building Skills** | Months 2–3 | Climb the ladder, buy capability, meet investing | Expert rank · first capability asset owned (bike/laptop) · Growth Jar opened · dream ≥50% funded |
| **4. Ownership** | Month 3+ | Mastery and the first taste of business | Master rank · business trial completed (market-stall capstone) · Dream #1 built · Band C graduation unlocked |

Every milestone above fires three things: a diorama change (visible progress), a mentor moment (reflection), and — where meaningful — a parent email (digest/milestone tier).

---

## 2. The First Session, Minute by Minute

Day 1 is scripted tightly because it must produce the loop's full emotional cycle — earn, spend, feel — inside ten minutes.

**Minute 0–2 · Arrival.** Create avatar (visual only; enforced-fictional name). The mentor (Aunt Vera, a retired banker with a parrot) welcomes the player to Townling, hands over the starter wallet (**€50**) and the key to a small rented room. One-line premise: "Your life here is yours to build."

**Minute 2–3 · The dream.** Player picks a dream from six illustrated cards (see §12). It appears on the diorama as a dotted outline. Price tag visible (e.g., Treehouse — €600). This is the pull installed before any grind exists.

**Minute 3–5 · First earnings.** The city appears with one badge bouncing: the Courier depot. Player taps → takes the always-open Courier job → plays the 45-second delivery mini-game (swipe the route) → result card: **+€24 (shift) +€4 (mini-game tip)**. Coins fly into the wallet. First slot consumed.

**Minute 5–7 · First costs.** The Shop badge lights. Groceries must be bought (mentor explains the fridge). Three cards: Cheap €20 / Normal €30 / Fancy €50, with visible wellbeing effects. Whatever they pick, the follow-through happens at the evening summary. Second slot consumed.

**Minute 7–9 · Evening.** Third slot auto-suggests Rest (introduces the energy refill). Evening summary shows the three-line picture: earned ↑ €28, spent ↓ €30, wallet = €48. The event card tonight is scripted and positive (a neighbor waves; +€5 found coin) — night one never punishes.

**Minute 9–10 · Close.** Mentor: "Rent is €60, due at payday — six days. Sleep well." Day ends. Tomorrow's hooks are planted: the Notice Board and School badges will be waiting. Session over at a natural stop.

Days 2–7 unlock one system per day: gigs (day 2), classes (day 3, first Money Skills class free), the Bank and savings jar (day 4), the locked-job-postings view (day 5 — the ladder made visible), free-play (day 6), and the first **payday ritual** (day 7): salary in, rent and bills out, the week's picture, mentor reflection, Chapter 1 begins ("The Festival" — save €100 for the town festival by day 21).

---

## 3. The Daily Interaction Model

**A day = 3 energy slots.** Every meaningful action costs exactly one slot: a work shift, a gig, a class, a shopping trip, or rest. Micro-actions (checking the bank, reading a letter, decorating, admiring the diorama) are free.

**Flow of one slot:** City diorama → tap a badged building → building sheet slides up → one action card (one decision, 1–3 buttons) → optional 30–60s mini-game → result card (+/- money animation, skill/XP ticks) → back to the diorama. Depth never exceeds one level below the city.

**When slots hit 0**, dusk falls on the diorama; the only tap left is the Evening Summary → event card → day closes. If the player doesn't open the app, autopilot runs the day safely (attends work, pays bills, buys normal groceries, buys nothing else) and the return recap shows what happened.

**Shift mini-games** (optional — a "Just Work" button always exists and pays the standard rate; playing the mini-game well earns a +10–20% tip):

| Profession | Mini-game (30–60s) |
|---|---|
| Courier | Swipe the fastest route through the town grid |
| Baker | Timing-taps: pull loaves at the perfect moment |
| Builder | Drag-and-drop: place blocks to match the blueprint |
| Teacher | Match the right answer card to each student's question |
| Vet Assistant | Rhythm-soothe: tap in time to calm the animal |
| Coder | Order the logic blocks to make the little robot walk |
| Shopkeeper | Serve the queue: total up prices, give correct change |

Mini-games are also quiet skill practice: each themed on its profession's real micro-skill (change-making at the shop is literal arithmetic practice).

---

## 4. The Skills System

Eight skills at launch. Each runs 0–5 stars. Stars are visible on the player card and on job postings (the gate is always shown, never hidden).

**Craft skills** (each is one profession's primary): Baking · Building · Animal Care · Coding · Teaching · Selling.

**Life skills** (cross-cutting): **Communication** (adds +2% salary per star to *every* job — the transferable-skill lesson) and **Money Skills** (raises knowledge-gig payouts +20%/star and gates bank features: savings jar needs ★1, Growth Jar needs ★2).

### Earning stars

Progress is measured in **lessons**. A star requires as many lessons as its own number (star 1 = 1 lesson, star 2 = 2 more, star 3 = 3 more…) — cumulative 1/3/6/10/15 lessons to reach ★1–★5.

Two sources of lessons:

**Classes** at the School — one slot + a fee, delivering a 90-second interactive micro-lesson (the pedagogy layer). Craft classes cost **€15** (Coding **€25** — pricier tools, higher ceiling: a deliberate lesson about education as investment). Communication classes **€15**. **Money Skills classes are free** — the Bank sponsors them, diegetically and by design: financial literacy must never be paywalled in this game.

**Practice** — every 5 shifts at a job convert to 1 lesson in that job's primary skill, automatically. Working slowly teaches; school teaches faster. Both paths are shown to the player, priced, and left as a genuine choice.

---

## 5. Professions, Jobs, and How Jobs Appear

### The job board (Notice Board, "Jobs" tab)

Job postings refresh every payday. Rules: there is **always at least one posting the player currently qualifies for** (no dead ends), and postings above the player's level are shown **locked with their requirements visible** — e.g., "Senior Baker — requires Baking ★2 + Junior experience." The visible locked ladder is the aspiration engine: the player always knows exactly what the next rung costs. Taking a job is one tap + a short "first day" scene. Promotion offers don't appear on the board — they arrive as **letters at the player's mailbox** on payday when thresholds are met (a ritual moment, per the design doc).

### Ranks and experience

Every profession has four ranks: **Junior → Senior → Expert → Master.** Shifts grant **10 XP** each. Rank-up requires XP + a skill gate + (for Master) the profession's capstone chapter:

| Rank | XP required | Primary-skill gate |
|---|---|---|
| Junior | 0 | ★1 |
| Senior | 100 (≈2 weeks of shifts) | ★2 |
| Expert | 300 | ★3 |
| Master | 600 + capstone chapter | ★4 |

Switching professions: skills keep their stars (transferability), XP resets to 0 in the new track — the felt cost of changing fields, exactly as designed.

### Launch professions (6 tracks + entry tier)

**Entry tier — always open, no gate:** Courier (€120/wk), Dishwasher (€110/wk). These exist so earning is never locked, and they grant no track XP beyond themselves — the nudge toward choosing a path.

**Tracks:** Baker · Builder · Teacher · Vet · Coder · Shopkeeper. Teacher uniquely requires two skills (Teaching + Communication ★ at each gate level) and pays a premium for it — the multi-skill-premium lesson. Shopkeeper's Master rank is the natural on-ramp to the Business path (Phase 4 / Band C). Vet starts as Vet Assistant and re-titles to Vet at Expert.

---

## 6. The Salary Model

### The formula

**Weekly salary = RankBase × (1 + 0.10 × BonusStars) × (1 + 0.02 × CommunicationStars)**

Where **BonusStars** = the player's primary-skill stars *above* the rank's gate (capped at +5 → max +50%), and Communication adds its small universal bonus (max +10%). Salary is paid at payday and assumes attended shifts (autopilot attends; deliberately skipping ≥3 shifts in a week triggers a warning letter, and a second such week triggers the "Let Go" event — see §10).

**This is the skill→income loop made mechanical:** study beyond your rank's requirement and your *current* salary rises immediately (+10% per star), *and* you're pre-qualified for the next promotion letter. Skill raises the ceiling and the floor at once — the player feels a class pay for itself within weeks.

### Rank base table (€/week, launch defaults)

| Track | Junior | Senior | Expert | Master | Class cost | Flavor |
|---|---|---|---|---|---|---|
| Courier (entry) | 120 | — | — | — | — | Always open |
| Dishwasher (entry) | 110 | — | — | — | — | Always open |
| Baker | 150 | 210 | 300 | 400 | €15 | Unlocks bakery-stall business trial |
| Builder | 160 | 220 | 310 | 430 | €15 | Physical: shifts −5 extra wellbeing |
| Vet | 150 | 215 | 305 | 420 | €15 | Animal shock events soften at ★3 |
| Shopkeeper | 140 | 200 | 280 | 380 | €15 | Master = Business path on-ramp |
| Teacher | 160 | 230 | 330 | 440 | €15 ×2 skills | Requires Teaching + Communication |
| Coder | 170 | 240 | 340 | 480 | €25 | Highest ceiling, priciest education |

**Worked example (the loop in numbers).** Week 2: Junior Baker at gate (★1) earns €150. She spends two slots and €30 on two Baking classes → ★2 (1+2 lessons banked from practice). Same rank, next payday: €150 × 1.10 = **€165** — the classes repaid themselves in two paydays. At 100 XP the Senior letter arrives (she already qualifies): **€210**, and her spare star now reads as bonus again pending ★3. Every number on that path is visible to the player in advance on the locked postings.

---

## 7. The Gig System

Gigs live on the Notice Board's "Gigs" tab: 1–3 fresh offers per day, each costing one slot, paid instantly.

**Payout formula: GigBase × (1 + 0.20 × RelevantSkillStars).**

| Gig type | Base | Scales with | Notes |
|---|---|---|---|
| Dog walking | €12 | Animal Care | The classic starter |
| Errand run | €10 | — (flat) | Always available fallback |
| Bake-sale help | €15 | Baking | Track-flavored gigs rotate |
| Fix-it visit | €15 | Building | |
| Tutoring hour | €18 | Teaching | |
| Website tweak | €20 | Coding | Requires laptop owned |
| **Knowledge gig (quiz)** | €10–25 | **Money Skills** | The learning-is-earning mechanic: bank quiz night, "explain interest to Mr. Bos," puzzle cards |

**The balancing rule from the design doc, enforced by numbers:** with a daily cap of 3 offers averaging ~€16 base, a full gig-only week yields roughly €250–€330 at high skill — real money, but below a Senior salary *and* earning zero XP toward promotion. Salary compounds; hustle doesn't. The player discovers this truth in their own ledger, which is precisely the intent. Gigs' actual role: surplus on demand, skill practice (each gig grants a half-lesson in its skill), and the knowledge-quiz teaching channel.

---

## 8. Money Out — Living Costs, Assets, and Prices

### Weekly fixed costs (auto-deducted at payday)

Rent (starter room) **€60** · Phone **€10** · Transport pass **€10** (skippable if walking — but walking makes cross-town gigs cost 2 slots until a bike is owned). Groceries are bought manually at the Shop weekly: Cheap €20 (wellbeing −5/wk) / Normal €30 (0) / Fancy €50 (+5/wk). **Baseline burn: ~€110/week** against a €150 entry salary — the starting surplus is deliberately thin (~€40) so the first savings feel earned and the first shock without savings genuinely stings.

### Capability assets (the Purpose Economy, priced)

| Asset | Price | Capability effect | Upkeep |
|---|---|---|---|
| Bike | €80 | Cross-town gigs cost 1 slot; +1 gig offer/day | €2/wk (occasional €15 repair event) |
| Laptop | €200 | Unlocks Coding classes at home (no slot for travel) + Website gigs | — |
| Toolbox | €120 | Builder shift tip +10%; unlocks Fix-it gigs | — |
| Oven upgrade (home kitchen) | €250 | Unlocks weekend bake-stall (proto-business, €30–60/weekend) | €5/wk energy |
| Room upgrade (bigger flat) | €400 + rent €85/wk | Rest refills +30 instead of +20; +1 decoration slot visible on diorama | Higher fixed cost — the lifestyle-inflation choice, made honest |

Status items (decor, outfits, pet accessories): €5–€60, zero simulation effect, maximum diorama visibility — honest by design.

### The Bank

**Savings Jar** (needs Money Skills ★1): deposits any time, **+1%/week interest**, instant withdrawal. *Pedagogical compression:* rates are ~50× reality so compounding is visible within a child's attention span; the mentor explicitly says real banks are slower — the *shape* of the lesson is true, the speed is theatrical.
**Growth Jar** (needs Money Skills ★2 + Chapter 3): average **+2%/week but each week rolls −5% to +9%** — money that grows but can shrink, experienced weekly at payday. Withdrawal takes one full day (liquidity lesson, gently).

---

## 9. Wellbeing and Energy

One meter, 0–100, visible only as the character's expression and room ambience (numbers appear on tap). Daily drift −5. Rest slot +20 (upgraded room +30). Food choice ±5/week. Builder shifts −5 extra.

Effects: below 30, shift pay −20% and mini-games get harder (the money-problems-compound spiral, gentle); at 0 for two consecutive days, the mentor forces a scripted Rest Day (a caring floor, not a punishment). Above 80, mini-game tip chance +10% — thriving pays, mildly.

*v1.2 amendment (July 2026, playtest: "sleep should restore energy; rest made groceries pointless"):* the overnight model is **sleep quality**: the day wears you −10; a night's sleep restores **+8/+12/+16 by dinner tier** (fed = sustainable: normal dinner nets +2/day); a **hungry night is −15** (net −25 — crashes in ~3 days); the rest slot is **+15**, deliberately smaller than a hungry night so rest can top you up but can never replace eating (the earlier +20 rest made skipping groceries the dominant strategy — a real exploit found in play). The evening card states the night's math explicitly; the forced Rest Day card names the missed pay (≈ 3 shifts) out loud so the opportunity cost is felt, not implied.

*v1.1 amendment (July 2026, from the first kid playtest — "no dinner didn't seem to matter"):* the fun-test build makes the pay effect **tiered and visible** rather than a single hidden threshold: thriving 80+ = full pay **+ €4 good-mood tip** (deterministic stand-in for the mini-game tip bonus), fine 60–79 = 100%, tired 30–59 = 90%, exhausted <30 = 80%. The current shift pay is always shown on the Workplace action button before working, and the evening card states the overnight energy math (drift + dinner effect) explicitly. Rationale: consequences must be legible and felt within a day, not discovered after crossing an invisible line; deliberately tiers rather than a linear wellbeing×pay tax to keep cause-and-effect explainable and non-punishing.

---

## 10. Events — the Launch Shock Deck

Fired from the evening slot (~1 per 2–3 days, 60/40 negative/positive) and at payday. Every card: situation → 2–3 priced choices → consequence, some delayed. Fifteen launch cards (Band B rated):

| Card | Choices (price → effect) |
|---|---|
| Phone screen cracks | Repair €60 / Live with it (gig offers −1/day) / Replace €120 (new phone, +status) |
| Pet turtle sick (if pet owned) | Vet €45 / Home care (Animal Care ★2+, €10) / Wait (50% worsens → €90) |
| Bike flat (if bike) | Fix €15 / Walk this week (bike benefits paused) |
| Friend's birthday | Gift €20 (+wellbeing 5) / Card €3 / Skip (−wellbeing 3) |
| School trip announced | Pay €35 now / Miss it (−wellbeing 5) |
| Rain ruins shoes | Replace €25 / Dry them (10% repeat) |
| Fridge breaks *(weekly-challenge debut card)* | Repair €80 / Used one €50 (10% re-break) / Eat out 1wk (+€40 groceries) |
| Grandma visits | Free +wellbeing 10, +€10 pocket money |
| Tax refund (mini) | +€25, mentor explains why |
| Found gig rush | +1 slot today only |
| Shop sale | Fancy groceries at Normal price this week |
| Neighbor's praise | Communication half-lesson free |
| Lost wallet | −€15 cash (bank money safe — the *why banks* lesson, felt) |
| Power cut evening | Rest slot forced; family game night +wellbeing 8 |
| Street festival | Spend €10 (+wellbeing 6) or work the stall (+€20, Selling half-lesson) |

**"Let Go" (systemic, Band B's hardest):** triggered only by the second warning week of deliberately skipped shifts. Two-week severance at 50%, the board guarantees an entry posting, and the mentor opens the diagnosis + fresh-start arc. Getting refired into a better track is written as a comeback, per the consequence design.

---

## 11. Chapters 1–3 (Launch Content) and the Capstone

**Chapter 1 — The Festival (days ~7–21).** Goal: save €100 for the festival ticket by the deadline. Teaches: surplus, the savings jar, wants-vs-needs under a deadline. Failure → festival missed, "attempt 2" runs next month's festival; success → festival scene + permanent string-lights on the diorama.

**Chapter 2 — The Ladder (weeks 3–6).** Goal: earn a Senior promotion in any track. Teaches: the classes→stars→salary loop deliberately walked. Unlocks: capability assets shelf.

**Chapter 3 — The Rainy Month (weeks 6–10).** Goal: end a scripted heavy-shock month (three majors: fridge, phone, shoes) with wallet ≥ €0 and wellbeing ≥ 30. Teaches: the buffer as strategy; unlocks the Growth Jar. This chapter is the emergency-fund lesson as a boss fight.

**Master capstone (per track, Phase 4).** One weekend running a real micro-business — e.g., Baker: the market stall (buy stock, set prices, weather event, sell). Profit or small loss both complete it; the *decision experience* is the content. Completing any capstone = Master rank + the Business path badge + Band C graduation eligibility.

---

## 12. The Dream Catalog (launch six)

Treehouse €600 · Own puppy €450 (adds pet care costs after — told upfront) · Ocean trip €500 · Name-on-the-window bake stall €700 · Telescope + stargazing deck €550 · Skate ramp in the yard €650. Each funds in visible increments (the dotted outline fills), each completes as a permanent diorama build + share-card frame. Dream prices are tuned to ~8–14 weeks of realistic surplus — one school term, on purpose.

---

## 13. Economy Balancing Targets (for the fun-test and beyond)

Design intent expressed as playtest telemetry: median week-1 end wallet **€60–€90** (thin but positive); first promotion at **day 12–18**; first shock met *with* savings by **week 3** for ≥60% of players; gig income ≤ **40%** of a Phase-3 player's total (else salary isn't anchoring); dream #1 completion **week 8–14**; session length **5–10 min** median; day-1→day-7 retention target ≥ **45%** in the fun test (kids asking to continue counts more than any number).

Primary tuning levers, all data-side: RankBase table, class costs, gig frequency/base, shock frequency/costs, rent, interest rates. Nothing above requires code changes to rebalance — by architecture.

---

## 14. Live Content and Events Architecture — How Missions, Challenges, and Special Events Ship

The design promise (design doc §20): chapters monthly, challenges weekly, no app-store release cycle. This section specifies the machinery.

### 14.1 Two timelines, never confused

Every piece of live content belongs to exactly one timeline:

**The personal timeline** — content triggered by *the player's own progression*: chapters, promotion events, milestone unlocks, the shock deck. A player who starts in November gets Chapter 1 in November. Chapters queue in order per player; a monthly release grows the queue, it does not interrupt anyone.

**The world calendar** — content triggered by *the real-world clock, simultaneously for everyone*: the weekly community challenge, seasonal town events (the launch market's own calendar — King's Day, Sinterklaas, summer festival), and limited-time gigs. This is the shared-context layer that makes the game discussable at school.

### 14.2 Content is data, authored in a pipeline

All live content is JSON packages in a Git content repository — no game code. A package (event card, gig template, chapter, challenge) carries: `id`, `type`, `band_rating`, `locale`, `schema_version`, localized strings, prices/effects, and for chapters a scene script. The pipeline: author (writer + Claude Code assist) → **pedagogy checklist gate** (educator sign-off flag required for anything teaching a concept) → automated validation (schema, price bounds vs. economy config, band rating present) → staging channel (internal devices) → production publish. Economy tuning (§13's levers) travels the same road as a versioned `economy_config` package — rebalancing is a content release, not an app update.

### 14.3 Distribution: manifest + prefetch (offline-proof by design)

Django exposes one endpoint that matters: the **content manifest** — a signed, versioned index of packages with activation windows and audience filters (band, locale, minimum app version). On every session start (and at most once daily in background), the client fetches the manifest diff and **prefetches everything scheduled for the next 14 days**, caching locally. Activation is then driven by the *local clock against the downloaded schedule* — so a child offline for a week still gets the festival on the right day and the challenge on Monday. The manifest can also *revoke* a faulty package; clients fall back to last-known-good. Result: the server schedules, the client executes, and connectivity is never required on the day itself.

### 14.4 The weekly challenge: one seed, everyone's fridge

The Wordle mechanic is implemented with **deterministic shared scripting**. A challenge package contains: the scenario script (which scripted events fire on which challenge-days — "day 2: fridge breaks"), a **shared random seed** for any variable elements, a scoring rubric (e.g., end-of-week net worth + wellbeing floor), and the challenge window (Monday 00:00 to Sunday 23:59, *local time* — the school-week rhythm matters more than global simultaneity, and results are anonymous aggregates, so timezone skew is harmless). Every client runs the identical deterministic scenario inside the player's normal week — the challenge overlays the life, it doesn't replace it. At window close, the client submits a **minimal anonymous result packet** (challenge id, band, rubric metrics — no identity, per the data-minimization spec); Django aggregates and serves back distribution stats ("you kept more savings than most players this week"). Server-side sanity bounds reject impossible packets; that's sufficient anti-cheat while results are aggregate-only. Classroom leagues (Phase 4) reuse this exact machinery with a teacher-scoped aggregation key.

**Authoring cost control:** challenges are instances of ~12 rotating **archetypes** (Breakdown Week, Windfall Week, Double-Bills Week, Sale Season, Gig Drought…) — a new week is an archetype + new seed + fresh flavor text, roughly an hour of authoring plus review, not a bespoke design.

### 14.5 Trigger taxonomy (complete)

**Calendar triggers** (manifest windows): challenges, seasonal events, limited gigs. **Progression triggers** (client-local rules): chapter start/completion, promotions, graduation, dream milestones. **State triggers** (client-local watchdogs): mentor interventions (wellbeing floor, debt spiral, first surplus), autopilot recaps. **Remote-config triggers** (manifest): economy retuning, package revocation, feature flags. Push notifications are deliberately **excluded at launch** — a kids' product nudging kids is both a store-policy risk and a design-principle violation (appointment retention must come from the world, not from pings); the only future exception considered is a parent-controlled, parent-received notification.

### 14.6 Operational cadence

Weekly: next challenge published to staging Tuesday, production Thursday (4-day prefetch margin before its Monday start). Monthly: one chapter + 3–5 new shock/gig cards + any tuning package. Quarterly: one seasonal event per launch locale. This cadence is the content pipeline's operating expense made concrete (design doc §20) and is the minimum that keeps the world feeling alive.

---

## 15. What This Spec Deliberately Leaves Open

Band A and C numeric tables (same systems, different tuning — specced post-fun-test); mini-game detailed designs (one page each at build time); business-path full economy (Phase 4 doc); Band C systems (tax, credit, insurance, property market). The fun-test prototype needs only: §2 (day 1), §3 (the slot loop), Courier + Baker track, 5 gigs, 6 shock cards, and Chapter 1. That's the build list.
