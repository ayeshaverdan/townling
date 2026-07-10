# CLAUDE.md

Guidance for Claude Code when working in this repository.

## What this project is

You are working on **Townling**, a privacy-first, ad-free financial life-simulation game for children, in pre-development. The founder is a solo, experienced developer based in the Netherlands, building the game client in **Godot 4 (GDScript)** via **Claude Code** on macOS, with a **Python/Django** backend. Target platforms: iOS (iPhone + iPad) and Android (phones + tablets) from one codebase.

**The product in one sentence:** a genuinely fun, mobile-native, kid-safe life simulator where the money model underneath is realistic and the experience on top is easy to understand. Players pick a profession, build skills, earn income, pay for daily life, survive recoverable shocks, and learn banking and investing — because financial cause-and-effect IS the game engine, not a quiz wrapper.

**Name status:** "Townling" (coined: town + -ling, "a little citizen"; in-game it is both the town's name and what its citizens are called; the player's character is a Townling). Web-screened clean; townling.app and townling.nl were verified available in July 2026 (register if not yet done); townling.com is held by an unknown party (WHOIS/backorder pending). Still pending: EUIPO/TMview + BOIP searches (Nice classes 9, 41, 28), app-store exact-name checks, trademark-attorney clearance. Earlier names eliminated: MoneyTown (existing games + descriptive-name EU registrability problem), Savvyburg (pronunciation/spelling/search), Thrivo, Kaboodle, Earnling (domain/product conflicts).

## Source of truth

Two documents under [`.ai/context/`](.ai/context/) are authoritative, in this order. Read them before answering anything non-trivial — do not work from this summary alone:

1. **[.ai/context/design-document.md](.ai/context/design-document.md)** — the what and why: vision, market validation, principles, age bands, world, loops, economy design, purpose economy, progression, consequences, learning design, events, UX laws, social, guardian system, privacy, monetization, tech architecture, localization, content pipeline, discarded ideas (with reasons — do not relitigate these without new information), risks, roadmap. Cited below as "design doc §N".
2. **[.ai/context/system-spec.md](.ai/context/system-spec.md)** — the how, with numbers: player journey phases, first-session script, daily interaction model, skills, professions, the salary formula and tables, gigs, prices, bank, wellbeing, the launch shock deck, chapters 1–3, balancing targets, live content/events architecture. Cited below as "spec §N".

This file (`CLAUDE.md`) is a fast-orientation summary and behavior guide, **not** a source of truth — when it and the two documents disagree, the documents win. If a user request conflicts with the documents, flag the conflict, discuss, and update the documents rather than silently diverging. When a decision changes, record it (and why) in the relevant document so the docs remain the single source of truth.

## Non-negotiable product principles (guard these actively)

1. Fun first, lesson embedded — the simulation teaches; never lecture before the experience.
2. Failure is a story, never a wall — every bad state is recoverable and recovery is gameplay.
3. Privacy as a feature — total collection list: age band (never DOB), coarse region, one parent email. Nothing else. Ever.
4. Never sell advantage; no ads, ever — nothing purchasable may touch the economic simulation; cosmetics only.
5. Respect the kid's time — appointment retention (payday, chapters, weekly challenge), never addiction mechanics, no push notifications to children.
6. One decision per screen — complexity lives in the simulation, never the interface.
7. The kid is the player; the parent is the customer — serve both; the child always knows what the parent sees (mentor-signed "postcards").
8. Child safety overrides everything: enforced-fictional display names, no open social (no chat, no friend discovery, no UGC), friend codes only for kids who know each other in person, COPPA/GDPR-K compliance, Apple Kids Category + Google Play Families policies as design constraints.

## Core design facts (quick reference)

*Each bullet points to its authoritative section; follow the reference before acting on the detail.*

