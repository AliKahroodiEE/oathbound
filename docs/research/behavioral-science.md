# Behavioral Science Foundations

**Phase 1 — Research** · Status: draft for product review · Last updated: 2026-11-04

This document collects the behavioral-science evidence behind Oathbound's core mechanics and turns it into
concrete product rules. It is meant to be argued with. Every design implication names the evidence it rests
on and how strong that evidence is, so that later phases (product spec, UX, architecture) can tell a
research-backed rule apart from a reasonable guess.

---

## 0. How to read this document

### 0.1 Evidence labels

| Label | Meaning |
| --- | --- |
| **Strong** | Several meta-analyses and/or large preregistered replications point the same way. The direction is reliable. The size may still be smaller in a consumer app than in the source studies. |
| **Moderate** | Consistent findings across several studies, or a meta-analysis with notable heterogeneity, risk of bias, or narrow contexts (for example only loyalty cards or only students). |
| **Emerging** | Few studies, small samples, a single lab or paper, or no independent replication yet. |
| **Speculative / design assumption** | Our own extrapolation from evidence to product. It must be validated with users before we rely on it. |

### 0.2 Standing caveats

- Most evidence comes from health, education, workplace, and consumer settings, mostly in WEIRD (Western,
  educated, industrialized, rich, democratic) samples. We found almost no direct evidence from Persian-speaking
  populations. Anything we say about the `fa` locale is a design assumption.
- Effects found in a lab or a short trial usually shrink in long-term, self-directed app use. The 2021 exercise
  megastudy (Milkman et al., 2021) found that only a small minority of interventions kept a detectable effect
  after the program ended, and expert forecasts did not predict which interventions would work.
- Our objective is the user's **goal attainment and well-being**, not time-in-app. Several techniques below raise
  engagement in trials and still fail our bar (variable rewards, loss framing of permanent assets, public ranking).
  Where we reject an effective technique, we say so and explain why.

### 0.3 Working feature names used here

These are working names for review. The product spec (Phase 2, [`requirements.md`](../product/requirements.md))
owns final naming and copy. PRD feature IDs are given where a mechanic already exists there.

| Working name | What it is |
| --- | --- |
| **Growth Receipt** | The post-completion explanation of what XP was granted, to which attributes, and why (including caps and diminishing returns). Backed by the auditable ledger (PRD P3, C3). |
| **Oath** | An optional if-then plan attached to a quest: "When/after [cue], I will [action] [where]" (PRD Q9). |
| **Vigil** | The flexible streak: consecutive weeks in which the user met a weekly target they set themselves (PRD S1). |
| **Ember quest** | The minimum viable version of a recurring quest (for example, "2 minutes of stretching" instead of "20"). |
| **Rekindle** | The return flow after a lapse, plus one earned repair of a broken Vigil week. |
| **Waypoints** | Milestones that split a Long-Term Objective into shorter segments, each with its own progress bar. |
| **Set It Down** | The step in Evening Reflection where each unfinished item gets a plan (schedule, shrink, park, or release). |
| **New Chapter** | The fresh-start offer at temporal landmarks and after lapses. |
| **Mastered Rite** | A habit "graduated" once it has become automatic. |
| **Guild Undertaking** | A collective challenge: an additive, pooled guild target. |
| **Petition** | A user's appeal against an AI evaluation, resolved transparently in the ledger (PRD P7, "This doesn't seem right"). |
| **Condition** | The temporary HP-like state (PRD S4). It reflects recovery versus overexertion, is never reduced by missed tasks, and never affects attributes. |
| **Pause** | A user-declared pause (travel, illness, exams) that freezes consistency tracking without loss (PRD S3). |

---

## A. Self-Determination Theory and the undermining effect of rewards

### A.1 Key findings

