# Drupal Module: Standard Implementation Spec

## Title
Standard Implementation for Drupal module `team_tasks`

## Objective
Develop a custom Drupal module `team_tasks` that provides an internal task management system built around a custom content entity. The implementation should follow standard Drupal architecture and coding practices.

## Module purpose
The module should allow administrators and permitted users to create, manage, view, and organize internal tasks inside Drupal. The module must include a custom entity, business logic service, admin routes, configuration form, local actions/tabs, permissions, and a small UI library.

## Assumed target
- Drupal 10 or Drupal 11
- PHP 8.2+
- Modern Drupal service/container patterns
- Dependency injection where appropriate

## Required YAML files
Create and use these files:
- `team_tasks.info.yml`
- `team_tasks.routing.yml`
- `team_tasks.links.menu.yml`
- `team_tasks.links.action.yml`
- `team_tasks.links.task.yml`
- `team_tasks.services.yml`
- `team_tasks.permissions.yml`
- `team_tasks.libraries.yml`

## Core functional requirements

### 1. Custom entity
Create a custom content entity `Task`.

The entity must support:
- create
- read/view
- update/edit
- delete
- administrative listing

Minimum fields:
- `title`
- `description`
- `status`
- `priority`
- `due_date`
- `assignee_uid`
- `reporter_uid`
- `estimated_hours`
- `external_ref`

Field expectations:
- `assignee_uid` and `reporter_uid` must reference Drupal users
- `due_date` must use an appropriate date/datetime field type
- `description` must use a suitable text field type
- `status` and `priority` should be compatible with configurable allowed values

### 2. Routes and pages
Implement routes/pages for:
- task collection/list page
- task canonical/view page
- task add form
- task edit form
- task delete form
- module settings form
- dashboard/overview page

Dashboard must display:
- task counts by status
- overdue task count
- task count assigned to current user if authenticated

### 3. Business logic service
Create a dedicated service for module business logic.

The service must:
- count tasks grouped by status
- detect overdue tasks
- build dashboard data
- read available statuses and priorities from configuration
- expose reusable methods so controllers/forms do not contain business logic

Use dependency injection.
Avoid static container lookups unless there is a strong Drupal-specific reason.

### 4. Configuration form
Create a Config Form for module settings.

Settings must include:
- available statuses
- available priorities
- default status for new tasks
- enable/disable notifications
- admin list page size
- enable/disable dashboard

Requirements:
- use Drupal Config API
- validate and normalize submitted config
- save and reload values correctly
- use config values in runtime behavior where appropriate

### 5. Permissions
Define permissions:
- `view own tasks`
- `view all tasks`
- `create tasks`
- `edit own tasks`
- `edit all tasks`
- `delete own tasks`
- `delete all tasks`
- `administer team tasks settings`

Apply permissions appropriately in routes and task operations.

### 6. Menu links, local actions, local tasks
Implement:
- admin menu entry for the module
- local action link for creating a task
- local task tabs for view/edit/delete where appropriate
- menu/settings link for module configuration

### 7. Library
Define at least one library in `team_tasks.libraries.yml`.

Use it for one of:
- dashboard styling
- status badges/colors
- small admin-side enhancement with CSS and optional JS

### 8. Architecture and code quality
Requirements:
- follow Drupal coding standards
- use clear namespaces and directory layout
- separate concerns across entity, form, controller, and service classes
- avoid invented Drupal APIs
- keep implementation realistic and runnable

## Expected output
Provide:
1. Full module file structure
2. Main YAML definitions
3. Entity implementation
4. Controller/service/form implementations
5. Brief architecture explanation
6. Short explanation of where config is used, where service logic lives, and where entity responsibilities begin/end
