# Dry Run: Static Analysis First Refactoring

## Example Task

Refactor `docroot/modules/custom/gc_salesforce_webform/` to pass PHPCS (Drupal,DrupalPractice) and PHPStan Level 8.

## Applied Workflow

1. **Applied R1 & R2 (Discover gates & Baselines):**
   - Found `phpcs.xml.dist` with `Drupal,DrupalPractice` standards.
   - Found `phpstan.neon` at level 6 — task requires level 8.
   - Identified no `phpstan-baseline.neon` to protect.
   - No Psalm config — skip for this pass.

2. **Applied R3 & R4 (Target Scope & Auto-formatting):**
   - Bounded scope to `docroot/modules/custom/gc_salesforce_webform/` only.
   ```bash
   phpcbf --standard=Drupal,DrupalPractice --extensions=php,module,inc,install docroot/modules/custom/gc_salesforce_webform/
   ```
   - 12 files fixed (whitespace, docblocks, trailing commas). Diff reviewed — no behavior changes.

3. **Applied R5 (Commit Formatting Separate):**
   - Committed the 12 formatting files with message: `Style: Auto-format gc_salesforce_webform via phpcbf`.

4. **Applied R6 (PHPCS remaining issues):**
   ```bash
   phpcs --standard=Drupal,DrupalPractice --extensions=php,module,inc,install docroot/modules/custom/gc_salesforce_webform/
   ```
   - 3 findings: missing return types, `@param` mismatch. Fixed manually.

5. **Applied R7, R10, R11 (PHPStan & Type Strictness):**
   ```bash
   phpstan analyse --level=8 docroot/modules/custom/gc_salesforce_webform/
   ```
   - 5 errors: 2 nullability, 1 union type, 2 missing property types.
   - Fixed with explicit null checks, `instanceof` guards, and typed `readonly` properties. No `mixed` types or suppressions were hallucinated to bypass the checks.

6. **Applied R9 (Validate Locally):**
   - Full pipeline re-run locally — all clean.

7. **Applied R12 (No Logic Changes):**
   - Verified that all fixes exclusively tightened types and standards without mutating business paths.

## Output

- 15 files changed: 12 formatting (committed separately), 3 manual type/doc fixes.
- 0 suppressions added.
- No runtime behavior changed.
- PHPStan level raised from 6 to 8 for this module.
