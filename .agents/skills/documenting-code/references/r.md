# R code documentation profile

## Scope

- Document exported functions, datasets, classes, methods, and user-visible parameters with roxygen comments.
- Record return values, errors, side effects, lifecycle, and examples when useful to callers.

## Conventions

- Follow the package's existing roxygen tags and Markdown settings.
- Keep documentation on the public contract; do not narrate obvious implementation details.
- Treat `NAMESPACE` and `man/*.Rd` as generated artifacts unless repository instructions say otherwise.

## Generation

Use the repository command when defined. Otherwise, prefer one of:

```bash
Rscript -e 'devtools::document()'
Rscript -e 'roxygen2::roxygenise()'
```

Do not hand-edit generated `NAMESPACE` or `man/*.Rd` files unless the project explicitly owns them manually.

## Validation

- Review changes to `NAMESPACE` and `man/*.Rd` against the source annotations.
- Run the package's configured checks and tests.
- If none are configured, use `R CMD check` on the package or the closest repository-approved equivalent.