- Self-Determination Theory (SDT) holds that people have three basic psychological needs: **autonomy** (acting
  from one's own volition), **competence** (feeling effective), and **relatedness** (feeling connected to others).
  Environments that support these needs foster *autonomous* motivation, meaning intrinsic interest plus
  well-internalized reasons ("this matters to me"). That kind of motivation predicts persistence, quality of
  engagement, and well-being (Ryan & Deci, 2000).
- Extrinsic motivation runs along a continuum: external regulation (reward or punishment), **introjected**
  regulation (guilt, shame, ego-involvement: "I should"), identified regulation (personally valued), and integrated
  regulation. Introjection can drive short-term behavior, but it carries emotional costs. Guilt-based copy
  pushes users toward introjection.
- Cognitive Evaluation Theory, a sub-theory of SDT: a reward has an *informational* aspect (it tells you about your
  competence) and a *controlling* aspect (it pressures you). Which one dominates decides whether intrinsic
  motivation rises or falls (Ryan, 1982).
- **Undermining (overjustification) effect.** The meta-analysis of 128 experiments by Deci, Koestner & Ryan (1999)
  found that *expected, tangible* rewards contingent on doing, completing, or performing a task reduced later
  free-choice engagement in interesting tasks (engagement-contingent d = −0.40, completion-contingent d = −0.36,
  performance-contingent d = −0.28). Positive feedback (verbal rewards) *increased* free-choice behavior
  (d = +0.33) and self-reported interest (d = +0.31). Unexpected rewards did not undermine. Children were more
  affected by tangible rewards than college students. The classic demonstration is Lepper, Greene & Nisbett (1973).
- The effect has been contested. Cameron & Pierce (1994) concluded that negative effects were limited. The
  current consensus is that undermining is real but conditional: it matters most for activities people already
  find interesting, and for rewards experienced as controlling.
- Incentives and intrinsic motivation are not simply opposed. In a 40-year meta-analysis, Cerasoli, Nicklin & Ford
  (2014) found that intrinsic motivation predicted performance *quality* and incentives better predicted
  *quantity*, and that the two jointly predicted performance.
- Applied SDT interventions in health produce small-to-medium gains in need support and autonomous motivation,
  and small gains in health behavior (Ng et al., 2012; Ntoumanis et al., 2021). Autonomy-supportive framing
  improves learning and persistence compared with controlling framing (Vansteenkiste et al., 2004). Peters,
  Calvo & Ryan (2018) apply SDT to digital product design (the METUX model).

### A.2 Evidence strength

- Undermining by expected, contingent, tangible rewards on free-choice behavior for interesting tasks: **Strong**.
  Note the meta-analytic debate (Cameron & Pierce, 1994 vs Deci et al., 1999).
- Positive informational feedback increases intrinsic motivation: **Strong**.
- Whether app XP behaves like a "tangible" reward or like verbal/symbolic feedback: **Speculative / design
  assumption**. XP has no monetary value but is expected and contingent. We treat it as at risk of being
  experienced as controlling unless we design it as information.
- SDT-informed interventions improve outcomes: **Moderate**. Effects are modest and heterogeneous.

### A.3 Design implications

- **XP is information, not payment.** The Growth Receipt explains *what grew and why* ("Strength +12: 40-minute
  run, logged with route; weekly cap not reached"). It is never framed as a wage.
- **Quest cards show which attributes a quest trains (icons and words), not a price tag.** By default the exact XP
  number appears only after completion, in the Growth Receipt and the ledger. Users who want an XP preview can
  turn it on in settings. That keeps the choice with the user.
- **Unscored logging.** Any activity can be logged to the Chronicle without XP evaluation. We will suggest this for
  activities the user describes as done purely for enjoyment, so measurement does not crowd out their
  enjoyment (see also Etkin, 2016, in section F).
- **Autonomy by construction.** Users author their own quests. AI suggestions are optional, capped at 3 per day,
  each with a one-line reason, and can be dismissed without consequence. Users can change the attribute mapping
  the AI proposes, and can file a Petition against any evaluation.
- **Autonomy-supportive copy.** Use "you could", "if it fits today", and "your plan said". Do not use "you must",
  "don't break", or "you failed". A copy lint list (EN and FA) blocks controlling phrasing and guilt or shame
  triggers.
- **Optional motivation profile.** It asks *why* a goal matters ("what would this change for you?") to support
  identified regulation. The AI reuses the user's own words when framing suggestions. The profile is never
  required, and it can be edited and deleted.
- **Diminishing returns in the engine** stop repetitive grinding of one behavior for XP. This protects both the
  integrity of the attributes and the user's reasons for acting.

### A.4 Risks and anti-patterns

- "Do this for 50 XP" framing on activities people already love: the textbook undermining setup.
- Turning the AI evaluator into a judge whose verdict feels controlling. Mitigations: transparent reasoning,
  Petition, no moralizing.
- Introjection levers: guilt notifications, shame mascots, "your guild is disappointed" messages.
- Mandatory onboarding questionnaires that profile the user before they have chosen to share anything.
- Treating SDT as a guarantee. Applied effects are modest, and our features still need measurement.

### A.5 Citations

- Cameron, J., & Pierce, W. D. (1994). Reinforcement, reward, and intrinsic motivation: A meta-analysis. *Review of Educational Research, 64*(3), 363–423. https://doi.org/10.3102/00346543064003363
- Cerasoli, C. P., Nicklin, J. M., & Ford, M. T. (2014). Intrinsic motivation and extrinsic incentives jointly predict performance: A 40-year meta-analysis. *Psychological Bulletin, 140*(4), 980–1008. https://doi.org/10.1037/a0035661
- Deci, E. L., Koestner, R., & Ryan, R. M. (1999). A meta-analytic review of experiments examining the effects of extrinsic rewards on intrinsic motivation. *Psychological Bulletin, 125*(6), 627–668. https://doi.org/10.1037/0033-2909.125.6.627
- Lepper, M. R., Greene, D., & Nisbett, R. E. (1973). Undermining children's intrinsic interest with extrinsic reward: A test of the "overjustification" hypothesis. *Journal of Personality and Social Psychology, 28*(1), 129–137. https://doi.org/10.1037/h0035519
- Ng, J. Y. Y., Ntoumanis, N., Thøgersen-Ntoumani, C., Deci, E. L., Ryan, R. M., Duda, J. L., & Williams, G. C. (2012). Self-determination theory applied to health contexts: A meta-analysis. *Perspectives on Psychological Science, 7*(4), 325–340. https://doi.org/10.1177/1745691612447309
- Ntoumanis, N., Ng, J. Y. Y., Prestwich, A., Quested, E., et al. (2021). A meta-analysis of self-determination theory-informed intervention studies in the health domain: Effects on motivation, health behavior, physical, and psychological health. *Health Psychology Review, 15*(2), 214–244. https://doi.org/10.1080/17437199.2020.1718529
- Peters, D., Calvo, R. A., & Ryan, R. M. (2018). Designing for motivation, engagement and wellbeing in digital experience. *Frontiers in Psychology, 9*, 797. https://doi.org/10.3389/fpsyg.2018.00797
- Ryan, R. M. (1982). Control and information in the intrapersonal sphere: An extension of cognitive evaluation theory. *Journal of Personality and Social Psychology, 43*(3), 450–461. https://doi.org/10.1037/0022-3514.43.3.450
- Ryan, R. M., & Deci, E. L. (2000). Self-determination theory and the facilitation of intrinsic motivation, social development, and well-being. *American Psychologist, 55*(1), 68–78. https://doi.org/10.1037/0003-066X.55.1.68
- Vansteenkiste, M., Simons, J., Lens, W., Sheldon, K. M., & Deci, E. L. (2004). Motivating learning, performance, and persistence: The synergistic effects of intrinsic goal contents and autonomy-supportive contexts. *Journal of Personality and Social Psychology, 87*(2), 246–260. https://doi.org/10.1037/0022-3514.87.2.246

---

## B. Goal-gradient effect

### B.1 Key findings

- Hull (1932) observed that rats ran faster the closer they were to a food reward: effort increases as a goal
  approaches.
- Kivetz, Urminsky & Zheng (2006) revived the idea with field data. Coffee-shop loyalty members bought more
  often as they neared a free coffee. A 12-stamp card with 2 bonus stamps already filled was completed faster
  than a 10-stamp card, even though both needed 10 purchases ("illusionary goal progress"). Members who
  accelerated more were more likely to be retained, and purchase rates dropped back after the reward was
  redeemed (a post-reward reset).
- Motivation is often U-shaped across a goal. People are "stuck in the middle", where neither the distance
  covered nor the distance remaining feels large (Bonezzi, Brendl & De Angelis, 2011).
- Framing matters. Highlighting accomplished actions ("to-date") boosts motivation when commitment is still
  uncertain. Highlighting remaining actions ("to-go") works better once commitment is established (Koo &
  Fishbach, 2008).

### B.2 Evidence strength

- Goal-gradient acceleration: **Moderate**. It replicates across animal, consumer, and lab settings, but most
  human evidence is from loyalty programs, and we know of few preregistered replications.
- "Stuck in the middle" and reference-point switching: **Moderate**.
- Size of the effect in self-improvement apps: **Speculative / design assumption**.

### B.3 Design implications

- **The XP bar shows absolute progress to the next level (current XP / XP required), never inflated or rescaled
  to look closer than it is.** Bars never start pre-filled except with real, labeled progress (section F).
- **Waypoints for Long-Term Objectives.** The AI suggests, and the user approves, 3–7 Waypoints per objective.
  Each has its own bar, so the user is never far from the next visible goal, which shortens "the middle".
- **Reference-point switch.** Below 50% of a Waypoint, show "done so far". Past 50%, show "remaining". For
  objectives created in the last 14 days (commitment still forming), always show "done so far".
- **Level curve with interstitial markers.** Early levels are short, for quick competence. Later levels are
  longer, but a title or Waypoint milestone always sits within roughly 7–10 active days of typical activity.
  The exact number is a design assumption to be tuned in Phase 2.
- **Celebrate, then show the next step lightly.** After a level or Waypoint, show a short celebration and one
  suggested next Waypoint, to soften the post-reward reset. There is no countdown and no pressure.
- **Near-completion messaging only in the Daily Briefing.** Never send a push notification like "only 20 XP to
  go!", and never send one during quiet hours.

### B.4 Risks and anti-patterns

- Manufactured proximity (fake "almost there" states). This is manipulation and resembles gambling near-misses
  (section H).
- Over-acceleration on Vitality and Strength quests near a milestone, leading to injury or burnout. Engine caps
  apply per day and per week.
- Abandonment after a big goal is reached, if no next step is ever planned.
- Rewarding speed toward a goal regardless of whether the goal is still worth pursuing. The Weekly Review lets
  users retire objectives without penalty.

### B.5 Citations

- Bonezzi, A., Brendl, C. M., & De Angelis, M. (2011). Stuck in the middle: The psychophysics of goal pursuit. *Psychological Science, 22*(5), 607–612. https://doi.org/10.1177/0956797611404899
- Hull, C. L. (1932). The goal-gradient hypothesis and maze learning. *Psychological Review, 39*(1), 25–43. https://doi.org/10.1037/h0072640
- Kivetz, R., Urminsky, O., & Zheng, Y. (2006). The goal-gradient hypothesis resurrected: Purchase acceleration, illusionary goal progress, and customer retention. *Journal of Marketing Research, 43*(1), 39–58. https://doi.org/10.1509/jmkr.43.1.39
- Koo, M., & Fishbach, A. (2008). Dynamics of self-regulation: How (un)accomplished goal actions affect motivation. *Journal of Personality and Social Psychology, 94*(2), 183–195. https://doi.org/10.1037/0022-3514.94.2.183

---

## C. Goal-setting theory and implementation intentions

### C.1 Key findings

- **Goal-setting theory.** Specific, difficult goals lead to higher performance than vague "do your best" goals.
  The effect is moderated by commitment, feedback, ability, and task complexity. For complex or novel tasks,
  learning goals ("master three techniques") can outperform outcome goals (Locke & Latham, 2002).
- In behavior-change RCTs, goal setting has a small-to-medium unique effect (d = 0.34 across 384 effect sizes).
  The effect was larger when goals were difficult, **set publicly**, or **set as group goals** (Epton, Currie &
  Armitage, 2017).
- Goals have side effects: narrowed focus, neglect of non-goal areas, risk-taking, unethical shortcuts, and
  reduced intrinsic motivation when goals are imposed or over-specified (Ordóñez et al., 2009).
- Intentions often fail to become action (the intention–behavior gap; Sheeran & Webb, 2016).
- **Implementation intentions** are if-then plans ("If situation X arises, I will do Y"). They delegate action
  initiation to a situational cue (Gollwitzer, 1999). A meta-analysis of 94 independent tests found a
  medium-to-large effect on goal attainment (d = 0.65; Gollwitzer & Sheeran, 2006). Effects are smaller in some
  domains, for example physical activity (Bélanger-Gravel, Godin & Amireault, 2013).
- **Mental contrasting with implementation intentions (MCII, "WOOP")** pairs a desired future with its main
  obstacle and an if-then plan to handle it (Oettingen, 2012). A meta-analysis found a small-to-medium effect
  (g = 0.34), larger when delivered interactively, and flagged possible publication bias (Wang, Wang & Gai, 2021).

### C.2 Evidence strength

- Specific, challenging goals improve performance: **Strong** (the direction is robust; side effects are well
  documented).
- Implementation intentions improve goal attainment: **Strong** for direction. The size is likely inflated by
  publication bias and lab settings, so expect smaller effects in-app.
- MCII: **Moderate**.
- Public and group goals amplify effects: **Moderate**. This comes from moderator analyses, which are
  correlational across studies.

### C.3 Design implications

- **Action-shaped quests.** Quest creation asks for an action and an amount ("Run 20 minutes"), not an outcome
  ("Get fit"). The AI evaluator may *suggest* a more specific rewrite. The user accepts or ignores it.
- **Oath clause.** An optional field on Daily Quests and Contracts: "When/after ___, I will ___ (where ___)". It
  comes prefilled with examples tied to existing routines ("after my morning tea"). The Daily Briefing lists
  today's Oaths by cue, not by priority.
- **Obstacle clause on Long-Term Objectives (MCII-lite).** One optional prompt: "What is most likely to get in the
  way? If that happens, I will…". It is shown again in the Weekly Review only if the user filled it in.
- **Difficulty dial per recurring quest: Ember / Standard / Heroic.** The user sets the default. The AI suggests
  stepping up only after sustained success at the current level (section J).
- **Learning goals are first-class.** Long-Term Objectives can be learning-shaped ("Learn the 5 basic chords"),
  not only outcome-shaped.
- **Cap on concurrent Long-Term Objectives (default 3, user-adjustable up to 5).** This limits goal conflict and
  overload. The number is a design assumption.
- **Guild shared goals.** Guilds can set a group goal for an Undertaking (section E). This draws on the group-goal
  moderator in Epton et al. (2017).

### C.4 Risks and anti-patterns

- Over-ambitious goals that set up repeated failure ("false hope", section K). The app flags targets far above
  the user's recent baseline and offers a gentler start.
- "Goals gone wild": rewarding volume encourages padding and over-logging. The AI evaluator plus engine caps and
  diminishing returns counter this.
- Too many simultaneous if-then plans, which can dilute their cue value. Limiting Oaths to quests the user
  actively chooses is a design assumption, not an established threshold.
- Imposing goals. The AI never creates quests without the user's acceptance.

### C.5 Citations

- Bélanger-Gravel, A., Godin, G., & Amireault, S. (2013). A meta-analytic review of the effect of implementation intentions on physical activity. *Health Psychology Review, 7*(1), 23–54. https://doi.org/10.1080/17437199.2011.560095
- Epton, T., Currie, S., & Armitage, C. J. (2017). Unique effects of setting goals on behavior change: Systematic review and meta-analysis. *Journal of Consulting and Clinical Psychology, 85*(12), 1182–1198. https://doi.org/10.1037/ccp0000260
- Gollwitzer, P. M. (1999). Implementation intentions: Strong effects of simple plans. *American Psychologist, 54*(7), 493–503. https://doi.org/10.1037/0003-066X.54.7.493
- Gollwitzer, P. M., & Sheeran, P. (2006). Implementation intentions and goal achievement: A meta-analysis of effects and processes. *Advances in Experimental Social Psychology, 38*, 69–119. https://doi.org/10.1016/S0065-2601(06)38002-1
- Locke, E. A., & Latham, G. P. (2002). Building a practically useful theory of goal setting and task motivation: A 35-year odyssey. *American Psychologist, 57*(9), 705–717. https://doi.org/10.1037/0003-066X.57.9.705
- Oettingen, G. (2012). Future thought and behaviour change. *European Review of Social Psychology, 23*(1), 1–63. https://doi.org/10.1080/10463283.2011.643698
- Ordóñez, L. D., Schweitzer, M. E., Galinsky, A. D., & Bazerman, M. H. (2009). Goals gone wild: The systematic side effects of overprescribing goal setting. *Academy of Management Perspectives, 23*(1), 6–16. https://doi.org/10.5465/amp.2009.37007999
- Sheeran, P., & Webb, T. L. (2016). The intention–behavior gap. *Social and Personality Psychology Compass, 10*(9), 503–518. https://doi.org/10.1111/spc3.12265
- Wang, G., Wang, Y., & Gai, X. (2021). A meta-analysis of the effects of mental contrasting with implementation intentions on goal attainment. *Frontiers in Psychology, 12*, 565202. https://doi.org/10.3389/fpsyg.2021.565202

---

## D. Habit formation, automaticity, context cues, and missed days

### D.1 Key findings

- A habit is a learned association between a context and a response, built by repeating the behavior in a stable
  context. Once formed, the cue triggers the behavior with little deliberation, and the habit becomes relatively
  insensitive to current goals (Wood & Neal, 2007; Wood & Rünger, 2016).
- **How long?** Lally et al. (2010) followed 96 people performing a self-chosen daily behavior in a consistent
  context for 12 weeks. Automaticity rose along an asymptotic curve. Among participants with well-fitting curves,
  the median time to near-plateau was 66 days, with modelled estimates ranging from 18 to 254 days. **Missing one
  opportunity did not materially affect the habit-formation process.** Caveats: the sample was small, good fits
  were found for only 39 participants, and there were few missed-day data points.
- A 2024 systematic review (20 studies, 2,601 adults) found median times of about 59–66 days, individual times
  ranging from 4 to 335 days, and determinants including repetition frequency, a stable time and place, specific
  plans, personal choice, and enjoyment. Many included studies had high risk of bias (Singh et al., 2024).
- Formation speed depends on the behavior. Machine-learning analysis of large panel data suggested that gym
  habits take months to become predictable, while hospital handwashing takes weeks (Buyalskaya et al., 2023).
- A change of context (moving house, a new job) disrupts old habits and opens a window in which intentions guide
  behavior again (Wood, Tam & Witt, 2005).
- Anchoring a new behavior to an existing routine supports automaticity (Judah, Gardner & Aunger, 2013). In a
  4-week app study, **reminders supported repetition but hindered habit development, while event-based cues
  increased automaticity** (Stawarz, Cox & Blandford, 2015).
- Practical guidance for clinicians: choose a simple action, tie it to a consistent cue, repeat it, and expect it
  to get easier with time (Gardner, Lally & Wardle, 2012).
- Habit strength can be measured by self-report. The Self-Report Habit Index (Verplanken & Orbell, 2003) and
  its 4-item automaticity subscale, the SRBAI (Gardner et al., 2012), are validated.
- **Streaks.** Across seven studies, an intact logged streak led to more subsequent engagement than a broken
  one. The drop after a break was weaker when the streak could be repaired (Silverman & Barasch, 2023).

### D.2 Evidence strength

- Context-cue repetition model of habit: **Moderate** (convergent lab, field, and large observational evidence).
- Time-to-habit estimates: **Emerging**. Variability is huge, samples are small, and risk of bias is high. Only
  the "it varies widely, often months" message is reliable.
- One missed day does not derail habit formation: **Emerging**. One study with few missed-day observations, but
  the direction is plausible.
- Reminders can create reminder-dependence: **Emerging** (one small study).
- Broken streaks reduce subsequent engagement, softened by repairability: **Moderate** (one multi-study paper).

### D.3 Design implications

- **Cue-first recurring quests.** Daily Quests invite an Oath cue ("after brushing teeth") and a fixed time or
  place. Event-based cues are the default suggestion. Clock reminders are optional extras.
- **Habit Strength meter.** It is based on consistency of performance in context (the share of planned occasions
  completed over a rolling 4 weeks), not on streak length. An optional monthly 4-item automaticity check-in uses
  SRBAI-style items rated by the user.
- **Honest duration copy.** "Many habits take around two months to feel automatic. Some take much longer, and
  that is normal." Never "21 days".
- **A missed recurring quest never deducts attributes.** It is recorded as "not done": neutral styling, no red X.
  The Habit Strength meter declines gradually, never to zero from one miss.
- **Vigil (flexible streak): streaks are counted as weeks meeting a user-set target (for example 4 of 7 days),
  with at least one rest day per week built in.** One Rekindle per calendar month repairs a missed week. Rekindles
  are earned by activity and can never be bought. If the PRD's daily chain (S2) ships, it keeps its automatic
  weekly rest day and manual rest days, and it is never the headline consistency metric.
- **Pause (PRD S3).** Users can pause consistency tracking for travel, illness, or exams without any loss. This
  is a planned, guilt-free alternative to a broken streak.
- **Graduation to Mastered Rite.** When consistency is at least about 80% for 8+ weeks and the automaticity
  check-in is high, the app offers graduation. Reminders are reduced or removed, XP for that quest tapers under
  diminishing returns, and a permanent title records the achievement. This frees the user's notification budget
  for newer goals. The thresholds are design assumptions.
- **New Season prompt.** When the user reports a life change (move, new job, new semester, travel), the app
  offers to re-plan cues for existing quests, using the habit-discontinuity window.
- **Behavior-specific expectations.** Exercise-type quests show a longer expected ramp than simple consumption
  habits.

### D.4 Risks and anti-patterns

- **Streak terror:** daily all-or-nothing streaks whose loss feels catastrophic, which drives abandonment.
- Reminder-dependence: notifications become the cue, and the habit never transfers to context.
- Treating every goal as a habit. One-off Contracts and Long-Term Objectives need plans, not repetition.
- Promising a fixed timeline, then implying failure when the user takes longer.

### D.5 Citations

- Buyalskaya, A., Ho, H., Milkman, K. L., Li, X., Duckworth, A. L., & Camerer, C. (2023). What can machine learning teach us about habit formation? Evidence from exercise and hygiene. *Proceedings of the National Academy of Sciences, 120*(17), e2216115120. https://doi.org/10.1073/pnas.2216115120
- Gardner, B., Abraham, C., Lally, P., & de Bruijn, G.-J. (2012). Towards parsimony in habit measurement: Testing the convergent and predictive validity of an automaticity subscale of the Self-Report Habit Index. *International Journal of Behavioral Nutrition and Physical Activity, 9*, 102. https://doi.org/10.1186/1479-5868-9-102
- Gardner, B., Lally, P., & Wardle, J. (2012). Making health habitual: The psychology of 'habit-formation' and general practice. *British Journal of General Practice, 62*(605), 664–666. https://doi.org/10.3399/bjgp12X659466
- Judah, G., Gardner, B., & Aunger, R. (2013). Forming a flossing habit: An exploratory study of the psychological determinants of habit formation. *British Journal of Health Psychology, 18*(2), 338–353. https://doi.org/10.1111/j.2044-8287.2012.02086.x
- Lally, P., van Jaarsveld, C. H. M., Potts, H. W. W., & Wardle, J. (2010). How are habits formed: Modelling habit formation in the real world. *European Journal of Social Psychology, 40*(6), 998–1009. https://doi.org/10.1002/ejsp.674
- Silverman, J., & Barasch, A. (2023). On or off track: How (broken) streaks affect consumer decisions. *Journal of Consumer Research, 49*(6), 1095–1117. https://doi.org/10.1093/jcr/ucac029
- Singh, B., Murphy, A., Maher, C., & Smith, A. E. (2024). Time to form a habit: A systematic review and meta-analysis of health behaviour habit formation and its determinants. *Healthcare, 12*(23), 2488. https://doi.org/10.3390/healthcare12232488
- Stawarz, K., Cox, A. L., & Blandford, A. (2015). Beyond self-tracking and reminders: Designing smartphone apps that support habit formation. In *Proceedings of CHI 2015* (pp. 2653–2662). ACM. https://doi.org/10.1145/2702123.2702230
- Verplanken, B., & Orbell, S. (2003). Reflections on past behavior: A self-report index of habit strength. *Journal of Applied Social Psychology, 33*(6), 1313–1330. https://doi.org/10.1111/j.1559-1816.2003.tb01951.x
- Wood, W., & Neal, D. T. (2007). A new look at habits and the habit–goal interface. *Psychological Review, 114*(4), 843–863. https://doi.org/10.1037/0033-295X.114.4.843
- Wood, W., & Rünger, D. (2016). Psychology of habit. *Annual Review of Psychology, 67*, 289–314. https://doi.org/10.1146/annurev-psych-122414-033417
- Wood, W., Tam, L., & Witt, M. G. (2005). Changing circumstances, disrupting habits. *Journal of Personality and Social Psychology, 88*(6), 918–933. https://doi.org/10.1037/0022-3514.88.6.918

---

## E. Social support, accountability, recognition, social comparison, public commitment, and cooperative goals

### E.1 Key findings

- **Social support.** Recruiting weight-loss participants with friends and adding social support improved
  completion and maintenance of weight loss (Wing & Jeffery, 1999). A review of reviews found that engaging social
  support was among the intervention components associated with greater effectiveness in diet and physical
  activity interventions (Greaves et al., 2011). Not every support format helps. In an RCT on fat intake,
  partner-based interventions produced small, often only marginally significant benefits (Prestwich et al., 2014).
- **Support versus comparison.** In a 4-arm RCT (n = 790), anonymous online peer *comparison* raised exercise-class
  attendance well above control. A peer *support* network alone did not, and attendance in the support-only arm
  was numerically below control (Zhang et al., 2016).
- **Competition and collaboration.** In the STEP UP trial (n = 602), gamification with competition increased
  daily steps most (+920 steps/day versus control). Support and collaboration arms also increased steps. Only
  the competition arm stayed significantly above control during follow-up (Patel et al., 2019).
- **Social comparison theory.** People evaluate themselves by comparing with others, especially similar others
  (Festinger, 1954). A meta-analysis spanning six decades found that people tend to *choose* upward comparison
  targets, yet the dominant *reaction* is contrast: self-evaluations drop after upward comparison, especially for
  ability (Gerber, Wheeler & Suls, 2018). Superior others inspire when their success seems attainable and deflate
  when it does not (Lockwood & Kunda, 1997).
- **Cooperative goal structures.** A meta-analysis found that cooperative goal structures were associated with
  higher achievement and more positive peer relationships than competitive or individualistic ones (Roseth,
  Johnson & Johnson, 2008). In group tasks, a weaker member can work harder when their contribution matters to
  the team, an effect shown in an exergame with a virtual partner (the Köhler effect; Feltz, Kerr & Irwin, 2011).
  The opposite risk is social loafing, which is reduced when individual contributions are identifiable, the task
  is meaningful, and the group is valued (Karau & Williams, 1993).
- **Public commitment.** Progress monitoring works better when results are reported to others or made public
  (Harkin et al., 2016), and goals set publicly have larger effects (Epton et al., 2017). However, when others
  noticed people's *identity-related* intentions ("I will become a psychologist"), they acted on them less,
  apparently because the acknowledgement gave a premature sense of having reached the identity (Gollwitzer et al.,
  2009).
- **Recognition.** Positive informational feedback increases intrinsic motivation (Deci et al., 1999). Purely
  symbolic awards raised performance in a field experiment (Kosfeld & Neckermann, 2011).

### E.2 Evidence strength

- Social support helps behavior change: **Moderate**. It depends on format, and support alone can underperform.
- Comparison and competition raise activity in trials: **Moderate**. The effects are real, but so are documented
  harms (section L, Hanus & Fox, 2015) and contrast effects on self-evaluation.
- Cooperative structures outperform competitive and individualistic ones for achievement and relationships:
  **Strong** in education settings, **Moderate** for consumer apps.
- Public reporting amplifies monitoring and goal effects: **Moderate**.
- Public identity intentions backfire: **Emerging**. One paper, and we found no independent replications.
- Symbolic recognition: **Moderate**.

### E.3 Design implications

- **Private by default, graded sharing.** Quests are private until the user picks a sharing level. The PRD's
  levels (Full, Title only, Completion only, Private), set as a per-guild default with per-quest override, let
  people show *that* they acted without showing *what*. That combines public reporting (Harkin et al., 2016) with
  privacy.
- **Share actions and specific plans, not identity proclamations.** Feed post templates describe what was done
  ("Finished chapter 3 of the statistics course") or a concrete Oath ("Tomorrow after work: 30-minute run"). We do
  not template "I'm becoming a runner"-style announcements, based on Gollwitzer et al. (2009), so that the
  announcement does not stand in for the action.
- **Supportive reactions only.** A small fixed set of positive reactions (working names: Salute, Torch, Shield).
  There are no negative reactions. Reaction counts are visible to the post author and not ranked publicly. This
  is a design assumption, aimed at limiting popularity comparison.
- **Guild Undertakings (collective challenges, PRD G6) are additive.** Members' contributions pool toward a
  shared target. When a Guild Master sets the target, the app recommends one based on currently active members'
  recent activity. One member's inactivity never reduces another member's rewards and never fails the Undertaking
  for others. Contributions are identifiable to counter social loafing, but they are shown as an unranked
  "contributed this week" roll, not a ranking.
- **Opt-in Rivalry, near-peer and time-boxed.** Small groups (3–6) matched by similar recent activity, running 1–2
  weeks, comparing **consistency** (the percentage of one's *own* targets met) rather than raw XP. Each member sees
  their own position and the adjacent ones. No "last place" label exists. Users can leave silently at any time.
  This keeps the benefit of competition found by Patel et al. (2019) and Zhang et al. (2016) while limiting the
  upward-contrast harm described by Gerber et al. (2018) and Lockwood & Kunda (1997).
- **Oath-witness (accountability partner).** A user can share a specific Oath with one chosen guildmate, who sees
  completions and can react. The witness is *not* notified of misses.
- **Commendations.** Members can commend a specific effort ("kept the Oath through exam week"). The weekly
  Chronicle highlights effort and consistency, never only the top XP earners.
- **No global or public leaderboards.** Public guilds are discovered by interest, language, and activity level,
  not by rank.

### E.4 Risks and anti-patterns

- Leaderboard-bottom demoralization and upward-comparison contrast. These are the main reason ranking stays
  opt-in, near-peer, and consistency-based.
- Shame by visibility: showing misses, inactivity, or "who let the guild down".
- Social pressure turning into coercion inside guilds. Users get mute, leave, and report tools, plus moderation.
- Privacy leaks. Social-attribute quests often involve other people, so the app never auto-posts details about
  third parties.
- Large anonymous groups where contributions feel irrelevant (loafing). Undertakings use sub-squads
  (≤ about 12 members, a design assumption) inside large public guilds.
- Harassment and pile-ons in comments. Moderation tooling is a Phase 2 requirement.

### E.5 Citations

- Epton, T., Currie, S., & Armitage, C. J. (2017). (See section C.)
- Feltz, D. L., Kerr, N. L., & Irwin, B. C. (2011). Buddy up: The Köhler effect applied to health games. *Journal of Sport and Exercise Psychology, 33*(4), 506–526. https://doi.org/10.1123/jsep.33.4.506
- Festinger, L. (1954). A theory of social comparison processes. *Human Relations, 7*(2), 117–140. https://doi.org/10.1177/001872675400700202
- Gerber, J. P., Wheeler, L., & Suls, J. (2018). A social comparison theory meta-analysis 60+ years on. *Psychological Bulletin, 144*(2), 177–197. https://doi.org/10.1037/bul0000127
- Gollwitzer, P. M., Sheeran, P., Michalski, V., & Seifert, A. E. (2009). When intentions go public: Does social reality widen the intention-behavior gap? *Psychological Science, 20*(5), 612–618. https://doi.org/10.1111/j.1467-9280.2009.02336.x
- Greaves, C. J., Sheppard, K. E., Abraham, C., et al. (2011). Systematic review of reviews of intervention components associated with increased effectiveness in dietary and physical activity interventions. *BMC Public Health, 11*, 119. https://doi.org/10.1186/1471-2458-11-119
- Karau, S. J., & Williams, K. D. (1993). Social loafing: A meta-analytic review and theoretical integration. *Journal of Personality and Social Psychology, 65*(4), 681–706. https://doi.org/10.1037/0022-3514.65.4.681
- Kosfeld, M., & Neckermann, S. (2011). Getting more work for nothing? Symbolic awards and worker performance. *American Economic Journal: Microeconomics, 3*(3), 86–99. https://doi.org/10.1257/mic.3.3.86
- Lockwood, P., & Kunda, Z. (1997). Superstars and me: Predicting the impact of role models on the self. *Journal of Personality and Social Psychology, 73*(1), 91–103. https://doi.org/10.1037/0022-3514.73.1.91
- Patel, M. S., Small, D. S., Harrison, J. D., et al. (2019). Effectiveness of behaviorally designed gamification interventions with social incentives for increasing physical activity among overweight and obese adults across the United States: The STEP UP randomized clinical trial. *JAMA Internal Medicine, 179*(12), 1624–1632. https://doi.org/10.1001/jamainternmed.2019.3505
- Prestwich, A., Conner, M. T., Lawton, R. J., Ward, J. K., Ayres, K., & McEachan, R. R. C. (2014). Partner- and planning-based interventions to reduce fat consumption: Randomized controlled trial. *British Journal of Health Psychology, 19*(1), 132–148. https://doi.org/10.1111/bjhp.12047
- Roseth, C. J., Johnson, D. W., & Johnson, R. T. (2008). Promoting early adolescents' achievement and peer relationships: The effects of cooperative, competitive, and individualistic goal structures. *Psychological Bulletin, 134*(2), 223–246. https://doi.org/10.1037/0033-2909.134.2.223
- Wing, R. R., & Jeffery, R. W. (1999). Benefits of recruiting participants with friends and increasing social support for weight loss and maintenance. *Journal of Consulting and Clinical Psychology, 67*(1), 132–138. https://doi.org/10.1037/0022-006X.67.1.132
- Zhang, J., Brackbill, D., Yang, S., Becker, J., Herbert, N., & Centola, D. (2016). Support or competition? How online social networks increase physical activity: A randomized controlled trial. *Preventive Medicine Reports, 4*, 453–458. https://doi.org/10.1016/j.pmedr.2016.08.008

---

## F. Progress feedback and monitoring; the endowed progress effect

### F.1 Key findings

- **Progress monitoring works.** A meta-analysis of 138 experimental studies (N = 19,951) found that interventions
  that increased progress monitoring improved goal attainment (d = 0.40). The effect was mediated by how often
  people monitored, and it was larger when progress was **physically recorded** and when it was **reported to
  others or made public** (Harkin et al., 2016).
- Self-monitoring combined with at least one other self-regulation technique (goal setting, feedback, review of
  goals) was associated with more effective healthy-eating and physical-activity interventions (Michie et al.,
  2009).
- **Feedback can backfire.** Across 607 effect sizes, feedback interventions improved performance on average
  (d ≈ 0.41), but over a third of the effects were negative. Feedback that shifts attention from the task to the
  self tended to hurt (Kluger & DeNisi, 1996).
- Positive feedback motivates when it signals commitment (typical for novices). Negative feedback motivates when
  it signals insufficient progress (typical for committed or expert pursuers) (Fishbach, Eyal & Finkelstein,
  2010). Perceived progress can also *license* goal-inconsistent choices: "I've done well, so I can slack" (Fishbach
  & Dhar, 2005).
- **Measurement has a hidden cost.** Across six experiments, measuring an enjoyable activity (steps walked, pages
  read) increased output but reduced enjoyment, continued engagement, and subjective well-being (Etkin, 2016).
- **Endowed progress.** Car-wash customers given a 10-stamp card with 2 stamps already filled completed it more
  often and faster than customers given an 8-stamp card, although both needed 8 purchases (roughly 34% versus 19%
  completion). The effect is described as stronger when the head start comes with a reason (Nunes & Drèze, 2006).
  Kivetz et al. (2006) found the same "illusionary progress" pattern with coffee cards.

### F.2 Evidence strength

- Progress monitoring improves goal attainment: **Strong**.
- Feedback often harms when it is self-focused or poorly designed: **Strong**.
- Measurement reduces enjoyment of intrinsically enjoyable activities: **Emerging**. One paper with student
  samples, but it fits SDT.
- Endowed progress: **Moderate** for the effect, which is mostly from loyalty programs. Ethically ambiguous when
  the endowment is *artificial*.

### F.3 Design implications

- **Completion is physically recorded.** One tap plus an optional note, photo, or duration. This record is also
  the evidence the AI evaluator reads. It ties monitoring to a recorded log, the stronger moderator in Harkin et
  al. (2016).
- **Weekly Review = monitor, then adjust.** Review last week against the user's own targets, then adjust targets,
  retire or add quests, and refresh Oaths. This combines self-monitoring with goal review (Michie et al., 2009).
- **Analytics compare users against their own baseline.** Weekly, monthly, and yearly views show trends,
  consistency, and attribute growth relative to the user's own past, never against other users.
- **Task-focused feedback copy.** "Weekday runs were steady; weekends dipped. Want a shorter weekend Ember
  version?" Never "You're lazy on weekends", and never person-level praise like "You're a machine". This follows
  Kluger & DeNisi (1996).
- **Feedback valence follows commitment.** In a user's first weeks, feedback emphasizes what was accomplished.
  For established objectives, the Weekly Review may plainly state the gap to target, always paired with a
  concrete next step.
- **No licensing copy.** Celebrations never say "you've earned a break from X". Rest is offered on its own merits
  (Condition, rest days), not as a reward for progress.
- **Honest endowed progress only.** Real onboarding actions count toward Level 1 and are labeled as such: creating
  the character, writing the first quest, completing it. If users declare existing habits at onboarding, those
  may seed the Habit Strength meter at reduced weight and are clearly labeled "carried in". Never pre-fill bars
  with fake progress.
- **Quiet mode.** Users can hide numbers (XP, counts) and keep only qualitative progress, for areas where
  quantification spoils enjoyment (Etkin, 2016).

### F.4 Risks and anti-patterns

- Dashboard anxiety and over-quantification of leisure.
- Fake or inflated progress used to manipulate effort.
- Vanity metrics such as total XP or global percentile, which invite comparison rather than reflection.
- Data overload. Analytics default to 3–4 key insights, with drill-down on request.
- AI "insights" that moralize or diagnose rather than describe.

### F.5 Citations

- Etkin, J. (2016). The hidden cost of personal quantification. *Journal of Consumer Research, 42*(6), 967–984. https://doi.org/10.1093/jcr/ucv095
- Fishbach, A., & Dhar, R. (2005). Goals as excuses or guides: The liberating effect of perceived goal progress on choice. *Journal of Consumer Research, 32*(3), 370–377. https://doi.org/10.1086/497548
- Fishbach, A., Eyal, T., & Finkelstein, S. R. (2010). How positive and negative feedback motivate goal pursuit. *Social and Personality Psychology Compass, 4*(8), 517–530. https://doi.org/10.1111/j.1751-9004.2010.00285.x
- Harkin, B., Webb, T. L., Chang, B. P. I., Prestwich, A., Conner, M., Kellar, I., Benn, Y., & Sheeran, P. (2016). Does monitoring goal progress promote goal attainment? A meta-analysis of the experimental evidence. *Psychological Bulletin, 142*(2), 198–229. https://doi.org/10.1037/bul0000025
- Kivetz, R., Urminsky, O., & Zheng, Y. (2006). (See section B.)
- Kluger, A. N., & DeNisi, A. (1996). The effects of feedback interventions on performance: A historical review, a meta-analysis, and a preliminary feedback intervention theory. *Psychological Bulletin, 119*(2), 254–284. https://doi.org/10.1037/0033-2909.119.2.254
- Michie, S., Abraham, C., Whittington, C., McAteer, J., & Gupta, S. (2009). Effective techniques in healthy eating and physical activity interventions: A meta-regression. *Health Psychology, 28*(6), 690–701. https://doi.org/10.1037/a0016136
- Nunes, J. C., & Drèze, X. (2006). The endowed progress effect: How artificial advancement increases effort. *Journal of Consumer Research, 32*(4), 504–512. https://doi.org/10.1086/500480

---

## G. Zeigarnik effect, goal salience, and plan-making that relieves intrusive thoughts

### G.1 Key findings

- Zeigarnik (1927) reported that interrupted tasks were recalled better than completed ones. The idea is widely
  used in product design ("open loops"), but a 2025 meta-analysis found **no general memory advantage** for
  unfinished tasks. The Zeigarnik effect "lacks universal validity". The meta-analysis did find a robust tendency
  to **resume** interrupted tasks, the Ovsiankina effect (Ghibellini & Meier, 2025).
- Unfulfilled goals do stay cognitively active. Across several experiments, an unfinished goal produced intrusive
  thoughts during an unrelated task, heightened accessibility of goal-related words, and worse performance on a
  separate task. **Making a specific plan for the goal eliminated these effects**, even though the goal itself
  was still unfinished (Masicampo & Baumeister, 2011).
- In a 12-week diary study with 59 employees, unfinished tasks at the end of the work week predicted worse
  weekend sleep via affective rumination (Syrek et al., 2017).
- In a polysomnography study (n = 57), writing a specific to-do list for the coming days at bedtime led to faster
  sleep onset than writing about completed activities. More specific lists were associated with faster sleep
  onset (Scullin et al., 2018).

### G.2 Evidence strength

- Better memory for unfinished tasks (classic Zeigarnik effect): **Weak / not reliably replicated.** Do not use
  it as a design rationale.
- Tendency to resume interrupted tasks (Ovsiankina effect): **Moderate**.
- Plan-making relieves the cognitive intrusion of unfinished goals: **Emerging**. One multi-study paper, and we
  know of no large independent replication.
- Unfinished tasks impair rest via rumination: **Moderate** (longitudinal diary data, correlational).
- Bedtime to-do lists speed sleep onset: **Emerging** (single small study).

### G.3 Design implications

- **Set It Down (Evening Reflection).** Each unfinished Contract or quest gets one of four choices: **schedule** (pick
  a day and time), **shrink** (define the next small step), **park** (no date, hidden from Today), or **release**
  (drop it without penalty). The ritual is designed to take under 60 seconds and ends with "Tomorrow's first step
  is set."
- **Every Contract has a "next step" field.** If a Contract sits for 3 days without one, the Daily Briefing asks
  once: "What's the very next action?"
- **Weekly close-out.** The Weekly Review includes the same Set It Down pass for the week's loose ends. Its default
  day is the last workday of the user's locale, and it is user-configurable.
- **Resume cards (benign Ovsiankina).** A paused task can store "where I left off" in one line, and that note is
  shown on the resume card, so returning is easy.
- **No artificial open loops.** No progress bars deliberately left at 90%, no cliffhanger notifications, no
  "incomplete ring" mechanics designed to nag.
- **No overdue counters in the evening or in notifications.** Overdue items appear only in planning views, as a
  neutral list with a bulk "reschedule or release" action.

### G.4 Risks and anti-patterns

- Weaponizing unfinished states to pull users back, which produces intrusive thoughts and worse sleep.
- Backlog bankruptcy: hundreds of overdue tasks become a shame pile. The app offers "archive everything older than
  N days" periodically.
- An evening ritual that turns into a second workday. Keep it optional and short, and allow skipping without
  penalty.

### G.5 Citations

- Ghibellini, R., & Meier, B. (2025). Interruption, recall and resumption: A meta-analysis of the Zeigarnik and Ovsiankina effects. *Humanities and Social Sciences Communications, 12*. https://doi.org/10.1057/s41599-025-05000-w
- Masicampo, E. J., & Baumeister, R. F. (2011). Consider it done! Plan making can eliminate the cognitive effects of unfulfilled goals. *Journal of Personality and Social Psychology, 101*(4), 667–683. https://doi.org/10.1037/a0024192
- Scullin, M. K., Krueger, M. L., Ballard, H. K., Pruett, N., & Bliwise, D. L. (2018). The effects of bedtime writing on difficulty falling asleep: A polysomnographic study comparing to-do lists and completed activity lists. *Journal of Experimental Psychology: General, 147*(1), 139–146. https://doi.org/10.1037/xge0000374
- Syrek, C. J., Weigelt, O., Peifer, C., & Antoni, C. H. (2017). Zeigarnik's sleepless nights: How unfinished tasks at the end of the week impair employee sleep on the weekend through rumination. *Journal of Occupational Health Psychology, 22*(2), 225–238. https://doi.org/10.1037/ocp0000031
- Zeigarnik, B. (1927). Das Behalten erledigter und unerledigter Handlungen. *Psychologische Forschung, 9*, 1–85. https://doi.org/10.1007/BF02409755 (published within K. Lewin's series "Untersuchungen zur Handlungs- und Affektpsychologie")

---

## H. Reward schedules, variable reinforcement, loot boxes, and gambling harms

### H.1 Key findings

- In operant conditioning, variable-ratio schedules (reward after an unpredictable number of responses) produce
  high, steady response rates that resist extinction (Ferster & Skinner, 1957). This is the core mechanic of slot
  machines.
- Near-misses (outcomes that look almost like a win) increase the motivation to keep gambling and recruit
  win-related brain circuitry (Clark et al., 2009). Ethnographic work describes gambling machines engineered to
  hold players in a continuous "zone" of play (Schüll, 2012).
- **Loot boxes.** Many loot-box implementations share structural and psychological features with gambling
  (Drummond & Sauer, 2018). In a survey of 7,422 gamers, spending on loot boxes was associated with
  problem-gambling severity (η² = 0.054), more strongly than spending on other in-game items (Zendle & Cairns,
  2018). A replication with a less self-selected sample (n = 1,172) found a similar association (η² = 0.051;
  Zendle & Cairns, 2019). Meta-analyses estimate the association at about r = 0.26–0.27 (Garea et al., 2021;
  Spicer et al., 2022). **Causal direction is unresolved**: loot boxes may act as a gateway, or people with
  gambling problems may be drawn to them.
- Randomness is not required for incentives to work. Lottery-based and deposit-contract incentives produced weight
  loss in a 16-week trial, but the gains were not sustained after the incentives ended (Volpp et al., 2008). In a
  step-count trial, a loss-framed incentive outperformed gain-framed and lottery incentives (Patel et al., 2016).
- Dark patterns are interface strategies that work against users' interests, such as nagging, obstruction,
  sneaking, interface interference, and forced action. Several overlap with reward-loop design (Gray et al., 2018).

### H.2 Evidence strength

- Variable-ratio schedules sustain responding: **Strong** (decades of operant research).
- Near-misses increase gambling motivation: **Moderate**.
- Loot-box spending is associated with problem gambling: **Moderate** (replicated, meta-analyzed, but
  correlational).
- That variable rewards in productivity apps cause harm: **Speculative**. We adopt a precautionary rule anyway,
  because the mechanism is the same, the benefit is unnecessary, and the population includes vulnerable users and
  minors.

### H.3 Design implications

- **All rewards are deterministic and documented.** An in-app "How growth works" page explains the XP rules,
  caps, and diminishing returns. The same input always yields the same output, and every grant is reproducible
  from the ledger.
- **No randomized rewards of any kind, paid or free.** No mystery chests, random drops, gacha, spin wheels,
  "chance to earn" bonuses, or daily login roulettes.
- **Cosmetic shop rules.** Items are bought directly at a listed price in local currency. There is no opaque premium
  currency, and if a currency is ever needed for platform reasons it converts at a fixed, displayed 1:1 rate. No
  randomized bundles, no countdown-timer scarcity, and a clear confirmation step on every purchase. Cosmetics never
  affect progression, attributes, Condition, Vigils, or guild outcomes.
- **Achievement codex.** Every achievement's criteria are listed. "Hidden" achievements are allowed only if they
  are deterministic, and their criteria are revealed once unlocked. This allows surprise without chance.
- **Proportionate celebrations.** No slot-machine animations, no "almost got the rare one" near-miss visuals, no
  escalating light-and-sound for streaks.
- **Surprise lives in narrative, not in rewards.** The Chronicle can be delightful and unexpected in *wording*.
  Reward magnitudes are never random.
- **No loss framing tied to inaction.** We do not adopt the loss-framed points that worked in Patel et al. (2016,
  2019). Attributes never decrease. Condition reflects recovery versus overexertion and is never reduced by missed
  tasks (PRD S4), so doing nothing never costs the user anything visible (Rules 1–2).

### H.4 Risks and anti-patterns

- Engagement-optimization creep: an A/B test shows a variable reward "wins" on DAU and quietly ships. Our rules
  forbid it regardless of test results.
- Premium-currency obfuscation, bundles, and whale targeting. Minors are a specific risk population.
- Daily login rewards and energy systems that train *opening the app* rather than doing real-world tasks.
- Monetizing streak repair. Rekindles are earned only.

### H.5 Citations

- Clark, L., Lawrence, A. J., Astley-Jones, F., & Gray, N. (2009). Gambling near-misses enhance motivation to gamble and recruit win-related brain circuitry. *Neuron, 61*(3), 481–490. https://doi.org/10.1016/j.neuron.2008.12.031
- Drummond, A., & Sauer, J. D. (2018). Video game loot boxes are psychologically akin to gambling. *Nature Human Behaviour, 2*(8), 530–532. https://doi.org/10.1038/s41562-018-0360-1
- Ferster, C. B., & Skinner, B. F. (1957). *Schedules of reinforcement*. Appleton-Century-Crofts.
- Garea, S. S., Drummond, A., Sauer, J. D., Hall, L. C., & Williams, M. N. (2021). Meta-analysis of the relationship between problem gambling, excessive gaming and loot box spending. *International Gambling Studies, 21*(3), 460–479. https://doi.org/10.1080/14459795.2021.1914705
- Gray, C. M., Kou, Y., Battles, B., Hoggatt, J., & Toombs, A. L. (2018). The dark (patterns) side of UX design. In *Proceedings of CHI 2018* (pp. 1–14). ACM. https://doi.org/10.1145/3173574.3174108
- Patel, M. S., Asch, D. A., Rosin, R., Small, D. S., et al. (2016). Framing financial incentives to increase physical activity among overweight and obese adults: A randomized, controlled trial. *Annals of Internal Medicine, 164*(6), 385–394. https://doi.org/10.7326/M15-1635
- Patel, M. S., et al. (2019). (See section E.)
- Schüll, N. D. (2012). *Addiction by design: Machine gambling in Las Vegas*. Princeton University Press.
- Spicer, S. G., Nicklin, L. L., Uther, M., Lloyd, J., Lloyd, H., & Close, J. (2022). Loot boxes, problem gambling and problem video gaming: A systematic review and meta-synthesis. *New Media & Society, 24*(4), 1001–1022. https://doi.org/10.1177/14614448211027175
- Volpp, K. G., John, L. K., Troxel, A. B., Norton, L., Fassbender, J., & Loewenstein, G. (2008). Financial incentive–based approaches for weight loss: A randomized trial. *JAMA, 300*(22), 2631–2637. https://doi.org/10.1001/jama.2008.804
- Zendle, D., & Cairns, P. (2018). Video game loot boxes are linked to problem gambling: Results of a large-scale survey. *PLOS ONE, 13*(11), e0206767. https://doi.org/10.1371/journal.pone.0206767
- Zendle, D., & Cairns, P. (2019). Loot boxes are again linked to problem gambling: Results of a replication study. *PLOS ONE, 14*(3), e0213194. https://doi.org/10.1371/journal.pone.0213194

---

## I. Cognitive load, choice overload, and decision fatigue

### I.1 Key findings

- **Cognitive load theory.** Working memory is sharply limited, and extraneous load imposed by presentation
  competes with the actual task (Sweller, 1988; Sweller, van Merriënboer & Paas, 2019). Working-memory capacity is
  often estimated at about four chunks (Cowan, 2001).
- **Choice overload is conditional, not general.** In the famous jam study, a 24-jam display drew more interest
  but far fewer purchases than a 6-jam display (Iyengar & Lepper, 2000). However, a meta-analysis of 63 conditions
  from 50 experiments (N = 5,036) found a mean effect of **virtually zero**, with large variance between studies
  (Scheibehenne, Greifeneder & Todd, 2010). A later meta-analysis identified when overload *does* occur: complex
  choice sets, difficult decision tasks, uncertain preferences, and a goal of minimizing effort (Chernev,
  Böckenholt & Goodman, 2015).
- **Defaults** strongly shape choices, with a medium average effect and large heterogeneity (Jachimowicz et al.,
  2019).
- **Ego depletion and decision fatigue: replication problems.** The resource model of self-control (Baumeister et
  al., 1998) and its extension to decision-making (Vohs et al., 2008) were influential. A preregistered 23-lab
  replication (N = 2,141) found d = 0.04, 95% CI [−0.07, 0.15] (Hagger et al., 2016). A 36-lab preregistered test
  (N = 3,531) found a nonsignificant d = 0.06 (Vohs et al., 2021). Bias-corrected meta-analytic estimates are near
  zero (Carter et al., 2015). The well-known "hungry judges" parole finding (Danziger, Levav & Avnaim-Pesso, 2011)
  has been challenged on confounds in case ordering (Weinshall-Margel & Shapard, 2011).
- **Notifications cost attention.** In a within-subject experiment, a week with notifications on produced more
  inattention and hyperactivity symptoms than a week with them minimized (Kushlev, Proulx & Dunn, 2016). A day
  without notifications left people less distracted but more anxious about missing information (Pielot & Rello,
  2017). In a micro-randomized trial, contextually tailored activity suggestions raised short-term step counts,
  but the **effect diminished over the study period** (Klasnja et al., 2019). Just-in-time adaptive intervention
  design recommends delivering support only when the user both needs it and is receptive (Nahum-Shani et al.,
  2018).

### I.2 Evidence strength

- Working-memory limits and extraneous load: **Strong**.
- Choice overload as a general rule: **Weak**. Conditional overload under the Chernev moderators: **Moderate**.
- Defaults: **Strong** for direction, heterogeneous in size.
- Ego depletion as a limited resource: **Weak**, with failed large preregistered replications. **Do not justify
  features with it.** Decision fatigue as popularly described: **Weak / contested**.
- Notification burden and habituation to prompts: **Moderate** (experiments and an MRT, small to medium samples).

### I.3 Design implications

- **Today view shows at most 5 quests above the fold**, in the user's own planned order, with "show all" below.
- **Daily Briefing suggests at most 3 quests per day.** Each has a one-line reason and one-tap accept or skip.
  Skipping has no consequence and is not recorded as a miss.
- **Progressive disclosure in quest creation.** Title first. The AI proposes the attribute mapping. Oath,
  difficulty, recurrence, and reminders sit behind "more options".
- **Curated defaults and templates.** Each category shows at most about 7 templates at once, with search. Sensible
  recurrence defaults are pre-selected. Reminders are off unless the user sets one, and an Oath cue is suggested
  instead (section D).
- **Notification budget, two tiers.** (1) *Motivational nudges* the app initiates on its own (Daily Briefing,
  Evening Reflection, suggestions, re-engagement): at most 2 per day. (2) *All non-reminder notifications*,
  including batched guild reactions and comments: at most 5 per day, the PRD N3 default. User-scheduled reminders
  count toward neither cap but follow quiet hours. Default quiet hours are 22:00–08:00 local time (PRD N2), and
  nothing app-initiated is sent inside them. Each category has its own toggle.
- **Receptivity over volume.** The Daily Briefing arrives at a user-chosen time. If it is ignored on several
  consecutive days, its frequency automatically drops (for example to every other day) and the user is told why.
  This responds to the habituation seen in Klasnja et al. (2019).
- **No pseudo-science copy.** Never "do hard things first because willpower runs out", and never "decision fatigue"
  claims. Scheduling advice is framed around the user's own patterns ("you complete more in the morning").
- **Keep the economy small.** Six attributes and one XP type, no secondary currencies, and no stats beyond what
  users can explain back to us in testing.

### I.4 Risks and anti-patterns

- Feature creep: every new mechanic adds extraneous load.
- Settings overload that pushes decisions onto users. Use good defaults and keep everything reversible.
- Notification fatigue leading to notifications being disabled or the app uninstalled, which also cuts off useful
  reminders.
- Grounding product rationale in ego depletion, which damages credibility with expert users and reviewers.

### I.5 Citations

- Baumeister, R. F., Bratslavsky, E., Muraven, M., & Tice, D. M. (1998). Ego depletion: Is the active self a limited resource? *Journal of Personality and Social Psychology, 74*(5), 1252–1265. https://doi.org/10.1037/0022-3514.74.5.1252
- Carter, E. C., Kofler, L. M., Forster, D. E., & McCullough, M. E. (2015). A series of meta-analytic tests of the depletion effect: Self-control does not seem to rely on a limited resource. *Journal of Experimental Psychology: General, 144*(4), 796–815. https://doi.org/10.1037/xge0000083
- Chernev, A., Böckenholt, U., & Goodman, J. (2015). Choice overload: A conceptual review and meta-analysis. *Journal of Consumer Psychology, 25*(2), 333–358. https://doi.org/10.1016/j.jcps.2014.08.002
- Cowan, N. (2001). The magical number 4 in short-term memory: A reconsideration of mental storage capacity. *Behavioral and Brain Sciences, 24*(1), 87–114. https://doi.org/10.1017/S0140525X01003922
- Danziger, S., Levav, J., & Avnaim-Pesso, L. (2011). Extraneous factors in judicial decisions. *Proceedings of the National Academy of Sciences, 108*(17), 6889–6892. https://doi.org/10.1073/pnas.1018033108
- Hagger, M. S., Chatzisarantis, N. L. D., Alberts, H., et al. (2016). A multilab preregistered replication of the ego-depletion effect. *Perspectives on Psychological Science, 11*(4), 546–573. https://doi.org/10.1177/1745691616652873
- Iyengar, S. S., & Lepper, M. R. (2000). When choice is demotivating: Can one desire too much of a good thing? *Journal of Personality and Social Psychology, 79*(6), 995–1006. https://doi.org/10.1037/0022-3514.79.6.995
- Jachimowicz, J. M., Duncan, S., Weber, E. U., & Johnson, E. J. (2019). When and why defaults influence decisions: A meta-analysis of default effects. *Behavioural Public Policy, 3*(2), 159–186. https://doi.org/10.1017/bpp.2018.43
- Klasnja, P., Smith, S., Seewald, N. J., Lee, A., Hall, K., Luers, B., Hekler, E. B., & Murphy, S. A. (2019). Efficacy of contextually tailored suggestions for physical activity: A micro-randomized optimization trial of HeartSteps. *Annals of Behavioral Medicine, 53*(6), 573–582. https://doi.org/10.1093/abm/kay067
- Kushlev, K., Proulx, J., & Dunn, E. W. (2016). "Silence your phones": Smartphone notifications increase inattention and hyperactivity symptoms. In *Proceedings of CHI 2016* (pp. 1011–1020). ACM. https://doi.org/10.1145/2858036.2858359
- Nahum-Shani, I., Smith, S. N., Spring, B. J., Collins, L. M., Witkiewitz, K., Tewari, A., & Murphy, S. A. (2018). Just-in-time adaptive interventions (JITAIs) in mobile health: Key components and design principles for ongoing health behavior support. *Annals of Behavioral Medicine, 52*(6), 446–462. https://doi.org/10.1007/s12160-016-9830-8
- Pielot, M., & Rello, L. (2017). Productive, anxious, lonely: 24 hours without push notifications. In *Proceedings of MobileHCI 2017* (pp. 1–11). ACM. https://doi.org/10.1145/3098279.3098526
- Scheibehenne, B., Greifeneder, R., & Todd, P. M. (2010). Can there ever be too many options? A meta-analytic review of choice overload. *Journal of Consumer Research, 37*(3), 409–425. https://doi.org/10.1086/651235
- Sweller, J. (1988). Cognitive load during problem solving: Effects on learning. *Cognitive Science, 12*(2), 257–285. https://doi.org/10.1207/s15516709cog1202_4
- Sweller, J., van Merriënboer, J. J. G., & Paas, F. (2019). Cognitive architecture and instructional design: 20 years later. *Educational Psychology Review, 31*(2), 261–292. https://doi.org/10.1007/s10648-019-09465-5
- Vohs, K. D., Baumeister, R. F., Schmeichel, B. J., Twenge, J. M., Nelson, N. M., & Tice, D. M. (2008). Making choices impairs subsequent self-control: A limited-resource account of decision making, self-regulation, and active initiative. *Journal of Personality and Social Psychology, 94*(5), 883–898. https://doi.org/10.1037/0022-3514.94.5.883
- Vohs, K. D., Schmeichel, B. J., Lohmann, S., Gronau, Q. F., et al. (2021). A multisite preregistered paradigmatic test of the ego-depletion effect. *Psychological Science, 32*(10), 1566–1581. https://doi.org/10.1177/0956797621989733
- Weinshall-Margel, K., & Shapard, J. (2011). Overlooked factors in the analysis of parole decisions. *Proceedings of the National Academy of Sciences, 108*(42), E833. https://doi.org/10.1073/pnas.1110910108

---

## J. Self-efficacy, attribution, and growth mindset

### J.1 Key findings

- **Self-efficacy** is the belief that one can carry out the actions a situation requires. It draws on four
  sources: mastery experiences (the most powerful), vicarious experience (seeing similar others succeed), verbal
  persuasion, and physiological or affective states (Bandura, 1977).
- Self-efficacy correlates with work performance (r ≈ 0.38 across 114 studies; Stajkovic & Luthans, 1998).
- In physical-activity interventions, the average effect on self-efficacy was small (d = 0.16). Techniques
  providing **feedback on past performance or on others' performance**, and **vicarious experience**, were
  associated with higher self-efficacy. Persuasion, graded mastery, and barrier identification were associated
  with *lower* self-efficacy (Ashford, Edmunds & French, 2010).
- **Within-person caveat.** Within individuals over time, self-efficacy looks more like a *product* of past
  performance than a driver of future performance (Sitzmann & Yeo, 2013). Some experiments find that raising
  self-efficacy can *reduce* effort on the next attempt through overconfidence (Vancouver et al., 2002). Bandura &
  Locke (2003) dispute the generality of this.
- **Attribution theory.** How people explain outcomes along three dimensions (internal or external, stable or
  unstable, controllable or uncontrollable) shapes expectancy and emotion. Attributing failure to stable,
  uncontrollable causes ("I lack ability") lowers future expectancy. Attributing it to unstable, controllable causes
  (effort, strategy, timing) preserves it (Weiner, 1985).
- **Growth mindset.** Praising intelligence rather than effort undermined children's persistence after failure
  in the original studies (Mueller & Dweck, 1998), but a close replication found no effect on the motivation and
  attribution measures (Li & Bates, 2019). Meta-analyses find a weak mindset–achievement association (r ≈ 0.10) and
  very small intervention effects (d ≈ 0.08) (Sisk et al., 2018). A large national experiment found small benefits
  concentrated among lower-achieving students (Yeager et al., 2019). Two 2023 meta-analyses disagree. One finds a
  small effect (d ≈ 0.05) that is not significant after bias correction (Macnamara & Burgoyne, 2023). The other
  finds modest effects (d ≈ 0.14) in targeted, high-fidelity subgroups with wide heterogeneity (Burnette et al.,
  2023).

### J.2 Evidence strength

- Self-efficacy is associated with performance: **Strong** (between-person).
- Self-efficacy causally drives within-person performance: **Moderate / contested**.
- Feedback on performance and vicarious experience raise self-efficacy: **Moderate**.
- Attribution dimensions shape expectancy and motivation: **Moderate**.
- Growth-mindset interventions improve outcomes: **Weak to Emerging** (small, contested effects). Mueller & Dweck
  (1998) praise effect: **contested** (failed close replication).

### J.3 Design implications

- **First-week mastery ladder.** The first quests suggested at onboarding are completable in 10 minutes or less,
  and Level 2 is reachable within the first few days of normal use. Mastery experience comes first.
- **Growth Receipts cite the user's own past performance.** "Third week in a row with 4+ runs" is feedback on past
  performance, the strongest self-efficacy technique in Ashford et al. (2010).
- **Guild Tales (vicarious experience).** Opt-in short stories from guildmates about getting past a specific
  obstacle, matched to the reader's current activity level (near-peer, per Lockwood & Kunda, 1997).
- **Attribution rules for all AI copy (Chronicles, Briefings, Receipts):**
  - Successes are attributed to effort, strategy, and choices ("you scheduled it right after work").
  - Setbacks are attributed to unstable, controllable, situational factors, plus a plan adjustment ("evenings
    were packed this week; want a morning Ember version?").
  - Never attribute outcomes to fixed ability or character ("you're not a morning person", "you're lazy", "you're
    a natural").
- **No "growth mindset module."** We use process-focused language throughout, but we do not market or build a
  mindset intervention. The effect sizes do not justify it.
- **Calibration rather than hype.** If a new target is more than about 2× the user's recent average, the app offers
  a stepping-stone target. Heroic difficulty is suggested only after sustained success at Standard, which guards
  against both under-challenge and the overconfidence pattern in Vancouver et al. (2002).
- **Emergent classes describe recent behavior, not identity.** Class labels are framed as "your recent path" and
  change as behavior changes. They never gate content and are never framed as innate aptitude.

### J.4 Risks and anti-patterns

- Empty persuasion ("You've got this!") without mastery behind it. Persuasion alone was associated with *lower*
  self-efficacy in Ashford et al. (2010).
- Fixed labels via classes or titles ("The Undisciplined"). Titles are only ever earned for things done.
- Inflated XP or levels that produce false confidence, then disappointment.
- Over-claiming mindset science in marketing or onboarding copy.

### J.5 Citations

- Ashford, S., Edmunds, J., & French, D. P. (2010). What is the best way to change self-efficacy to promote lifestyle and recreational physical activity? A systematic review with meta-analysis. *British Journal of Health Psychology, 15*(2), 265–288. https://doi.org/10.1348/135910709X461752
- Bandura, A. (1977). Self-efficacy: Toward a unifying theory of behavioral change. *Psychological Review, 84*(2), 191–215. https://doi.org/10.1037/0033-295X.84.2.191
- Bandura, A., & Locke, E. A. (2003). Negative self-efficacy and goal effects revisited. *Journal of Applied Psychology, 88*(1), 87–99. https://doi.org/10.1037/0021-9010.88.1.87
- Burnette, J. L., Billingsley, J., Banks, G. C., Knouse, L. E., Hoyt, C. L., Pollack, J. M., & Simon, S. (2023). A systematic review and meta-analysis of growth mindset interventions: For whom, how, and why might such interventions work? *Psychological Bulletin, 149*(3–4), 174–205. https://doi.org/10.1037/bul0000368
- Li, Y., & Bates, T. C. (2019). You can't change your basic ability, but you work at things, and that's how we get hard things done: Testing the role of growth mindset on response to setbacks, educational attainment, and cognitive ability. *Journal of Experimental Psychology: General, 148*(9), 1640–1655. https://doi.org/10.1037/xge0000669
- Macnamara, B. N., & Burgoyne, A. P. (2023). Do growth mindset interventions impact students' academic achievement? A systematic review and meta-analysis with recommendations for best practices. *Psychological Bulletin, 149*(3–4), 133–173. https://doi.org/10.1037/bul0000352
- Mueller, C. M., & Dweck, C. S. (1998). Praise for intelligence can undermine children's motivation and performance. *Journal of Personality and Social Psychology, 75*(1), 33–52. https://doi.org/10.1037/0022-3514.75.1.33
- Sisk, V. F., Burgoyne, A. P., Sun, J., Butler, J. L., & Macnamara, B. N. (2018). To what extent and under which circumstances are growth mind-sets important to academic achievement? Two meta-analyses. *Psychological Science, 29*(4), 549–571. https://doi.org/10.1177/0956797617739704
- Sitzmann, T., & Yeo, G. (2013). A meta-analytic investigation of the within-person self-efficacy domain: Is self-efficacy a product of past performance or a driver of future performance? *Personnel Psychology, 66*(3), 531–568. https://doi.org/10.1111/peps.12035
- Stajkovic, A. D., & Luthans, F. (1998). Self-efficacy and work-related performance: A meta-analysis. *Psychological Bulletin, 124*(2), 240–261. https://doi.org/10.1037/0033-2909.124.2.240
- Vancouver, J. B., Thompson, C. M., Tischner, E. C., & Putka, D. J. (2002). Two studies examining the negative effect of self-efficacy on performance. *Journal of Applied Psychology, 87*(3), 506–516. https://doi.org/10.1037/0021-9010.87.3.506
- Weiner, B. (1985). An attributional theory of achievement motivation and emotion. *Psychological Review, 92*(4), 548–573. https://doi.org/10.1037/0033-295X.92.4.548
- Yeager, D. S., Hanselman, P., Walton, G. M., Murray, J. S., et al. (2019). A national experiment reveals where a growth mindset improves achievement. *Nature, 573*(7774), 364–369. https://doi.org/10.1038/s41586-019-1466-y

---

## K. Self-compassion, relapse, the "what-the-hell" effect, and the fresh-start effect

### K.1 Key findings

- **Self-compassion** has three components: self-kindness instead of self-judgment, a sense of common humanity
  instead of isolation, and mindful awareness instead of over-identification with painful thoughts (Neff, 2003).
- Self-compassion is not complacency. In four experiments, self-compassion after a failure, transgression, or
  weakness *increased* motivation to improve, for example more time studying for a retest after failing (Breines &
  Chen, 2012). Self-compassion buffers negative reactions to unpleasant self-relevant events (Leary et al., 2007).
  Among restrictive eaters, a self-compassion induction reduced eating after a diet-breaking "preload" (Adams &
  Leary, 2007). Students who forgave themselves for procrastinating before a first exam procrastinated less before
  the next one (Wohl, Pychyl & Bennett, 2010). A meta-analysis of 27 RCTs found self-compassion interventions
  improved self-criticism, rumination, stress, depression, and anxiety, with moderate effects (Ferrari et al.,
  2019).
- **"What-the-hell" / abstinence-violation effects.** Restrained eaters who believed they had already broken their
  diet often ate *more*, not less (Polivy & Herman, 1985). Cochran & Tesser (1996) named the "what the hell" effect:
  once a goal feels blown, people abandon it for the rest of the period. In addiction, a single lapse framed as
  total failure tends to escalate into relapse (abstinence violation effect; Marlatt & Gordon, 1985).
  Over-ambitious self-change goals produce repeated cycles of failure and renewed false hope (Polivy & Herman,
  2002).
- **Fresh-start effect.** Temporal landmarks such as the start of a week, month, or year, birthdays, and holidays
  are followed by more aspirational behavior: searches for "diet", gym visits, commitment contracts (Dai, Milkman
  & Riis, 2014). Landmarks help most when framed as new beginnings that separate the person from past
  imperfections (Dai, Milkman & Riis, 2015). In a field experiment (N = 6,082), framing a future savings increase
  around a fresh-start date (such as a birthday or the first day of spring) increased contributions (Beshears et
  al., 2021). The flip side: anticipating an *upcoming* landmark reduces persistence on a goal already underway,
  and reminders of consistent everyday actions mitigate this (Koo et al., 2020).
- **Making returns easy.** In an exercise megastudy (61,293 gym members, 54 four-week interventions), 45% of
  interventions significantly increased weekly visits, by 9–27%. The top performer gave small rewards for
  *returning after a missed workout*. Few effects persisted after the program, and forecasters could not predict
  the winners (Milkman et al., 2021). Repairable streaks soften the drop-off after a break (Silverman & Barasch,
  2023; section D).

### K.2 Evidence strength

- Self-compassion improves well-being outcomes: **Moderate** (meta-analysis of RCTs, heterogeneous).
- Self-compassion improves *motivation and behavior* after setbacks: **Moderate to Emerging** (several small
  experiments; independent large replications are lacking).
- What-the-hell / abstinence-violation effects: **Moderate** (mostly the dieting and addiction literature, lab
  paradigms).
- Fresh-start effect on goal initiation: **Moderate** (large observational data plus field experiments, largely
  from one research network).
- Anticipated landmarks undermine ongoing effort: **Emerging**.
- Rewarding returns after lapses: **Moderate** for the megastudy method, **Emerging** for that specific
  intervention (one setting, monetary micro-rewards, four weeks).

### K.3 Design implications

- **Missed-day copy follows the three components:** acknowledge (mindfulness), normalize (common humanity), then
  offer a kind, concrete next step (self-kindness). Example: "Yesterday didn't go to plan. That happens on every
  long road. Want to pick up with the Ember version today?" All templates are reviewed in both EN and FA by
  native speakers for tone.
- **No all-or-nothing days.** Every recurring quest has an Ember version. The AI evaluator can grant proportional
  XP for partial completion. Weekly Vigil targets absorb individual misses (section D).
- **"Salvage" prompt.** If a planned morning quest is missed, the Daily Briefing (or one in-app card, not a push)
  may offer a smaller version later that day. It is offered at most once.
- **Rekindle return flow (extends PRD S5 and journey J5).** After 3 or more days of inactivity, the next app open
  shows:
  1. "Nothing has been lost" (true: attributes are permanent). The PRD's "Your journey hasn't been erased" card
     says the same thing.
  2. One suggested small (Ember) quest, plus an option to start a **New Chapter**: archive overdue items in one tap
     and choose up to 3 quests to restart.
  3. A fixed, capped **Return recognition**: a small deterministic XP bonus on the first completed quest after a
     lapse of 3+ days, at most once per 14 days. This is inspired by Milkman et al. (2021), and the size and cap
     are design assumptions to test for gaming.
- **New Chapter at landmarks, never as postponement.** It is offered *at or just after* locale-aware landmarks:
  week start (for example Saturday in the `fa-IR` locale, Monday elsewhere), the first of the month (Gregorian or
  Solar Hijri per user setting), Nowruz, January 1 where relevant, and the user's birthday (opt-in). The app never
  suggests "start next Monday". Following Koo et al. (2020), approaching landmarks are paired with reminders of
  the user's ongoing routines rather than "fresh start soon".
- **Gentle re-engagement.** At most two messages per lapse (around day 3 and day 10), then silence until the user
  returns. If the user opted in, a monthly digest may follow. No loss framing ("you'll lose your…"), no guilt, no
  sad mascot.
- **Rough-day chip.** Evening Reflection offers optional self-report chips ("good day", "ordinary", "rough day"). If
  the user picks "rough day", the reflection offers a self-compassion prompt and suggests lighter Ember quests
  for tomorrow. The AI responds only to what the user explicitly selected or wrote. It never infers mood (see
  Rule 7).
- **Rest is legitimate.** Logging a rest day restores Condition. Rest days built into Vigils are never framed as
  failures.

### K.4 Risks and anti-patterns

- Misreading self-compassion as "anything goes". Pair kindness with a concrete next step, and keep the Weekly
  Review honest about gaps.
- Fresh starts turning into a procrastination ritual or a false-hope cycle. Unsolicited New Chapter prompts are
  limited to one per month.
- Comeback rewards incentivizing deliberate lapses. Cap and monitor them, and remove the reward if gaming shows up.
- Toxic positivity, and copy whose cheerfulness clashes with the dark-fantasy tone. Aim for warmth that is sober,
  not chirpy.
- Treating relapse as a moral event. Copy never uses "failed", "broken", or "dead streak".

### K.5 Citations

- Adams, C. E., & Leary, M. R. (2007). Promoting self-compassionate attitudes toward eating among restrictive and guilty eaters. *Journal of Social and Clinical Psychology, 26*(10), 1120–1144. https://doi.org/10.1521/jscp.2007.26.10.1120
- Beshears, J., Dai, H., Milkman, K. L., & Benartzi, S. (2021). Using fresh starts to nudge increased retirement savings. *Organizational Behavior and Human Decision Processes, 167*, 72–87. https://doi.org/10.1016/j.obhdp.2021.06.005
- Breines, J. G., & Chen, S. (2012). Self-compassion increases self-improvement motivation. *Personality and Social Psychology Bulletin, 38*(9), 1133–1143. https://doi.org/10.1177/0146167212445599
- Cochran, W., & Tesser, A. (1996). The "what the hell" effect: Some effects of goal proximity and goal framing on performance. In L. L. Martin & A. Tesser (Eds.), *Striving and feeling: Interactions among goals, affect, and self-regulation*. Lawrence Erlbaum Associates.
- Dai, H., Milkman, K. L., & Riis, J. (2014). The fresh start effect: Temporal landmarks motivate aspirational behavior. *Management Science, 60*(10), 2563–2582. https://doi.org/10.1287/mnsc.2014.1901
- Dai, H., Milkman, K. L., & Riis, J. (2015). Put your imperfections behind you: Temporal landmarks spur goal initiation when they signal new beginnings. *Psychological Science, 26*(12), 1927–1936. https://doi.org/10.1177/0956797615605818
- Ferrari, M., Hunt, C., Harrysunker, A., Abbott, M. J., Beath, A. P., & Einstein, D. A. (2019). Self-compassion interventions and psychosocial outcomes: A meta-analysis of RCTs. *Mindfulness, 10*(8), 1455–1473. https://doi.org/10.1007/s12671-019-01134-6
- Koo, M., Dai, H., Mai, K. M., & Song, C. E. (2020). Anticipated temporal landmarks undermine motivation for continued goal pursuit. *Organizational Behavior and Human Decision Processes, 161*, 142–157. https://doi.org/10.1016/j.obhdp.2020.06.002
- Leary, M. R., Tate, E. B., Adams, C. E., Batts Allen, A., & Hancock, J. (2007). Self-compassion and reactions to unpleasant self-relevant events: The implications of treating oneself kindly. *Journal of Personality and Social Psychology, 92*(5), 887–904. https://doi.org/10.1037/0022-3514.92.5.887
- Marlatt, G. A., & Gordon, J. R. (Eds.). (1985). *Relapse prevention: Maintenance strategies in the treatment of addictive behaviors*. Guilford Press.
- Milkman, K. L., Gromet, D., Ho, H., Kay, J. S., et al. (2021). Megastudies improve the impact of applied behavioural science. *Nature, 600*(7889), 478–483. https://doi.org/10.1038/s41586-021-04128-4
- Neff, K. D. (2003). Self-compassion: An alternative conceptualization of a healthy attitude toward oneself. *Self and Identity, 2*(2), 85–101. https://doi.org/10.1080/15298860309032
- Polivy, J., & Herman, C. P. (1985). Dieting and binging: A causal analysis. *American Psychologist, 40*(2), 193–201. https://doi.org/10.1037/0003-066X.40.2.193
- Polivy, J., & Herman, C. P. (2002). If at first you don't succeed: False hopes of self-change. *American Psychologist, 57*(9), 677–689. https://doi.org/10.1037/0003-066X.57.9.677
- Silverman, J., & Barasch, A. (2023). (See section D.)
- Wohl, M. J. A., Pychyl, T. A., & Bennett, S. H. (2010). I forgive myself, now I can study: How self-forgiveness for procrastinating can reduce future procrastination. *Personality and Individual Differences, 48*(7), 803–808. https://doi.org/10.1016/j.paid.2010.01.029

---

## L. What gamification meta-analyses tell us

### L.1 Key findings

- Gamification means using game-design elements in non-game contexts (Deterding et al., 2011).
- An early review of 24 empirical studies found mostly positive effects, but they depended heavily on context and
  on the users. Many studies had small samples, no control group, or were vulnerable to novelty effects (Hamari,
  Koivisto & Sarsa, 2014).
- A later review covered 819 studies, analyzing 273 empirical ones in depth. Results leaned positive, but with a
  "remarkable" share of mixed results (Koivisto & Hamari, 2019).
- In education, a meta-analysis found small-to-medium effects on cognitive (g = 0.49), motivational (g = 0.36),
  and behavioral (g = 0.25) outcomes. Only the cognitive effect held up among methodologically rigorous studies.
  **Game fiction and social interaction** moderated behavioral outcomes, and combining competition with
  collaboration performed well (Sailer & Homner, 2020).
- For physical activity, a meta-analysis of 16 RCTs (N = 2,407) found a small-to-medium effect (g = 0.42), about
  1,600 extra steps per day. The effect persisted after the programs ended but was small long-term (Mazeas et al.,
  2022). A systematic review of health and well-being gamification found mostly positive effects, strongest for
  health behaviors, with generally modest study quality (Johnson et al., 2016).
- **Individual elements.** Points, levels, and leaderboards increased task *output*, but not intrinsic motivation
  or competence satisfaction (Mekler et al., 2017). Badges, leaderboards, and performance graphs increased
  competence need satisfaction. Avatars, meaningful stories, and teammates increased social relatedness (Sailer et
  al., 2017). In a 16-week classroom study, a course with leaderboards and badges *lowered* intrinsic motivation,
  satisfaction, and final exam scores compared with the same course without them (Hanus & Fox, 2015).

### L.2 Evidence strength

**Moderate.** Average effects are small to moderate and heterogeneous. Expect novelty decay and publication bias.
Long-term RCTs are rare, and specific elements can harm.

### L.3 Design implications

- **Game elements are feedback and meaning, not the main incentive.** The character sheet, Chronicle, and guilds
  carry the motivation. XP is the record, not the carrot (section A).
- **Invest in game fiction and social interaction**, the moderators that matter: a narrative Chronicle grounded in
  real data, guild Undertakings, and cooperative structures with optional, bounded competition.
- **No badge spam.** Achievements mark meaningful milestones (first Mastered Rite, a year of Vigils), not trivia like
  "opened the app 10 times".
- **Plan for novelty decay.** Success metrics are evaluated at 4, 12, and 26 weeks. A feature must show benefit
  beyond week 4 to stay (Milkman et al., 2021).
- **Measure outcomes users care about**: goal attainment, habit automaticity (SRBAI-style), need satisfaction,
  and well-being, alongside retention. DAU alone is never a success metric.

### L.4 Risks and anti-patterns

- "Pointsification": bolting points onto tasks and calling it motivation.
- Assuming more elements means more effect. Each element should earn its place.
- Leaderboard-centric designs (Hanus & Fox, 2015).
- Optimizing for short trials, which shows novelty rather than durable change.

### L.5 Citations

- Deterding, S., Dixon, D., Khaled, R., & Nacke, L. (2011). From game design elements to gamefulness: Defining "gamification". In *Proceedings of the 15th International Academic MindTrek Conference* (pp. 9–15). ACM. https://doi.org/10.1145/2181037.2181040
- Hamari, J., Koivisto, J., & Sarsa, H. (2014). Does gamification work? — A literature review of empirical studies on gamification. In *Proceedings of the 47th Hawaii International Conference on System Sciences* (pp. 3025–3034). IEEE. https://doi.org/10.1109/HICSS.2014.377
- Hanus, M. D., & Fox, J. (2015). Assessing the effects of gamification in the classroom: A longitudinal study on intrinsic motivation, social comparison, satisfaction, effort, and academic performance. *Computers & Education, 80*, 152–161. https://doi.org/10.1016/j.compedu.2014.08.019
- Johnson, D., Deterding, S., Kuhn, K.-A., Staneva, A., Stoyanov, S., & Hides, L. (2016). Gamification for health and wellbeing: A systematic review of the literature. *Internet Interventions, 6*, 89–106. https://doi.org/10.1016/j.invent.2016.10.002
- Koivisto, J., & Hamari, J. (2019). The rise of motivational information systems: A review of gamification research. *International Journal of Information Management, 45*, 191–210. https://doi.org/10.1016/j.ijinfomgt.2018.10.013
- Mazeas, A., Duclos, M., Pereira, B., & Chalabaev, A. (2022). Evaluating the effectiveness of gamification on physical activity: Systematic review and meta-analysis of randomized controlled trials. *Journal of Medical Internet Research, 24*(1), e26779. https://doi.org/10.2196/26779
- Mekler, E. D., Brühlmann, F., Tuch, A. N., & Opwis, K. (2017). Towards understanding the effects of individual gamification elements on intrinsic motivation and performance. *Computers in Human Behavior, 71*, 525–534. https://doi.org/10.1016/j.chb.2015.08.048
- Sailer, M., Hense, J. U., Mayr, S. K., & Mandl, H. (2017). How gamification motivates: An experimental study of the effects of specific game design elements on psychological need satisfaction. *Computers in Human Behavior, 69*, 371–380. https://doi.org/10.1016/j.chb.2016.12.033
- Sailer, M., & Homner, L. (2020). The gamification of learning: A meta-analysis. *Educational Psychology Review, 32*(1), 77–112. https://doi.org/10.1007/s10648-019-09498-w

---

## M. The motivational pull of games

### M.1 Key findings

- Across four studies, perceived **autonomy, competence, and relatedness** during play each predicted game
  enjoyment, preference, and intention for future play, and need satisfaction during play was associated with
  short-term changes in well-being (Ryan, Rigby & Przybylski, 2006). This work introduced the Player Experience of
  Need Satisfaction (PENS) perspective: games are compelling mainly because they satisfy basic needs, not because
  of rewards as such.
- A follow-up model distinguishes healthy, need-satisfying engagement from obsessive engagement. The latter is
  more likely when needs are poorly met in the rest of the player's life (Przybylski, Rigby & Ryan, 2010).

### M.2 Evidence strength

**Moderate.** The evidence is consistent but comes mostly from correlational and short experimental studies of
entertainment games, not productivity apps.

### M.3 Design implications

- **Autonomy:** meaningful choices. The user authors quests, decides which attributes to emphasize, gets an
  emergent class that reflects their behavior rather than a locked-in class pick, and has cosmetic
  self-expression.
- **Competence:** clear, immediate, accurate feedback (Growth Receipts), calibrated challenge (difficulty dial),
  and visible mastery (titles, Mastered Rites).
- **Relatedness:** guilds, shared Chronicle moments, cooperative Undertakings, and Commendations.
- **The Oath metaphor supports identified regulation.** The fiction frames commitments as chosen vows, not
  assignments.
- **No compulsion scaffolding:** no energy or stamina systems, no timers that force return visits, no daily login
  rewards. The game loop closes in the *real world* (doing the task), not in the app.

### M.4 Risks and anti-patterns

- The app becomes the activity: time spent customizing, scrolling the feed, or reading Chronicles crowds out real
  tasks. Monitor app time against completed real-world tasks.
- Obsessive engagement in users whose needs are unmet elsewhere. Avoid mechanics that reward app time itself.
- A dark-fantasy tone that drifts into bleakness and conflicts with self-compassion.

### M.5 Citations

- Przybylski, A. K., Rigby, C. S., & Ryan, R. M. (2010). A motivational model of video game engagement. *Review of General Psychology, 14*(2), 154–166. https://doi.org/10.1037/a0019440
- Ryan, R. M., Rigby, C. S., & Przybylski, A. (2006). The motivational pull of video games: A self-determination theory approach. *Motivation and Emotion, 30*(4), 344–360. https://doi.org/10.1007/s11031-006-9051-8

---

## N. Cross-cutting tensions and how we resolve them

| Tension | What the evidence says | Our resolution |
| --- | --- | --- |
| XP visibility vs undermining | Visible, contingent rewards can undermine interest (A). Visible progress drives effort (B, F). | Show progress bars, not price tags. Exact XP appears post-completion. Users can turn on previews, use unscored logging, or use Quiet mode. |
| Competition works vs comparison harms | Competition raised activity in RCTs (E). Leaderboards lowered motivation in class (L). Upward comparison deflates (E). | Competition only as opt-in, near-peer, time-boxed, consistency-based Rivalry. No global boards. |
| Loss framing works vs permanent character | Loss-framed points beat gain-framed incentives in trials (H). | No loss tied to inaction. Attributes never decrease, and Condition tracks overexertion and recovery, not misses (Rules 1–2). |
| Streaks motivate vs streak terror | Intact streaks sustain behavior, broken ones cause drop-off (D). | Weekly Vigils with rest days and earned repair. Lifetime totals never reset. |
| Comeback rewards vs gaming the system | Rewarding returns was the top megastudy intervention (K). | A small deterministic bonus, capped at once per 14 days and monitored. |
| Fresh starts vs procrastination | Past landmarks spur initiation. Anticipated ones undercut ongoing effort (K). | Offer New Chapters at or after landmarks, never "start next week". |
| Public commitment helps vs identity backfire | Public reporting amplifies effects (E, F). Noticed identity intentions reduced action (E). | Share completed actions and concrete plans, not identity claims. |
| Reminders help repetition vs dependence | Reminders aid repetition but can hinder automaticity (D). | Cue-based Oaths by default. Reminders optional, and reduced as habits graduate. |

---

## Design principles summary

| # | Principle | Product features | Evidence strength |
| --- | --- | --- | --- |
| 1 | Rewards inform; they do not pay | Growth Receipt; attribute icons instead of XP price tags; unscored logging; published XP rules; diminishing returns | Strong (undermining effect); application to XP is a design assumption |
| 2 | Protect autonomy | User-authored quests; ≤3 optional AI suggestions/day; Petition; optional motivation profile; autonomy-supportive copy lint | Strong (SDT); Moderate (digital SDT interventions) |
| 3 | Honest, always-near progress markers | Absolute XP bar; Waypoints; to-date/to-go switch; interstitial titles; no fake near-misses | Moderate |
| 4 | Specific goals with if-then plans | Action-shaped quests; Oath clause; obstacle clause; difficulty dial; learning goals; cap of 3 active objectives | Strong (direction; magnitude likely inflated) |
| 5 | Context-cued repetition over streak pressure | Cue field; Habit Strength meter; SRBAI-style check-in; weekly Vigil with rest days; Mastered Rite graduation; New Season prompt | Moderate (model); Emerging (timing, missed days) |
| 6 | Lapses are normal and cheap to recover from | No attribute loss; Ember quests; partial credit; Pause; Rekindle; salvage prompt | Moderate (abstinence-violation literature); Emerging (app-specific) |
| 7 | Cooperation by default, competition by consent | Additive Guild Undertakings; contribution roll (unranked); Commendations; opt-in near-peer Rivalry | Moderate to Strong (cooperation); Moderate (competition) |
| 8 | Share actions, not identity claims | Per-item sharing; action and plan post templates; Oath-witness that never reports misses | Moderate (public reporting); Emerging (identity backfire) |
| 9 | Monitor, review, adjust, with task-focused feedback | Logged completions; Weekly Review loop; own-baseline analytics; attribution-aware copy | Strong |
| 10 | Close open loops with plans, never exploit them | Set It Down; next-step field; resume cards; no overdue counters at night | Emerging (plan-making); Moderate (resumption, rumination) |
| 11 | Deterministic rewards only | Published formula; achievement codex; direct-price cosmetics; no random rewards | Strong (schedule effects); Moderate (loot-box harm association) |
| 12 | Low cognitive load, respectful attention | Today ≤5; suggestions ≤3; progressive disclosure; notification budget; quiet hours; adaptive briefing frequency | Strong (load); Moderate (notifications) |
| 13 | Build mastery and controllable attributions | First-week ladder; past-performance receipts; Guild Tales; attribution rules; calibrated targets | Moderate |
| 14 | Self-compassionate recovery | Three-part missed-day copy; rough-day chip; rest restores Condition; no failure vocabulary | Moderate |
| 15 | Fresh starts at landmarks, never postponement | Locale-aware New Chapter (Saturday/Monday, Solar Hijri or Gregorian month, Nowruz, birthday) | Moderate (effect); design assumption (locale landmarks) |
| 16 | The game layer serves needs, not compulsion | Emergent classes; meaningful titles; cosmetic self-expression; no energy, timers, or login rewards | Moderate |
| 17 | AI restraint | No emotion inference; Chronicles grounded in ledger data; AI proposes, engine decides | Strong (limits of emotion inference); design assumption (product rule) |

---

## Rules we commit to

These are product invariants. Changing any of them requires an explicit decision record (ADR) citing new evidence.
A/B test results that improve engagement are *not* sufficient grounds.

1. **No permanent attribute loss.** Attribute XP and levels never decrease because of inactivity, missed quests,
   broken Vigils, or low Condition. The only reductions are the user's own undo within 24 hours and transparent
   administrative corrections, each recorded as a reversing ledger entry with a reason (PRD FR-4).
2. **Condition is temporary and harmless.** It reflects recovery versus overexertion, is never reduced by missed
   tasks, is bounded, recovers on its own (faster with logged rest), never gates features, never reduces XP gains,
   and is never shown publicly.
3. **No randomized rewards.** No loot boxes, gacha, mystery chests, random drops, spin wheels, chance-based
   bonuses, or near-miss presentations, whether paid or free.
4. **No paid progression.** Money never buys XP, attributes, levels, titles, Condition recovery, Rekindles, Vigil
   repairs, or social features essential to accountability. Prices are shown directly, and there are no randomized
   bundles or countdown scarcity. (The brief specifies cosmetic-only monetization. PRD 4.11 also sketches a
   premium tier with AI insights and longer-range Chronicles. Either way this rule holds, and core
   self-monitoring, meaning the Weekly Review and weekly analytics, must stay free.)
5. **Deterministic, explainable growth.** Every XP grant has a ledger entry and a Growth Receipt. The XP bar shows
   absolute progress to the next level and is never inflated. Any progress shown at onboarding reflects real,
   labeled actions.
6. **No guilt, shame, or fear copy.** No "you failed", "streak lost", "your guild is disappointed", confirmshaming,
   or sad-mascot guilt. Every template passes the copy lint in both English and Persian.
7. **The AI never infers emotional state, mental health, or personality** from behavior, timing, text, or voice. It
   responds only to what the user explicitly states (rough-day chip, written reflection, optional motivation
   profile). The profile is optional, editable, and deletable at any time. (Scientific basis: Barrett et al., 2019,
   on the unreliability of emotion inference. Regulatory context: Article 5(1)(f) of Regulation (EU) 2024/1689
   prohibits emotion-inference AI in workplace and education settings.)
8. **The AI proposes and the engine decides.** The AI never writes to the character directly. The deterministic
   engine applies caps and diminishing returns, and the user can Petition any evaluation.
9. **Notification caps.** At most 2 app-initiated motivational nudges per day, and at most 5 non-reminder
   notifications per day in total, with guild activity batched (PRD N3). None during quiet hours (default
   22:00–08:00 local). Every category can be switched off individually, and briefing frequency drops
   automatically when the briefing is ignored.
10. **At most 3 AI-suggested quests per day.** The PRD's single "suggested focus" (M2) sits within this cap.
    Dismissing a suggestion carries no penalty and is never recorded as a miss. At most 5 quests above the fold on
    Today.
11. **Streaks are weekly and forgiving.** Vigils count weeks meeting a user-set target, include at least one rest
    day per week, allow one earned Rekindle per month, and can be paused (travel, illness, exams) without loss. A
    broken Vigil never resets lifetime totals, records, titles, or attributes.
12. **No global or public leaderboards.** Comparison is opt-in, near-peer, time-boxed, consistency-based, and never
    labels anyone "last".
13. **Guild outcomes never punish individuals.** Undertakings are additive, with targets recommended from active
    members' recent activity. One member's inactivity never reduces another's rewards, and the app never notifies
    a guild that a specific member is inactive.
14. **Private by default.** Nothing about a user's quests is shared until the user chooses a sharing level (per
    guild, overridable per quest). Misses and Condition are never shared at any level.
15. **Re-engagement is gentle and finite.** At most two messages per lapse, no loss framing, then silence until the
    user returns. A monthly digest only if the user opts in.
16. **No compulsion mechanics.** No energy or stamina limits, no daily login rewards, no artificial open loops or
    cliffhanger notifications, no overdue counters in evening notifications.
17. **Honest science in copy.** Never claim "21 days to a habit", "willpower runs out", or other contested findings
    as fact. Feedback targets the task and strategy, never the person's worth or fixed ability.

---

## Open questions to validate with users

1. **XP visibility.** Does hiding the XP number until completion (the default) preserve enjoyment without
   reducing follow-through, compared with showing it upfront? Which users turn previews on?
2. **Vigil comprehension.** Do users understand weekly-target streaks, and do they feel as motivating as daily
   streaks without the anxiety? What default target and number of rest days feel right?
3. **Condition.** Is a temporary HP-like state motivating, neutral, or stressful? Does "rest restores Condition"
   change rest behavior in healthy or unhealthy ways?
4. **AI evaluation fairness.** Do users perceive AI evaluations as fair and informational, or as judgmental? What
   Petition rate and outcome patterns indicate trust problems?
5. **Comparison appetite.** What share of users opt into Rivalry? Does participation help or harm users who sit in
   the lower half of their group?
6. **Comeback recognition.** Does the Return bonus increase re-engagement after lapses without encouraging
   deliberate lapses?
7. **Persian-speaking users.** Do sharing norms, guild dynamics (cooperation vs competition), and tone preferences
   differ from English-speaking users? Which fresh-start landmarks resonate (Nowruz, Solar Hijri month starts,
   Saturday week start)? How does self-compassionate copy read in Persian?
8. **Dark-fantasy tone vs warmth.** Can the aesthetic carry self-compassionate, non-shaming messages without feeling
   saccharine or bleak?
9. **Chronicles.** Do AI-written narratives increase meaning and identified motivation, or feel generic or
   embarrassing? How often do users read them, and which do they share?
10. **Optional motivation profile.** Who fills it in, and does using the user's own "why" in suggestions improve
    acceptance and follow-through?
11. **Notification budget.** Is 2 per day too many or too few for different user types? Does adaptive briefing
    frequency feel respectful or neglectful?
12. **Habit graduation.** Do users welcome Mastered Rite (fewer reminders, tapering XP), or experience tapering XP
    as a penalty?
13. **Suggestion cap.** Is 3 suggested quests per day right? Do power users want more, and do new users want
    fewer?
14. **Set It Down ritual.** Does an evening planning step improve next-day completion and self-reported sleep or
    rumination, or is it skipped as extra work?
15. **Durability.** Which features show benefit beyond week 4 and week 12? This needs cohort analysis, with goal
    attainment, SRBAI-style automaticity, need satisfaction (PENS-style items), and well-being as outcomes, not
    just retention.

---

### Note on sources

All DOIs above were checked against Crossref metadata on 2026-11-04. Books and book chapters (Ferster & Skinner,
1957; Marlatt & Gordon, 1985; Cochran & Tesser, 1996; Schüll, 2012) are cited without DOIs. Page numbers for the
Cochran & Tesser chapter are omitted because they could not be verified. The completion percentages quoted for
Nunes & Drèze (2006) come from widely reproduced summaries of the paper and should be checked against the original
before being quoted externally.

Supporting reference for Rule 7: Barrett, L. F., Adolphs, R., Marsella, S., Martinez, A. M., & Pollak, S. D. (2019).
Emotional expressions reconsidered: Challenges to inferring emotion from human facial movements. *Psychological
Science in the Public Interest, 20*(1), 1–68. https://doi.org/10.1177/1529100619832930
