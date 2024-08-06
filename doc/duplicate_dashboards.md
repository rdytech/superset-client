# Duplicating Dashboards to a New Database or Schema

## The Problem

In a multi-tenant configuration where client databases are logically separate (either separate databases or separate schemas), copying or duplicating an existing Superset dashboard to a new database can be a laborious process with many manual steps.

### Typical Steps in Superset GUI
- Create a dashboard template.
- Duplicate the template in the GUI using Edit -> Save As (ensuring duplicate charts are checked).
- Duplicate all datasets from the template, edit each, and point to the new target database.
- Edit all the new charts created and link them to the new datasets.
- Set up the embedded settings for the new dashboard.
- Add new tags for the new dashboard.

Given the need to perform this for multiple clients (tens, hundreds, or thousands), this becomes a very time-consuming task.

### Superset API to the Rescue

**Note**: This requires setting up your [Superset environment credentials](https://github.com/rdytech/superset-client/blob/develop/doc/setting_up_personal_api_credentials.md).

## The Solution

We can perform the same steps as above via the Superset API.

In this example, the example video game dashboard has been adjusted to include only one chart for simplicity.  The output includes the new dashboard ID and URL, with logs provided in `log/superset-client.log`.

To attempt this on your local superset setup with the examples databse, you would need to create a second database (ref id 2 below) that is a direct replica of the examples db.

Given you have a dashboard created, ref `source_dashboard_id`, and you know your `target_schema` and `target_database_id`, the following call would duplicate the dashboard.

```ruby
Superset::Services::DuplicateDashboard.new(
    source_dashboard_id: 90,
    target_schema: 'public',
    target_database_id: 2
  ).perform

=> {:new_dashboard_id=>401, :new_dashboard_url=>"https://your-superset-host/superset/dashboard/401/", :published=>false}

# Logfile shows the steps taken

# cat log/superset-client.log
# INFO -- : >>>>>>>>>>>>>>>>> Starting DuplicateDashboard Service <<<<<<<<<<<<<<<<<<<<<<
# INFO -- : Source Dashboard URL: https://your-superset-host/superset/dashboard/90/
# INFO -- : Duplicating dashboard 90 into Target Schema: public in database 2
# INFO -- :   Copy Dashboard/Charts Completed - New Dashboard ID: 401
# INFO -- : Duplicating Source Dataset examples.video_game_sales with id 11
# INFO -- :     Finished. Duplicate Dataset Name video_game_sales-example_two with id 542
# INFO -- :     Validating Dataset ID: 542 schema update to public on Database: 2
# INFO -- :     Successfully updated dataset schema to public on Database: 2
# INFO -- : Updating Charts to point to New Datasets and updating Dashboard json_metadata ...
# INFO -- :   Update Chart 55752 to new dataset_id 542
# INFO -- :   Updated new Dashboard json_metadata charts with new dataset ids
# INFO -- : Duplication Successful. New Dashboard URL: https://your-superset-host/superset/dashboard/401/
# INFO -- : >>>>>>>>>>>>>>>>> Finished DuplicateDashboard Service <<<<<<<<<<<<<<<<<<<<<<
```

## Additional Options for Embedded Workflow and Tags

If you are using embedded dashboards, you can also provide attributes for:
- Allowed domains for embedded dashboard settings.
- Database tags for ease of searching.
- Option to publish.

```ruby
Superset::Services::DuplicateDashboard.new(
    source_dashboard_id: 37,
    target_schema: 'public',
    target_database_id: 2,
    allowed_domains: ["https://wylee-coyote-domain/"],
    tags: ["product:acme_fu", "client:wylee_coyote", "embedded"],
    publish: true
  ).perform
```

### Determining Your Database ID

```ruby
# List your available databases with
Superset::Database::List.call

# DEBUG -- : Happi: GET https://your-superset-host/api/v1/database/?q=(page:0,page_size:100), {}
+----+------------------------------------+------------+------------------+
|                        Superset::Database::List                         |
+----+------------------------------------+------------+------------------+
| Id | Database name                      | Backend    | Expose in sqllab |
+----+------------------------------------+------------+------------------+
| 1  | examples                           | postgresql | true             |
| 2  | examples_two                       | postgresql | true             |
+----+------------------------------------+------------+------------------+

# Optionally provide a title filter
Superset::Database::List.new(title_contains: 'examples_two').list

# DEBUG -- : Happi: GET https://your-superset-host/api/v1/database/?q=(filters:!((col:database_name,opr:ct,value:'examples')),page:0,page_size:100), {}
+----+------------------------------------+------------+------------------+
|                        Superset::Database::List                         |
+----+------------------------------------+------------+------------------+
| Id | Database name                      | Backend    | Expose in sqllab |
+----+------------------------------------+------------+------------------+
| 2  | examples_two                       | postgresql | true             |
+----+------------------------------------+------------+------------------+
```

### Determining Your Dashboards

```ruby
# List dashboards with
Superset::Dashboard::List.call
# DEBUG -- : Happi: GET https://your-superset-host/api/v1/dashboard/?q=(page:0,page_size:100), {}
+-----+------------------------------------------------------+-----------+--------------------------------------------------------------------+
|                                                          Superset::Dashboard::List                                                          |
+-----+------------------------------------------------------+-----------+--------------------------------------------------------------------+
| Id  | Dashboard title                                      | Status    | Url                                                                |
+-----+------------------------------------------------------+-----------+--------------------------------------------------------------------+
| 20  | Baby Names                                           | draft     | https://your-superset-host/superset/dashboard/20/                  |
| 6   | Video Game Sales                                     | published | https://your-superset-host/superset/dashboard/6/                   |
| 5   | COVID Vaccine Dashboard                              | published | https://your-superset-host/superset/dashboard/5/                   |
| 9   | Superset Project Slack Dashboard                     | published | https://your-superset-host/superset/dashboard/9/                   |
+-----+------------------------------------------------------+-----------+--------------------------------------------------------------------+

# Or filter by title
Superset::Dashboard::List.new(title_contains: 'video').list
# DEBUG -- : Happi: GET https://your-superset-host/api/v1/dashboard/?q=(filters:!((col:dashboard_title,opr:ct,value:'video')),page:0,page_size:100), {}
+----+------------------+-----------+------------------------------------------------------------------+
|                                      Superset::Dashboard::List                                       |
+----+------------------+-----------+------------------------------------------------------------------+
| Id | Dashboard title  | Status    | Url                                                              |
+----+------------------+-----------+------------------------------------------------------------------+
| 6  | Video Game Sales | published | https://your-superset-host/superset/dashboard/6/ |
+----+------------------+-----------+------------------------------------------------------------------+
```

### Replicate a Dashboard Across All Schemas

To duplicate a dashboard across all schemas in Acme pools 1, 2, and 3:

```ruby
acme_dbs = Superset::Database::List.new(title_contains: 'acme').rows
=> [["7", "acme-pool1", "postgresql", "true"],
    ["8", "acme-pool2", "postgresql", "true"], 
    ["9", "acme-pool3", "postgresql", "true"]]

ignore_system_tables = ['information_schema', 'shared_extensions']  # PostgreSQL system schemas

db_with_schemas = acme_dbs.map do |db_conn|
  Superset::Database::GetSchemas.new(db_conn[0]).list.map do |schema|
    { database_id: db_conn[0], schema: schema, database_name: db_conn[1] } unless ignore_system_tables.include?(schema)
  end.compact
end.flatten

=>[{:database_id=>"7", :schema=>"client1", :database_name=>"acme-pool1"},
   {:database_id=>"7", :schema=>"client2", :database_name=>"acme-pool1"},
   {:database_id=>"7", :schema=>"client3", :database_name=>"acme-pool1"},
   {:database_id=>"8", :schema=>"client4", :database_name=>"acme-pool2"},
   {:database_id=>"8", :schema=>"client5", :database_name=>"acme-pool2"},
   {:database_id=>"8", :schema=>"client6", :database_name=>"acme-pool2"},
   {:database_id=>"9", :schema=>"client7", :database_name=>"acme-pool3"},
   {:database_id=>"9", :schema=>"client8", :database_name=>"acme-pool3"},
   {:database_id=>"9", :schema=>"client9", :database_name=>"acme-pool3"},
   {:database_id=>"9", :schema=>"client10", :database_name=>"acme-pool3"}]

db_with_schemas.each do |conn|
  Superset::Services::DuplicateDashboard.new(
    source_dashboard_id: 90,
    target_schema:       conn[:schema],
    target_database_id:  conn[:database_id]
  ).perform
end
```

## TODO / Issues

### Handling Change

Dashboards are ever-evolving, and changes are expected. This raises the question: given a template dashboard and multiple replicas, how do you update the template and propagate changes to each replica?

Changes can be broadly categorized into two types:

1. **Minor changes to a dataset query**: Adjusting the logic of the query without altering the output attributes. This can be handled easily by locating each dashboard's dataset and updating the query via the Superset API.

2. **Major changes**: Editing or adding charts, formatting the dashboard, updating datasets with new attributes for new charts. There is no clear, easy direction forward for these changes. The current approach is to delete all replica dashboards and recreate them.

### Bringing the Duplicate Dashboard Process into Superset Core

Potential direction is to have the DuplicateDashboard process as part of the core Superset codebase. This Superset Improvement Proposal (SIP) below is a starting point for the discussion.

{Add SIP request here}