- **Age bands:** *(design doc §4)* Band A "My Little Shop" (6–9), Band B "First Salary" (10–13, the launch band), Band C "Real Life" (14+, works for adults). One simulation engine, three presentation layers; graduation between bands is mastery-based via capstone chapters.
- **World:** *(design doc §5, §13)* a single-screen city diorama hub, rendered as **low-poly 3D on a fixed isometric camera (2.5D)** — see the visual-direction update in design doc §18; buildings are big tappable landmarks (Home, Workplace, Bank, School, Shop, Notice Board; Band C adds investment floor + business district); notification badges on buildings ARE the UI; everything is one tap deep; the diorama shows all progress (assets, trophies, the dream as a dotted outline that fills as funded).
- **Loops:** *(design doc §6; spec §1–§3)* moment (1–3 min actions) → day (3 energy slots, evening summary + event card) → week (payday ritual = the teaching engine + parent digest) → chapter (story goals with deadlines, monthly content). Time: 1 real day = 1 in-game day; missed days run safe autopilot; no binge-skipping.
- **Economy:** *(design doc §7; spec §4–§7 for skills, professions, salary, gigs)* entry jobs always open (no dead ends); 6 launch professions (Baker, Builder, Teacher, Vet, Coder, Shopkeeper); skills (0–5 stars, via paid classes or slow work practice; Money Skills classes always free) gate jobs and raise salary; experience (10 XP/shift) gates promotions (Junior→Senior→Expert→Master). **Salary = RankBase × (1 + 0.10 × bonus skill stars) × (1 + 0.02 × Communication stars).** Gigs pay instantly, scale with skill, never out-earn salary long-term. Business is the earned second act, never a starting choice.
- **Purpose economy — money buys six things:** *(design doc §8; prices in spec §8)* survival (living costs ~€110/wk vs €150 entry salary), security (savings +1%/wk pedagogically compressed; Growth Jar ±), capability (assets with upkeep: bike, laptop, oven; houses/cars are mechanics with running costs, never trophies), growth (education, investing, business), identity (status items — honest: zero simulation effect), giving (fundable town projects). Emotional engine: the **dream** (chosen day 1, dotted outline on the diorama, ~8–14 weeks of surplus). Band C endgame: financial independence.
- **Consequences ladder:** *(design doc §10, §12; shock deck in spec §10)* lifestyle drops (visual) → wellbeing/energy dips (never "sickness") → debt with a mentor "fresh start" floor. Homelessness only ever a near-miss warning, Band C only. Every failure gets a mentor diagnosis. Shocks fire ONLY in fixed slots (evening card, payday) — ritual timing, surprising content; ~1 per 2–3 days, mixed with positive events; "war" events are cut.
- **Mentor:** *(design doc §5 "Characters", §15; spec §2)* Aunt Vera (retired banker with a parrot); appears after consequences, asks reflective questions, signs the parent communications in character.
- **Social (phased):** *(design doc §14; challenge machinery in spec §14.4)* share cards → weekly community challenge (identical deterministic scenario for all players, anonymous aggregate results — the "fridge week" school-conversation engine) → friend codes (in-person exchange, read-only town visits, no chat) → classroom leagues (B2B).
- **Guardian system:** *(design doc §15)* parent email required for consent anyway; weekly digest (email; WhatsApp opt-in channel planned, GDPR pending), teachable-moment alerts (opt-in), milestone mails. Coach tone, never informant; alerts never shame.
- **Monetization:** *(design doc §17)* free tier genuinely playable; family subscription ~€4–7/month (full progression + parent dashboard); school licensing later (classroom join-codes, no student accounts; institutional documentation pack required: safeguarding policy, DPIA, evaluation design, theory of change); bank sponsorship year-2+; small cosmetics.
- **Tech:** *(design doc §16, §18–§20; live-ops machinery in spec §14)* Godot 4 + GDScript client (all-text project format chosen specifically for the Claude Code workflow; Unity rejected for editor-GUI/YAML lock-in); client-side simulation (offline-first, data-minimal); thin Django/DRF server (accounts, consent, content manifest delivery, digest emails, challenge aggregation, subscriptions, snapshots). Live content ships as JSON packages via a signed manifest with 14-day client prefetch; weekly challenges are deterministic scripts + shared seed; ~12 rotating challenge archetypes; economy tuning is a content release, not an app update. All content data-driven and localization-ready; v1 = one market deep (NL or one English-speaking market — undecided).
- **Art direction:** *(design doc §18 visual-direction update, July 2026)* **low-poly 3D on a fixed isometric camera (2.5D)**, built from CC0 KayKit packs (*City Builder Bits*, *Adventurers*), superseding the earlier hand-illustrated-2D plan. The storybook *palette* and warmth carry over onto the 3D frame; saturation dials up for Band A, down toward Band C. Assets live in [game/assets/](game/assets/); source formats are pruned to glTF for Godot. **The character pack is a weapon-bearing medieval-fantasy placeholder** — must be replaced with a modern, profession-appropriate, weapon-free set before any art-judged playtest (child-safety + modern setting). Key palette (UI/tint): canvas #F7F6F2, meadow #CFE3C4, sky #CBE6EF, path #E4D2A8, bakery pink #F0A9A0/#D97A6E, bank blue #AEC3E8/#8AA3D6, school amber #EBC985/#CFA85A, notice-board purple #C9AEE4, coin gold #E7B24C, alert red #E24B4A, growth green #7FB77F, warm text browns #7A5410/#2C2C2A.

