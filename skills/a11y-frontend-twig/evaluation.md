# Evaluation of Draft: a11y-frontend-twig

## 1. Diagnosis of the Draft

### Strengths
- The draft had the right semantic core: semantic HTML first, ARIA only where needed, keyboard operability, and validation.
- It already covered the main Drupal frontend surfaces that matter here: Twig, SDC, cache integrity, and validation.
- The anti-patterns were useful and correctly targeted common accessibility mistakes.

### Gaps
- **Operational triggers:** The draft said what good output looks like, but not clearly when the agent should activate the skill or how it relates to the broader theming workflow.
- **Retrieval behavior:** It did not tell the agent what to inspect before editing, especially existing templates, Drupal attribute variables, current JS state logic, or SDC prop contracts.
- **Scope boundaries:** It implied Drupal theming scope, but did not explicitly separate accessibility decisions from general theming and build concerns.
- **Execution gates:** It lacked explicit must/should/must-not rules, which makes day-to-day application less reliable.
- **Update semantics:** It mentioned dynamic ARIA, but did not formalize truthfulness requirements around cached markup, duplicate state logic, or dropped Drupal attributes during template rewrites.
- **Persistence rules:** It had no guidance on which accessibility decisions are durable enough to record in project memory versus which fixes are routine code changes.

### Risks
- An agent could treat the draft like a best-practices note and still skip important context gathering before touching Twig or JS.
- A template rewrite could accidentally drop `attributes` or related Drupal surfaces because the draft did not explicitly protect them.
- The agent could apply ARIA roles or keyboard patterns inconsistently because the draft did not force a simplest-pattern decision.
- Personalized or dynamic accessibility state could become stale in cached markup because the draft did not define update behavior strongly enough.

## 2. Preserved Ideas
- Semantic HTML first.
- Context-aware ARIA instead of blanket ARIA usage.
- Keyboard and focus management as a first-class requirement.
- SDC as the preferred component model for reusable frontend work.
- Validation through automated tooling plus manual keyboard and screen-reader checks.
- The anti-patterns list centered on fake buttons, static ARIA, hidden focus, and nested interactivity.

## 3. Missing Pieces Added
- **Activation triggers:** Clear conditions for when the skill applies.
- **Retrieval modes:** Explicit searches for structure, attribute surfaces, behavior, component contracts, and validation tooling.
- **Scope and boundary rules:** Separation between accessibility work and general theming and build workflow, with a note to pair with `drupal-theming-workflow` when needed.
- **Pattern selection:** A decision table mapping UI needs to the simplest accessible pattern.
- **Execution gates:** `Must`, `Should`, and `Must Not` rules for predictable agent behavior.
- **Drupal-specific update rules:** Explicit protection for `attributes` and related Twig variables, unique IDs for `aria-*` relationships, and truthful cache-safe state handling.
- **Memory integration:** Durable write rules for architectural accessibility decisions and incidents.

## 4. Rewritten Skill Text
See `SKILL.md`.

## 5. Explicit Rules Implemented
- **Retrieval:** Search existing templates, components, attribute variables, JS handlers, and SDC props before editing or adding behavior.
- **Persistence:** Record only durable accessibility invariants, custom widget rationale, cache-state decisions, and incident-level failures.
- **Update behavior:** Keep `aria-*` state truthful, preserve Drupal-provided attributes during Twig rewrites, and avoid user-specific accessible state in shared cached markup.
