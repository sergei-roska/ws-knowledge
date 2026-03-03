# Dry Run: Static Analysis First Refactoring

## Example Task

Refactor `docroot/modules/custom/gc_salesforce_webform/` to pass PHPCS (Drupal,DrupalPractice) and PHPStan Level 8.

## Applied Workflow

1. Discover gates:
   - Found `phpcs.xml.dist` with `Drupal,DrupalPractice` standards.
   - Found `phpstan.neon` at level 6 — task requires level 8.
   - No Psalm config — skip for this pass.

2. Auto-fix formatting:
   ```
   phpcbf --standard=Drupal,DrupalPractice --extensions=php,module,inc,install docroot/modules/custom/gc_salesforce_webform/
   ```
   12 files fixed (whitespace, docblocks, trailing commas). Diff reviewed — no behavior changes.

3. PHPCS remaining issues:
   ```
   phpcs --standard=Drupal,DrupalPractice --extensions=php,module,inc,install docroot/modules/custom/gc_salesforce_webform/
   ```
   3 findings: missing return types, `@param` mismatch. Fixed manually.

4. PHPStan at target level:
   ```
   phpstan analyse --level=8 docroot/modules/custom/gc_salesforce_webform/
   ```
   5 errors: 2 nullability, 1 union type, 2 missing property types.
   Fixed with null checks, `instanceof` guards, typed `readonly` properties.

5. Full pipeline re-run — all clean.

## Output

- 15 files changed: 12 formatting (phpcbf), 3 manual type/doc fixes.
- 0 suppressions added.
- No runtime behavior changed.
- PHPStan level raised from 6 to 8 for this module.
- Follow-up: consider Level 9 and Psalm taint analysis for HTTP client calls.