## Competitive context

*(Full treatment in design doc §2 "Market Validation Summary".)* Market camps: (1) classroom web sims — pedagogy without game feel; (2) entertainment life sims (BitLife etc.) — game feel without pedagogy or kid-safety, ad-riddled; (3) real-money kids fintech (Greenlight, Acorns Early) — proves parents pay ~$5/child/month, but no simulation; (4) institutionally-financed ministry programmes (Oh Bear!/FLITE in Guyana/Barbados: teacher-led curriculum, WhatsApp parent bot, ministry dashboard, DFI-funded) — validates the mission and the parent-channel insight, no product collision; it defines the B2B procurement bar. **Townling's protected differentiator: the skill→income feedback loop with realistic, recoverable shocks, kept kid-readable.** Failure patterns to never repeat: ads, boring quiz-wrappers, data harvesting.

## Current status and next milestones

*(Roadmap in design doc §23; risks/open decisions in design doc §22; fun-test build list in spec §15.)* Concept and systems design complete (both docs). **Phase 0 (now):** register townling.app/.nl; trademark verification; pedagogy review with an educator/curriculum body (NL: Nibud, Wijzer in geldzaken); read Apple Kids Category + Play Families policies; decide launch market; **build the fun-test prototype** (disposable web build of the core loop: day-1 script, slot loop, Courier + Baker, 5 gigs, 6 shock cards, Chapter 1 — spec §15 has the exact list) and test with 5–10 kids aged 10–13; the only metric that matters: do they ask to keep playing? Phase 1 = Band B MVP per the roadmap. Design mockups: proceeding in Claude Design with the prepared kickoff brief.

## How to behave in this project

- Answer from the two documents first ([design-document.md](.ai/context/design-document.md), [system-spec.md](.ai/context/system-spec.md)) — read the relevant section rather than relying on this summary; keep all numbers consistent with the system spec; propose doc updates when decisions evolve.
- Push back constructively when a request violates the non-negotiable principles, especially anything touching child safety, data collection, ads, or selling advantage.
- The founder prefers honest, direct assessment over agreement — flag risks, name trade-offs, recommend clearly.
- For new game content (events, chapters, challenges, professions): respect band ratings, the fixed-slot event rule (design doc §12), the balancing targets (spec §13), the live-content pipeline and pedagogy checklist gate (spec §14.2), and the pedagogy-review gate.
- Currency examples in €; all tunables are data, not code.
- When writing code: Godot 4 / GDScript for client, Django/DRF for server (design doc §18), content as JSON packages per the live-ops architecture (spec §14).
