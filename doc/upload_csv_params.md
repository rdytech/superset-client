# CSV Upload API

**Endpoint:** `POST /api/v1/database/{pk}/upload/`

Upload a file to a database table.

---

## Path Parameters

| Name | Type    | Required | Description        |
|------|---------|----------|--------------------|
| `pk` | integer | Yes      | Database record ID |

---

## Form Parameters (multipart/form-data)

| Name                 | Type    | Required | Applies To  | Default | Description |
|----------------------|---------|----------|-------------|---------|-------------|
| `file`               | file    | Yes      | All         |         | The CSV file to upload |
| `table_name`         | string  | Yes      | All         |         | The name of the table to create or append to |
| `type`               | string  | Yes      | All         | `csv`   | File type to upload |
| `already_exists`     | string  | No       | All         | `fail`  | Action when table exists: `fail`, `replace`, or `append` |
| `column_data_types`  | string  | No       | CSV only    |         | JSON dict of column names to Pandas data types. Example: `{"user_id": "int"}` |
| `column_dates`       | array   | No       | CSV, Excel  |         | Column names to parse as dates. Example: `["date", "timestamp"]` |
| `columns_read`       | array   | No       | All         |         | List of column names to read (others ignored) |
| `dataframe_index`    | boolean | No       | All         |         | Write dataframe index as a column |
| `day_first`          | boolean | No       | CSV only    |         | Parse dates as DD/MM (European format) |
| `decimal_character`  | string  | No       | CSV, Excel  | `.`     | Character to use as decimal point |
| `delimiter`          | string  | No       | CSV only    |         | Character used to separate values (comma, semicolon, tab, etc.) |
| `header_row`         | integer | No       | CSV, Excel  |         | Row index containing column headers (0 = first row). Leave empty for no header |
| `index_column`       | string  | No       | CSV, Excel  |         | Column to use as row labels. Leave empty for none |
| `index_label`        | string  | No       | CSV, Excel  |         | Label for the index column |
| `null_values`        | array   | No       | CSV, Excel  |         | Strings to treat as null. Example: `["", "None", "N/A"]`. Hive supports only one value |
| `rows_to_read`       | integer | No       | CSV, Excel  |         | Max rows to read. Reads all if not set |
| `schema`             | string  | No       | All         |         | Database schema to upload into |
| `sheet_name`         | string  | No       | Excel only  |         | Sheet name to read (defaults to first sheet) |
| `skip_blank_lines`   | boolean | No       | CSV only    |         | Skip blank lines |
| `skip_initial_space` | boolean | No       | CSV only    |         | Skip spaces after the delimiter |
| `skip_rows`          | integer | No       | CSV, Excel  |         | Number of rows to skip at the start of the file |
