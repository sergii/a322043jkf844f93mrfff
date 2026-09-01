-- Local development runtime role. Migrations use the POSTGRES_USER owner;
-- Rails connects as this non-superuser so RLS is exercised during development.
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'hire_do_app') THEN
    CREATE ROLE hire_do_app LOGIN PASSWORD 'hire_do_development' NOSUPERUSER NOBYPASSRLS;
  END IF;
END $$;
GRANT CONNECT ON DATABASE hire_do_development TO hire_do_app;
GRANT USAGE ON SCHEMA public TO hire_do_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO hire_do_app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO hire_do_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO hire_do_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE, SELECT ON SEQUENCES TO hire_do_app;
