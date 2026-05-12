# Dry Run: Drupal Migration

## Example Task

Import doctor profiles from a CSV file into Drupal nodes with taxonomy term references and paragraph fields for specialties.

## Applied Workflow

1. Source: CSV with columns `id`, `name`, `title`, `bio`, `specialties` (pipe-separated), `location_name`.

2. Migration plan (3 migrations in dependency order):
   - `doctor_terms` — import specialties as taxonomy terms.
   - `doctor_paragraphs` — create specialty paragraph items.
   - `doctor_nodes` — import doctor nodes referencing terms and paragraphs.

3. YAML for `doctor_nodes`:
   ```yaml
   id: doctor_nodes
   source:
     plugin: csv
     path: private://imports/doctors.csv
     ids: [id]
   process:
     title: name
     field_title: title
     body/value: bio
     body/format:
       plugin: default_value
       default_value: full_html
     field_specialties:
       plugin: sub_process
       source: specialties
       process:
         target_id:
           plugin: migration_lookup
           migration: doctor_terms
           source: name
     field_location:
       plugin: entity_lookup
       entity_type: taxonomy_term
       bundle: locations
       value_key: name
       source: location_name
   destination:
     plugin: 'entity:node'
     default_bundle: doctor
   migration_dependencies:
     required:
       - doctor_terms
       - doctor_paragraphs
   ```

4. Run:
   ```bash
   drush migrate:import doctor_terms
   drush migrate:import doctor_paragraphs
   drush migrate:import doctor_nodes
   drush migrate:status --group=doctors
   ```

## Output

- 3 migrations, all `Idle` status after completion.
- 150 doctor nodes created with correct term references.
- Rollback tested: `drush migrate:rollback doctor_nodes` removes nodes cleanly.
- Re-import with `--update` correctly updates changed records.
