---
name: drupal-testing
description: Write and run automated tests for Drupal 10/11 using PHPUnit Unit, Kernel, Functional, and BrowserTest types. Use when creating tests, fixing test failures, setting up test infrastructure, or validating custom module behavior.
---

# Drupal Testing

## Overview

Write correct, fast, and maintainable tests for Drupal custom code.

This skill ensures the right test type is chosen for each scenario, proper test directory structure is followed, tests run reliably in both local and CI environments, and the agent knows when a test is worth writing and when it is not.

## Scope and Status

- **Scope:** All Drupal 10.2+ and 11.x custom module testing.
- **Status:** active
- **PHP requirement:** 8.2+
- **Test runner:** PHPUnit (Drupal's built-in configuration).
- **Excluded:** Contrib module tests, Behat, Cypress, or other non-PHPUnit frameworks — unless the project explicitly uses them.

> **Note:** For existing-site testing (against a running installed site rather than a fresh install), see the DTT section below.

## Workflow: Test Task Entry

When entering a testing task, follow this sequence:

1. **Identify the module under test.** Locate the module root directory and its existing test structure.
2. **Check for existing tests.** Before writing new tests, inspect `tests/src/` for existing coverage. Do not duplicate.
3. **Classify what to test.** Use the Decision Matrix below to select the test type.
4. **Check dependencies.** For Kernel and Functional tests, identify all required modules, entity schemas, and config.
5. **Write the test.** Follow the patterns in this skill and in `references/testing-patterns.md`.
6. **Run the test locally.** Confirm it passes.
7. **Validate isolation.** Confirm the test does not depend on state from other tests.

## Decision Matrix: Which Test Type?

Before writing a test, classify what you need to verify:

| I need to test... | Test type | Base class |
|---|---|---|
| Pure PHP logic (no Drupal APIs) | Unit | `UnitTestCase` |
| Service/entity/database logic (Drupal bootstrap, no HTTP) | Kernel | `KernelTestBase` |
| Page rendering, forms, routing, access control (full HTTP) | Functional | `BrowserTestBase` |
| JavaScript/AJAX interactions | WebDriver | `WebDriverTestBase` |
| Behavior on an existing installed site (no fresh install) | DTT | `ExistingSiteBase` |

**Rule of thumb:** Use the lightest test type that covers the behavior. Unit > Kernel > Functional > WebDriver.

### Boundary Rules (Ambiguous Cases)

- **Service uses `\Drupal::entityTypeManager()` internally?** → Kernel, not Unit. You need the container.
- **Form submission saves config but I only care about the config value?** → Kernel if you can call the form submit handler directly. Functional if you need to test routing, access, and the full form render/submit flow.
- **Access control on a route?** → Functional. Access checks require a full request cycle.
- **Plugin with dependencies?** → Kernel if testing plugin logic. Functional if testing plugin rendering.
- **Queue worker?** → Kernel for `processItem()`. Functional only if testing cron-triggered execution end-to-end.

## Coverage Priorities

### Must Test

- Custom services with business logic.
- Access control on custom routes and permissions.
- Config forms that save settings (verify data persists).
- Queue workers (`processItem()` happy path + failure handling).
- Data transforms and payload builders (pure logic → Unit).

### Should Test

- Block plugins (render output matches expectations).
- Field formatters (output for edge-case field values).
- Event subscribers (verify they fire and produce the expected side effect).
- Custom entity operations (CRUD via API).

### May Test

- Simple controllers that only delegate to a service (the service test may suffice).
- Templates/Twig (hard to test meaningfully; visual review is often better).
- Admin UX flows (better suited for manual QA or Cypress if available).

### Must Not Test

- Drupal core/contrib behavior (not your code, not your test).
- Simple getter/setter methods with no logic.
- Configuration YAML structure (schema validation catches this).
- Code that is a thin wrapper around a Drupal API call with no conditional logic.

## Test Directory Structure

```text
my_module/
└── tests/
    └── src/
        ├── Unit/
        │   └── ExampleServiceTest.php
        ├── Kernel/
        │   └── EntityQueryTest.php
        ├── Functional/
        │   └── SettingsFormTest.php
        └── FunctionalJavascript/
            └── AjaxWidgetTest.php
```

Namespace: `Drupal\Tests\{module_name}\{Type}\{ClassName}`.

## Test Type Patterns

### Unit Tests

- Extend `Drupal\Tests\UnitTestCase`.
- No Drupal bootstrap — fastest to run.
- Mock all dependencies via `$this->createMock()`.
- Good for: data transforms, utility functions, value objects, enums.
- **Constraint:** No `\Drupal::service()` calls. No static Drupal calls. Mock everything.

### Kernel Tests

- Extend `Drupal\KernelTests\KernelTestBase`.
- Partial Drupal bootstrap with database.
- Install modules via `protected static $modules = ['my_module', 'node'];`.
- Install entity schemas via `$this->installEntitySchema('node')`.
- Install config via `$this->installConfig(['my_module'])`.
- Good for: services, entity queries, config logic, plugin behavior.
- **Common pitfall:** Forgetting to install a dependency module or entity schema → cryptic "table not found" errors. Always list all transitive dependencies.

### Functional Tests

- Extend `Drupal\Tests\BrowserTestBase`.
- Full Drupal install per test class.
- Use `$this->drupalGet()`, `$this->submitForm()`, `$this->assertSession()`.
- Set `protected $defaultTheme = 'stark';` — required since Drupal 9.
- Good for: forms, routing, access control, page content.
- **Cost awareness:** Full install per test class is slow. Keep test classes focused. Do not put 20 test methods in one Functional test class.

### WebDriver Tests

- Extend `Drupal\FunctionalJavascriptTests\WebDriverTestBase`.
- Full browser with JS execution.
- Use `$this->assertSession()->waitForElement()` for AJAX — never `sleep()`.
- Good for: autocomplete, AJAX forms, drag-and-drop, modal dialogs.
- **Requires:** Running ChromeDriver or Selenium.

### DTT / Existing Site Tests

- Extend `weitzman\DrupalTestTraits\ExistingSiteBase`.
- Runs against an **existing installed site** — no fresh install.
- Requires the `weitzman/drupal-test-traits` package.
- Good for: smoke tests, content migration validation, integration tests against real data.
- **Trade-off:** Fast (no install), but tests depend on site state. Not hermetic.

## Writing Tests

### Setup

- Use `setUp()` for common fixtures (users, content types, nodes).
- Create test users with specific permissions: `$this->drupalCreateUser(['perm'])`.
- Create content: `$this->drupalCreateNode(['type' => 'article'])`.
- Keep `setUp()` minimal. Only create what the test class needs. Over-provisioning slows tests and obscures intent.

### Assertions

| Assertion | Purpose |
|---|---|
| `$this->assertEquals($expected, $actual)` | Value equality |
| `$this->assertSession()->pageTextContains('text')` | Page content |
| `$this->assertSession()->statusCodeEquals(200)` | HTTP status |
| `$this->assertSession()->fieldValueEquals('field_name', 'value')` | Form field |
| `$this->assertCount(3, $results)` | Collection size |
| `$this->assertInstanceOf(MyClass::class, $obj)` | Type check |
| `$this->expectException(\InvalidArgumentException::class)` | Expected exception |

### Test Isolation

- Each test method runs independently — no state leaks between methods.
- Kernel tests: call `$this->installSchema()` for custom database tables.
- Functional tests: full site install per class (slow) — keep test classes focused.
- **Never assume entity IDs.** Always query by properties, not by hardcoded IDs.

### Naming

- Test class: `{Subject}Test.php` — named after the class or behavior under test.
- Test method: `test{Behavior}()` — describe what is being verified, not how.
- Good: `testPublishedArticlesAreReturnedByQuery()`
- Bad: `testFunction1()`, `testIt()`

## Running Tests

### Local (Lando) — environment-specific

```bash
# Run all tests for a module
lando php vendor/bin/phpunit -c phpunit.xml --testsuite unit
lando php vendor/bin/phpunit docroot/modules/custom/my_module/tests/

# Run a specific test class
lando php vendor/bin/phpunit --filter=ExampleServiceTest

# Run a specific test method
lando php vendor/bin/phpunit --filter=testEmptyRequirements
```

> Adjust `lando php` to `ddev php` or `php` depending on the project's local environment.

### CI — environment-specific

- Ensure `phpunit.xml` is committed with correct test suite directories.
- Set `SIMPLETEST_BASE_URL`, `SIMPLETEST_DB` environment variables.
- Functional tests need a running web server and database.
- WebDriver tests need ChromeDriver or Selenium in the CI container.

## Failure Diagnosis

When a test fails, follow this sequence **before changing anything**:

1. **Read the full error message.** PHPUnit errors often include the exact assertion that failed, the expected vs. actual values, and a stack trace.
2. **Classify the failure:**
   - **Assertion failure** (expected ≠ actual) → Is the test wrong, or is the code wrong? Check the code under test first.
   - **Exception during setup** (e.g., "table not found") → Missing module, entity schema, or config install in `setUp()`.
   - **HTTP error (403, 404, 500)** → Missing route, missing permission, or missing module dependency.
   - **Class not found** → PSR-4 mismatch (namespace vs. file path).
   - **Timeout / Java exception** → WebDriver test missing ChromeDriver, or element selector is wrong.
3. **Fix the root cause.** Do not add workarounds (e.g., installing extra unnecessary modules) without understanding why the failure occurred.
4. **Re-run.** Confirm the fix resolves the failure without introducing new ones.

## Updating Existing Tests

When modifying code that has existing tests:

1. **Run existing tests first** to establish a baseline.
2. **If tests fail after code change**, determine whether:
   - The test correctly caught a regression → fix the code.
   - The test asserts old behavior that intentionally changed → update the test assertions.
3. **If adding new behavior**, add new test methods. Do not modify existing passing tests unless their assertions are now wrong.
4. **If removing behavior**, remove or update corresponding test methods. Do not leave dead tests.

## Required Checks

- Test class namespace matches directory structure (PSR-4).
- `$modules` array includes all dependencies for Kernel/Functional tests.
- Entity schemas and config are installed in `setUp()` for Kernel tests.
- No `\Drupal::service()` calls in Unit tests — mock everything.
- `$defaultTheme` is set in Functional and WebDriver tests.
- Tests pass both locally and in CI with identical results.

## Anti-Patterns and Fixes

| Anti-Pattern | Why It's Wrong | Fix |
|---|---|---|
| Using Functional test for logic testable at Unit/Kernel level | Wastes CI time, slower feedback | Reclassify: use lightest test type |
| Testing Drupal core/contrib behavior | Not your code, not your test | Test only custom code |
| Hardcoding entity IDs | Breaks with parallel tests or database changes | Query by properties |
| Duplicating setup in every method | DRY violation, harder to maintain | Use `setUp()` |
| Not installing modules/schemas in Kernel tests | "Table not found" errors | Declare all dependencies in `$modules` and `setUp()` |
| Using `sleep()` in WebDriver tests | Flaky, wastes time | Use `waitForElement()` or `waitForElementVisible()` |
| One giant Functional test class with 20 methods | Slow (full install per class), hard to debug | Split into focused classes |
| Testing private methods directly | Brittle, couples test to implementation | Test through public API |
| Asserting exact HTML output | Breaks on theme/markup changes | Assert semantic content (`pageTextContains`, field values) |

## References

- Read `references/testing-patterns.md` for code templates by test type.
- Read `references/dry-run.md` for a worked testing example.
