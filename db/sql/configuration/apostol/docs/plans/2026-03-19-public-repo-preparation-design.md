# Public Repository Preparation — Design

**Date:** 2026-03-19
**Status:** Approved
**Scope:** configuration/apostol/ — 30 entities, 368 SQL files, 1032 functions

## Goal

Prepare the apostol CRM configuration database layer for public GitHub repository by applying the same three work streams that were completed for the db-platform framework.

## Three Blocks

### Block 1: Documentation Overhaul
- JSDoc blocks for all 1032 functions (`@brief`, `@param`, `@return`, `@throws`, `@see`, `@since 1.0.0`)
- COMMENT ON rewrite for all 366 table/column comments to English
- Inline comment cleanup: translate 25 Russian comments, remove obvious ones

### Block 2: Exception Localization (per migration-1.2.0.md)
- Register 30 project-specific exceptions in error_catalog with 6 locales (ERR-400-200+)
- Migrate 10 exception.sql files from CreateExceptionResource/direct RAISE to error_catalog pattern
- Replace 19 hardcoded RAISE EXCEPTION with Russian text
- Replace 10 ObjectNotFound() calls with Russian parameters
- Translate 100+ WriteToEventLog() messages to English

### Block 3: Workflow Localization (per migration-1.2.1.md)
- 37 init.sql files: switch base language from Russian to English
- Add Edit*Text() calls for ru, de, fr, it, es (5 non-English locales)
- Swap AddDefaultMethods() parameter order
- Switch AddEvent labels to English

## Approach

Process by blocks (not by entity) because:
1. Error codes need global coordination (unified numbering)
2. Documentation is independent work
3. Localization follows a mechanical pattern

## Out of Scope

- Code refactoring or business logic changes
- SQL formatting
- Reference data translation (country names, region names, measure names — business data)
- Platform layer changes (already completed)
