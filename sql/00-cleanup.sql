-- Cleanup
DROP SCHEMA IF EXISTS shop CASCADE;
CREATE SCHEMA IF NOT EXISTS shop;
-- Everything should be in a schema (!= public)
SET search_path TO shop;
