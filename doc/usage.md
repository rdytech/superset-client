# Usage

## API call examples

Quickstart examples

```ruby
Superset::Database::List.call
Superset::Database::GetSchemas.new(1).list # get schemas for database 1

Superset::Dashboard::List.call
Superset::Dashboard::List.new(title_contains: 'Sales').list
Superset::Dashboard::Datasets::List.new(dashboard_id: 10).list  # get all datasets for dashboard 10

Superset::Dashboard::Datasets::List.new(dashboard_id: 10, include_filter_datasets: true).list  # get all datasets for dashboard 10 including the ones used only in dashboard filters
Superset::Dashboard::WarmUpCache.new(dashboard_id: 10).perform

Superset::Dataset::List.call

Superset::Chart::List.call

Superset::Dashboard::BulkDelete.new(dashboard_ids: [1,2,3]).perform        # Deletes Dashboards only ( leaves all charts, datasets in place)
Superset::Dashboard::BulkDeleteCascade.new(dashboard_ids: [1,2,3]).perform # Deletes Dashboards and related charts and datasets. (WARNING: no checks are performed)

Superset::Sqllab::Execute.new(database_id: 1, schema: 'public', query: 'select count(*) from birth_names').perform

Superset::Dashboard::Export.new(dashboard_id: 1, destination_path: '/tmp').perform

Superset::RouteInfo.new(route: 'dashboard/_info').perform # Get info on an API endpoint .. handy for getting available filters
Superset::RouteInfo.new(route: 'chart/_info').filters     # OR just get the filters for an endpoint

superset_class_list # helper method to list all classes under Superset::

```

## Detailed API Examples

Generally classes follow the convention/path of the Superset API strucuture as per the swagger docs.

ref https://superset.apache.org/docs/api/

Limited support for filters is available on some list pages, primarily through param `title_contains`.  
Pagination is supported via `page_num` param.

Primary methods across majority of api calls are
- response : the full API response
- result : just the result attribute array
- list : displays a formatted output to console, handy for quick investigation of objects
- call : is a class method to list on Get and List requests

```ruby
# List all Databases
Superset::Database::List.call
# DEBUG -- : Happi: GET https://your-superset-host/api/v1/database/?q=(page:0,page_size:100), {}
+----+------------------------------------+------------+------------------+
|                        Superset::Database::List                         |
+----+------------------------------------+------------+------------------+
| Id | Database name                      | Backend    | Expose in sqllab |
+----+------------------------------------+------------+------------------+
| 1  | examples                           | postgresql | true             |
+----+------------------------------------+------------+------------------+

# List database schemas for Database 1
Superset::Database::GetSchemas.new(1).list
# DEBUG -- : Happi: GET https://your-superset-host/api/v1/database/1/schemas/, {}
=> ["information_schema", "public"]

# List dashboards
Superset::Dashboard::List.call
# PAGE_SIZE is set to 100, so get the second set of 100 dashboards with
Superset::Dashboard::List.new(page_num: 1).list
# OR filter by title
Superset::Dashboard::List.new(title_contains: 'Sales').list
# DEBUG -- : Happi: GET https://your-superset-host/api/v1/dashboard/?q=(filters:!((col:dashboard_title,opr:ct,value:'Sales')),page:0,page_size:100), {}

+-----+------------------------------+-----------+--------------------------------------------------------------------+
|                                              Superset::Dashboard::List                                              |
+-----+------------------------------+-----------+--------------------------------------------------------------------+
| Id  | Dashboard title              | Status    | Url                                                                |
+-----+------------------------------+-----------+--------------------------------------------------------------------+
| 6   | Video Game Sales             | published | https://your-superset-host/superset/dashboard/6/                   |
| 8   | Sales Dashboard              | published | https://your-superset-host/superset/dashboard/8/                   |
+-----+------------------------------+-----------+--------------------------------------------------------------------+


Superset::Dashboard::Get.call(1)  # same as Superset::Dashboard::Get.new(1).list
+----------------------------+
|     World Banks Data      |
+----------------------------+
| Charts                     |
+----------------------------+
| % Rural                    |
| Region Filter              |
| Life Expectancy VS Rural % |
| Box plot                   |
| Most Populated Countries   |
| Worlds Population          |
| Worlds Pop Growth          |
| Rural Breakdown            |
| Treemap                    |
| Growth Rate                |
+----------------------------+


```