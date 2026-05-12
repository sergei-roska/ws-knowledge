# Drupal Module: Test-Driven Implementation Spec

## Title
Test-Driven Implementation for Drupal module `team_tasks`

## Objective
Develop the same custom Drupal module `team_tasks`, but do it in a test-first style. The module must be designed through tests first, then implemented so the tests drive the architecture and behavior.

## Important process rule
Do not begin with production implementation.
Start with test strategy, then tests, then implementation.

## Module purpose
The module provides internal task management based on a custom content entity, configuration-driven behavior, admin routes, permissions, dashboard data, and a reusable business logic service.

## Assumed target
- Drupal 10 or Drupal 11
- PHP 8.2+
- PHPUnit-based Drupal testing
- Dependency injection and testable architecture

## Required YAML files
The final implementation must include:
- `team_tasks.info.yml`
- `team_tasks.routing.yml`
- `team_tasks.links.menu.yml`
- `team_tasks.links.action.yml`
- `team_tasks.links.task.yml`
- `team_tasks.services.yml`
- `team_tasks.permissions.yml`
- `team_tasks.libraries.yml`

## Functional requirements for the final module

### 1. Custom entity
Create a custom content entity `Task` with at least:
- `title`
- `description`
- `status`
- `priority`
- `due_date`
- `assignee_uid`
- `reporter_uid`
- `estimated_hours`
- `external_ref`

### 2. Routes and pages
The module must provide:
- task list page
- task view page
- task add form
- task edit form
- task delete form
- settings form
- dashboard page

### 3. Service behavior
A dedicated service must:
- count tasks by status
- identify overdue tasks
- build dashboard data
- read available statuses and priorities from config

### 4. Config form behavior
The settings form must support:
- available statuses
- available priorities
- default status
- notifications toggle
- admin list page size
- dashboard toggle

### 5. Permissions
Permissions must include:
- `view own tasks`
- `view all tasks`
- `create tasks`
- `edit own tasks`
- `edit all tasks`
- `delete own tasks`
- `delete all tasks`
- `administer team tasks settings`

## Process requirements

### Step 1. Test strategy first
Before implementation, explain:
- which concerns belong in Unit tests
- which concerns belong in Kernel tests
- which concerns belong in Functional tests
- which scenarios are critical enough to define architecture
- what should not be over-tested

### Step 2. Write tests first
Create the tests before production code.

Minimum expected coverage:

#### A. Kernel tests
- Task entity can be created and saved
- expected base fields exist
- module config can be read
- service can read statuses/priorities from config
- service can compute grouped task counts
- service can detect overdue tasks

#### B. Functional tests
- user with permission can access task list
- user without permission is denied
- user with permission can access add form
- settings page is restricted to admin permission
- config form saves successfully
- dashboard page renders expected statistics
- local action for creating a task is available where expected
- local task tabs appear where expected if implemented that way

#### C. Unit tests
Only when useful for isolated logic that does not need Drupal kernel.
Do not write decorative unit tests just to increase test count.

## Test quality rules
- tests must verify behavior, not just class existence
- test names must be descriptive
- tests should influence implementation structure
- if tests force architectural choices, explain that briefly

### Step 3. Implement production code
After defining tests, implement the module so that the behavior described by tests becomes true.

## Implementation rules
- use dependency injection
- avoid unnecessary global/static service lookups
- follow Drupal coding standards
- keep code testable and modular
- let tests shape service boundaries and controller/form responsibilities

## Expected output
Provide:
1. Short test strategy
2. Test classes and key test cases first
3. Production code after tests
4. Short explanation of how implementation follows from tests
5. Brief note on covered vs uncovered behavior
