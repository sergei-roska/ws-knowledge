---
name: drupal-testing
description: Write and run automated tests for Drupal 10/11 using PHPUnit Unit, Kernel, Functional, and BrowserTest types. Use when creating tests, fixing test failures, setting up test infrastructure, or validating custom module behavior.
---

# Drupal Testing

## Overview

Write correct, fast, and maintainable tests for Drupal custom code.
This skill ensures the right test type is chosen for each scenario, proper test directory structure is followed, and tests run reliably in both local (Lando) and CI (Azure) environments.

## Decision: Which Test Type?

Before writing a test, classify what you need to verify:

- **Pure PHP logic** (no Drupal APIs) → Unit test (`UnitTestCase`).
- **Service/entity/database logic** (needs Drupal bootstrap, no HTTP) → Kernel test (`KernelTestBase`).
- **Page rendering, forms, routing** (needs full Drupal + HTTP) → Functional test (`BrowserTestBase`).
- **JavaScript/AJAX interactions** → WebDriver test (`WebDriverTestBase`).
- **Existing site tests** (test against running site, no install) → DTT `ExistingSiteBase`.

**Rule of thumb:** use the lightest test type that covers the behavior. Unit > Kernel > Functional > WebDriver.

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

### Kernel Tests

- Extend `Drupal\KernelTests\KernelTestBase`.
- Partial Drupal bootstrap with database.
- Install modules via `protected static $modules = ['my_module', 'node'];`.
- Install entity schemas via `$this->installEntitySchema('node')`.
- Install config via `$this->installConfig(['my_module'])`.
- Good for: services, entity queries, config logic, plugin behavior.

### Functional Tests

- Extend `Drupal\Tests\BrowserTestBase`.
- Full Drupal install per test class.
- Use `$this->drupalGet()`, `$this->submitForm()`, `$this->assertSession()`.
- Good for: forms, routing, access control, page content.

### WebDriver Tests

- Extend `Drupal\FunctionalJavascriptTests\WebDriverTestBase`.
- Full browser with JS execution.
- Use `$this->assertSession()->waitForElement()` for AJAX.
- Good for: autocomplete, AJAX forms, drag-and-drop, modal dialogs.

## Writing Tests

### Setup

- Use `setUp()` for common fixtures (users, content types, nodes).
- Create test users with specific permissions via `$this->drupalCreateUser(['perm'])`.
- Create content via `$this->drupalCreateNode(['type' => 'article'])`.

### Assertions

- `$this->assertEquals($expected, $actual)` — value equality.
- `$this->assertSession()->pageTextContains('text')` — page content.
- `$this->assertSession()->statusCodeEquals(200)` — HTTP status.
- `$this->assertSession()->fieldValueEquals('field_name', 'value')` — form field.
- `$this->assertCount(3, $results)` — collection size.

### Test Isolation

- Each test method runs independently — no state leaks between tests.
- Kernel tests: call `$this->installSchema()` for custom tables.
- Functional tests: full site install per class (slow) — keep test classes focused.

## Running Tests

### Local (Lando)

```bash

# Run all tests for a module

lando php vendor/bin/phpunit -c phpunit.xml --testsuite unit
lando php vendor/bin/phpunit docroot/modules/custom/my_module/tests/

# Run a specific test class

lando php vendor/bin/phpunit --filter=ExampleServiceTest

# Run a specific test method

lando php vendor/bin/phpunit --filter=testEmptyRequirements
```

### CI

- Ensure `phpunit.xml` is committed with correct test suite directories.
- Set `SIMPLETEST_BASE_URL`, `SIMPLETEST_DB` environment variables.
- Functional tests need a running web server and database.

## Required Checks

- Test class namespace matches directory structure (PSR-4).
- `$modules` array includes all dependencies for Kernel/Functional tests.
- Entity schemas and config are installed in `setUp()` for Kernel tests.
- No `\Drupal::service()` calls in Unit tests — mock everything.
- Tests pass both locally and in CI with identical results.

## Anti-Patterns

- Writing Functional tests for logic that can be tested with Unit or Kernel tests.
- Testing Drupal core/contrib behavior instead of custom code.
- Hardcoding entity IDs or assuming database state across tests.
- Skipping `setUp()` and duplicating setup code in every test method.
- Not installing required modules/schemas in Kernel tests (causes cryptic errors).
- Using `sleep()` instead of `waitForElement()` in WebDriver tests.

## References

- Read `references/testing-patterns.md` for code templates by test type.
- Read `references/dry-run.md` for a worked testing example.
