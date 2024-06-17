# Superset Client

[![Build status](https://badge.buildkite.com/fc7ee4a03e119a5d859472865fc0bdc9a6e46d51b7f5b8cd62.svg)](https://buildkite.com/jobready/superset-client)

The Repo is `superset-client` with the ruby gem named `superset`

All ruby classes are namespaced under `Superset::`

# Installation

## Docker Setup

Build, bundle and open a ruby console

```
docker-compose build
docker-compose run --rm app bundle install
docker-compose run --rm app bin/console
```

Run specs

```
docker-compose run --rm app rspec
# or 
docker-compose run --rm app bash      # then run 'bundle exec rspec' from the container.
```

## Local setup or including in a Ruby/Rails app

Add to your Gemfile `gem 'superset'`  
And then execute: `bundle install`  
Or install it yourself as `gem install superset`

## Setup API Credentials

Follow this doc setup your users API creds [setting_up_personal_api_credentials](https://github.com/rdytech/superset-client/tree/develop/doc/setting_up_personal_api_credentials.md)

Short version is .. copy the `env.sample` to `.env` and add edit values where applicable.  Opening a console with `bin/console` will then auto load the `.env` file.

## Usage

Experiment with the API calls directly by open a pry console using  `bin/console`




### API calls

Quickstart examples

```ruby
Superset::Database::List.call
Superset::Database::GetSchemas.new(1).list # get schemas for database 1

Superset::Dashboard::List.call
Superset::Dashboard::List.new(title_contains: 'Sales').list

Superset::Dashboard::BulkDelete.new(dashboard_ids: [1,2,3]).perform        # Dashboards only ( leaves all charts, datasets in place)
Superset::Dashboard::BulkDeleteCascade.new(dashboard_ids: [1,2,3]).perform # Dashboards and related charts and datasets.

Superset::Sqllab::Execute.new(database_id: 1, schema: 'public', query: 'select count(*) from birth_names').perform

Superset::Dashboard::Export.new(dashboard_id: 1, destination_path: '/tmp').perform

Superset::RouteInfo.new(route: 'dashboard/_info').perform # Get info on an API endpoint .. handy for getting available filters
Superset::RouteInfo.new(route: 'chart/_info').filters     # OR just get the filters for an endpoint

superset_class_list # helper method to list all classes under Superset::

```

### Duplicating Dashboards

Primary motivation behind this library was to use the Superset API to duplicate dashboards, charts, datasets across multiple database connections.  
See examples in [Duplicate Dashboards](https://github.com/rdytech/superset-client/tree/develop/doc/duplicate_dashboards.md)

### API Examples with results

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
## Optional Credential setup for Embedded User

Primary usage is for api calls and/or for guest token retrieval when setting up applications to use the superset embedded dashboard workflow.

The Superset API users fall into 2 categories  
- a user for general api calls to endpoints for Dashboards, Datasets, Charts, Users, Roles etc.  
  ref `Superset::Credential::ApiUser`  
  which pulls credentials from  `ENV['SUPERSET_API_USERNAME']` and `ENV['SUPERSET_API_PASSWORD']`

- a user for guest token api call to use when embedding dashboards in a host application.  
  ref `Superset::Credential::EmbeddedUser`
  which pulls credentials from  `ENV['SUPERSET_EMBEDDED_USERNAME']` and `ENV['SUPERSET_EMBEDDED_PASSWORD']`


### Fetch a Guest Token for Embedded user

Assuming you have setup your Dashboard in Superset to be embedded and that your creds are setup in  
`ENV['SUPERSET_EMBEDDED_USERNAME']` and `ENV['SUPERSET_EMBEDDED_PASSWORD']`

```
Superset::GuestToken.new(embedded_dashboard_id: '15').guest_token
=> "eyJ0eXAiOi............VV4mrMfsvg"
```

## Releasing a new version

On develop branch make sure to update `Superset::VERSION` and `CHANGELOG.md` with the new version number and changes.  
Build the new version and upload to gemfury.

`gem build superset.gemspec`

### Publishing to RubyGems

WIP .. direction is for this gem to be made public

### ReadyTech private Gemfury repo

ReadyTech hosts its own private gemfury remote repo.

Get the latest develop into master

    git checkout master
    git pull
    git fetch
    git merge origin/develop

Tag the version and push to github

    git tag -a -m "Version 0.1.0" v0.1.0
    git push origin master --tags

Push to gemfury or upload the build manually in the gemfury site.

    git push fury master

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
