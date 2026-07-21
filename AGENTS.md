# Agents

This file provides guidance to AI coding agents working with code in this repository.

## Commands

```bash
# Install dependencies
bundle install

# Open interactive console (auto-loads .env)
bin/console

# Run full test suite
rspec

# Run a single test file
rspec spec/path/to/test_spec.rb

# Run a single test by line number
rspec spec/path/to/test_spec.rb:42

# Lint
rubocop

# Run specs + rubocop together
rake
```

Docker equivalents: prefix commands with `docker-compose run --rm app`.

### Environment Setup

Copy `env.sample` to `.env` and fill in:
- `SUPERSET_HOST` — API base URL (required)
- `SUPERSET_API_USERNAME` / `SUPERSET_API_PASSWORD` — API credentials (required)
- `SUPERSET_ENVIRONMENT` — optional; loads `.env-{ENVIRONMENT}` instead
- `CONSOLE_TIMEOUT` — seconds before auto-logout in console (default 1800)

## Architecture

### Request Framework

All API interactions inherit from `Superset::Request` (`lib/superset/request.rb`). Subclasses implement:
- `route` — returns the API path (e.g., `"dashboard/#{id}"`)
- `filters` — returns a filter query string or `""`
- `list_attributes` — array of field names used for terminal table display

**Patterns by HTTP verb:**
- **GET/LIST** — inherit `Superset::Request`, implement `route` and `filters`
- **PUT** — inherit `Superset::BasePutRequest`, takes `target_id:` and `params:`, implement `route`
- **DELETE/POST** — call `client.delete(route)` or `client.post(route, params)` directly

Pagination is built into `Superset::Request` (default page size: 100, max: 1000). List classes accept `page_num:` and `page_size:` kwargs.

### Authentication Flow

1. `Superset::Client` (extends `Happi::Client`) includes `Credential::ApiUser` and creates a `Superset::Authenticator`
2. `Authenticator` POSTs to `api/v1/security/login` and extracts `access_token`
3. `Client#connection` builds a Faraday connection with Bearer token; supports both JSON and multipart modes (`config.use_json`)

### Query Filter Syntax

Superset uses an ORM-like filter string format:
```
filters:!((col:column_name,opr:operation,value:value)),
```
Common operations: `ct` (contains), `eq` (equals), `neq` (not equals), `rel_o_m`, `rel_m_m`, `dashboard_tags`.

### Service Layer

`lib/superset/services/` contains complex multi-step workflows. The main one is `DuplicateDashboard`, which:
1. Validates source/target IDs, schema existence, and data sovereignty rules (all chart datasets must share the same DB schema)
2. Copies the dashboard and its charts
3. Duplicates datasets pointing to the target schema
4. Rewires chart JSON metadata and filter configs to the new dataset IDs
5. Optionally sets embedded config, tags, and publishes
6. **Rolls back all created objects on failure**

`ImportDashboardAcrossEnvironment` handles cross-environment migration via export/import ZIP files.

### Display Mixin

`Superset::Display` (`lib/superset/display.rb`) is included in `Superset::Request` and provides `list`, `rows`, `to_h`, and `ids`. Requires `list_attributes` and `result` to be implemented by the subclass.

### Resource–Relationship Model

- **Dashboards** contain **Charts**
- **Charts** reference **Datasets** (datasources)
- **Dashboard JSON metadata** stores layout, chart positions, and filter configurations
- **Filters** reference Datasets for filter values
- Duplication/migration requires updating all these cross-references

### Conventions

- Namespace: `Superset::<ResourceType>::<Action>` (e.g., `Superset::Dashboard::List`)
- `perform` — executes a state-changing action, returns `self`
- `response` — raw (cached) HTTP response
- `result` — extracts `response['result']`
- Constructor filter params follow naming: `title_contains:`, `title_equals:`, etc.
- Logging goes through `Superset.logger`; by default writes to `log/superset-client.log`. Consumers can inject any `::Logger`-compatible object via `Superset.configure { |c| c.logger = your_logger }`.

### Console Helpers

In `bin/console`: `sshelp` (alias: `superset_class_list`) lists all available `Superset::` classes. On startup, `Superset::Database::List.call` prints available DB connections.
