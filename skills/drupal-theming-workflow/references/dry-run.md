# Dry Run: Drupal Theming Workflow

## Example Task

Add a responsive hero banner component to the Sun State Specialists theme using SDC.

## Applied Workflow

1. Scope: new SDC component (`hero-banner`) with responsive background image, title, subtitle, and CTA button.

2. Create component:
   ```
   docroot/themes/custom/sun_state_specialists/components/hero-banner/
   ├── hero-banner.component.yml
   ├── hero-banner.twig
   ├── hero-banner.css
   └── hero-banner.js
   ```

3. Define props in `hero-banner.component.yml`:
   - `title` (string, required)
   - `subtitle` (string)
   - `cta_text` (string)
   - `cta_url` (string)
   - `image_url` (string, required)

4. Template uses `<picture>` with responsive image style for background.
   Attach library automatically via SDC auto-discovery.

5. Add breakpoint-specific styles in `hero-banner.css`:
   - Mobile: stacked layout, smaller text.
   - Tablet: side-by-side layout.
   - Desktop: full-width with overlay text.

6. Use component in paragraph template:
   ```twig
   {{ include('sun_state_specialists:hero-banner', {
     title: content.field_title|render|trim,
     subtitle: content.field_subtitle|render|trim,
     cta_text: content.field_cta_text|render|trim,
     cta_url: content.field_cta_link.0['#url'],
     image_url: file_url(node.field_image.entity.fileuri),
   }) }}
   ```

7. Build and validate:
   ```bash
   lando gulp build && lando drush cr
   ```
   Test at mobile/tablet/desktop widths. Verify `<picture>` sources.

## Output

- 4 new files in `components/hero-banner/`.
- 1 modified paragraph template.
- Responsive images verified at all 3 breakpoints.
- No global CSS changes — component is self-contained.
