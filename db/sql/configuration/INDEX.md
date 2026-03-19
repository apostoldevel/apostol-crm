# configuration

> Application-specific database layer

This directory contains configuration code for the Project Example application. The active configuration is determined by `\set dbname example` in `sql/sets.psql`.

## Structure

```
configuration/
  apostol/              ← Project Example application configuration
    INDEX.md               ← Master overview with module index and class tree
    create.psql            ← Full installation (loaded after platform/create.psql)
    update.psql            ← Update routines/views only
    patch.psql             ← DDL patches + update
```

See [example/INDEX.md](example/INDEX.md) for the full module documentation.
