# Duplicating Dashboards to a new database or schema

The problem!

Given a multi tenant configuration where clients databases are logically separate dbs and or schemas all configured in Superset,  
copying or duplicating an existing Superset dashboard to a new database is a fairly laborious operation with many manual steps.

Usually run in the Superset GUI something like :
- Create Dashboard (template)
- Duplicate the template in GUI with Edit->Save As (duplicate charts checked)
- Duplicate all Datasets from template, Edit each and point to the new target database
- Edit all the new charts created and link them to the new datasets.
- Setup the embedded settings for new dashboard
- Add new tags for the new dashboard

Give the need for multiple clients, 10s or 100s, or 1000s, this quickly becomes a laborious and time consuming feat.

Superset API to the rescue.

Note .. requires setup of your [superset environment credentials](https://github.com/rdytech/superset-client/blob/develop/doc/setting_up_personal_api_credentials.md)

## The Solution

Essentially we perform the same points above but all via the Superset API.

The examples video game dashboard was adjusted to have only 1 chart.  
Output is new new_dashboard_id and url.  Logs provided in `log/superset-client.log`

Given you have a dashboard created, ie `source_dashboard_id`  
and you know your `target_schema`  
as well as your `target_database_id`  
then you could go ahead and run something like this.  



```ruby
Superset::Services::DuplicateDashboard.new(
    source_dashboard_id: 90,
    target_schema: 'client_1',
    target_database_id: 2
  ).perform

=> {:new_dashboard_id=>401, :new_dashboard_url=>"https://your-superset-host/superset/dashboard/401/", :published=>false}

# logfile shows the steps taken

# cat log/superset-client.log
# INFO -- : >>>>>>>>>>>>>>>>> Starting DuplicateDashboard Service <<<<<<<<<<<<<<<<<<<<<<
# INFO -- : Source Dashboard URL: https://your-superset-host/superset/dashboard/90/
# INFO -- : Duplicating dashboard 90 into Target Schema: client_1 in database 2
# INFO -- :   Copy Dashboard/Charts Completed - New Dashboard ID: 401
# INFO -- : Duplicating Source Dataset examples.video_game_sales with id 11
# INFO -- :     Finished. Duplicate Dataset Name video_game_sales-example_two-client_1 with id 542
# INFO -- :     Validating Dataset ID: 542 schema update to client_1 on Database: 2
# INFO -- :     Successfully updated dataset schema to client_1 on Database: 2
# INFO -- : Updating Charts to point to New Datasets and updating Dashboard json_metadata ...
# INFO -- :   Update Chart 55752 to new dataset_id 542
# INFO -- :   Updated new Dashboard json_metadata charts with new dataset ids
# INFO -- : Duplication Successful. New Dashboard URL: https://your-superset-host/superset/dashboard/401/
# INFO -- : >>>>>>>>>>>>>>>>> Finished DuplicateDashboard Service <<<<<<<<<<<<<<<<<<<<<<

```

## Other options for embedded workflow and tags

If your using the embedded dashboards you can also provied attributes for 
- allowed domains for embeded dashboard settings
- database tags for ease of searching
- option to publish

```ruby
Superset::Services::DuplicateDashboard.new(
    source_dashboard_id: 37,
    target_schema: 'client_1',
    target_database_id: 2,
    allowed_domains: ["https://wylee-coyote-domain/"],
    tags: ["product:acme_fu", "client:wylee_coyote", "embedded"],
    publish: true
  ).perform



```

## Duplication when schemas are not used

If your multitenant setup is at the database level, and database structures are replicated into the same base schema, ie public,
then the target resulted datasets name must be overidden in order to get around the superset uniq datasets name validation restriction.  This can be done through the parameter 'target_dataset_suffix_override'.

```ruby
Superset::Services::DuplicateDashboard.new(
    source_dashboard_id: 90,
    target_schema: 'public',
    target_database_id: 2
    target_dataset_suffix_override: 'client_1' 
  ).perform

```



### What is my Database ID ?

``` ruby
# list your available databases with
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

# optionally provide a title filter
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

### What Dashboards do I have access to ?

```ruby
# list dashboard with
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

# or filter by title
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

### Replicate a Dashboard across all schemas

With a bit of ruby ...

Duplicate dashboard across all schemas in acme pools 1,2,3.

```ruby
acme_dbs = Superset::Database::List.new(title_contains: 'acme').rows
=> [["7", "acme-pool1", "postgresql", "true"],
    ["8", "acme-pool2", "postgresql", "true"], 
    ["9", "acme-pool3", "postgresql", "true"]]

ignore_system_tables = ['information_schema', 'shared_extensions']   # postgres system schemas

db_with_schemas = acme_dbs.map do |db_conn|
  Superset::Database::GetSchemas.new(db_conn[0]).list.map do |schema|
    { database_id: db_conn[0], schema: schema, database_name: db_conn[1] } unless ignore_system_tables.include?(schema)
  end.compact
end.flatten

=>[{:database_id=>"7", :schema=>"client1", :database_name=>"acme-pool1"},
   {:database_id=>"7", :schema=>"client2", :database_name=>"acme-pool1"},
   {:database_id=>"7", :schema=>"client3", :database_name=>"acme-pool1"},
   {:database_id=>"8", :schema=>"client4", :database_name=>"acme-pool1"},
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

## TODO / ISSUES

### Handling Change

Dashboards are an ever evolving animal and they are expected to change.

This raises the question, given I have a template dashboard and I have X number of replicas of that dashboard  
how do I make a change to the template and get the change updated to each of the replicas?

Current direction is to separate these "changes" in to 2 categories.

- Firstly: minor chages to a Dataset query that will not result in breaking a chart.  
  ie .. adjusting the logic of the query but not the output attributes.
- Secondly: ... everything else.
  ie .. editing/adding charts, formating the dashboard, updating the datasets with new attributes for new charts

For the first case, the Superset API can easily locate each Dashboards Dataset and update the query with the changes.  
This is a fairly simple procedure.

For the second case, currently we can see no easy/clear direction forward.  
Very happy to have others with more experience in Superset pose suggestions.

Putting it simply, the current thinking is to delete all the replica dashboards and recreate them.

### Bringing the Duplicate Dashboard process into Superset core

An ideal direction would be to have the DuplicateDashboard process as a part of the core superset codebase.

A Superset discussion thread has been started in  [Duplicating Dashboards into a new database or schema](https://github.com/apache/superset/discussions/29899)