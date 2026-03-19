--------------------------------------------------------------------------------
-- Project Example — Shared Test Fixtures
--
-- The test database is created as a TEMPLATE copy of the dev database,
-- so all reference data (currencies, categories, types, etc.) already exists.
--
-- This file creates test-specific entities reused across multiple test files.
--------------------------------------------------------------------------------

SET search_path TO kernel, public;

-- Establish admin session context
SELECT test_setup_session();

-- Create a shared test client
SELECT test_create_client('test_fixture_client', 'Fixture Test Client');

-- Create active and passive accounts for the fixture client
SELECT test_create_account(GetClient('test_fixture_client'), 'active.account',  'customer.category', 'test.active.001');
SELECT test_create_account(GetClient('test_fixture_client'), 'passive.account', 'customer.category', 'test.passive.001');
