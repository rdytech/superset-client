# Implementation Plan: Database CSV Upload

## Requirements

- Add `Superset::Database::UploadCsv` class that posts a CSV file to `POST /api/v1/database/{pk}/upload/`
- Accept all parameters documented in `doc/upload_csv_params.md`
- Follow existing multipart upload pattern (as used in `Superset::Dashboard::Import`)
- Validate required parameters before sending the request

## Acceptance Criteria

- `Superset::Database::UploadCsv.new(database_id: 1, file: "/path/to/data.csv", table_name: "my_table").perform` uploads the file and returns the response
- Required params (`database_id`, `file`, `table_name`) raise `ArgumentError` when missing or invalid
- Optional params are passed through only when provided (no nil keys in payload)
- Spec covers required param validation and happy-path response

## Out of scope

- Excel upload (the `type` param will be hardcoded to `"csv"` for this class — a separate `UploadExcel` class can follow the same pattern later)
- Verifying the target table exists after upload
- UI / console display helpers (`list_attributes`)

## Approach

Follow the `Superset::Dashboard::Import` pattern exactly:

1. Inherit from `Superset::Request`
2. Override `response` to call `client(use_json: false).post(route, payload)` — this switches Faraday to multipart mode
3. Wrap the file in `Faraday::UploadIO.new(file, "text/csv")`
4. Build `payload` as a hash of all provided params, excluding nils
5. `perform` calls `validate_params` then `response`
6. `route` returns `"database/#{database_id}/upload/"`

The `type` field will default to `"csv"` and not be exposed as a constructor argument, keeping the interface simple for the CSV-only case.

## Files to change

| File | Change |
|------|--------|
| `lib/superset/database/upload_csv.rb` | New class `Superset::Database::UploadCsv` |
| `spec/superset/database/upload_csv_spec.rb` | New spec file |

## Tests to add / modify

| File | What to test |
|------|-------------|
| `spec/superset/database/upload_csv_spec.rb` | `#perform` — raises `ArgumentError` when `database_id` is nil |
| | `#perform` — raises `ArgumentError` when `file` is nil |
| | `#perform` — raises `ArgumentError` when `file` path does not exist |
| | `#perform` — raises `ArgumentError` when `table_name` is nil or blank |
| | `#perform` — returns response when all required params are valid (stub `response`) |
| | `#payload` — optional params are excluded from payload when not provided |
| | `#payload` — optional params are included in payload when provided |
| | `#route` — returns correct route string |

## Config / schema changes

None

## Risks & assumptions

- The Superset API returns a success body (not just a 200 status) — stub `response` in specs rather than hitting the real API
- `Faraday::UploadIO` is already available (used by `Dashboard::Import`); no new gem dependencies needed
- Array params (`column_dates`, `columns_read`, `null_values`) should be passed as Ruby arrays — Faraday multipart will serialize them; verify this works with the real API
- Boolean params (`dataframe_index`, `day_first`, `skip_blank_lines`, `skip_initial_space`) must be sent as strings (`"true"`/`"false"`) since multipart form data is string-only

## Resolved decisions

- `already_exists` must be validated — raise `ArgumentError` if value is not `"fail"`, `"replace"`, or `"append"`
- `column_data_types` accepts a Ruby Hash; the class calls `.to_json` before sending
- `result` returns a simple success/failure message string from the API response
