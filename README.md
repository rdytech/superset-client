# Superset Client

[![Build status](https://badge.buildkite.com/fc7ee4a03e119a5d859472865fc0bdc9a6e46d51b7f5b8cd62.svg)](https://buildkite.com/jobready/superset-client)

The Repo is `superset-client` with the gem named `superset`

All ruby classes are namespaced under `Superset::`

## Installation

Add to your Gemfile
```
gem 'superset'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install superset

Open a pry console with the gem directly using `bin/console`

## Usage

Assumption is that this Gem would be used for general api calls and/or for guest token retrieval when setting up applications to use the superset embedded dashboard workflow.

The Superset API users could then fall into 2 categories
- a user for general api calls to endpoints for Dashboards, Datasets, Charts, Users, Roles etc.  ref `Superset::Credential::ApiUser`
- a user for guest token api call to use when embedding dashboards in a host application. ref `Superset::Credential::EmbeddedUser`

Credential setup is per following env vars:
Env Var Credentials setup as follows
- for general api calls setup creds in  `ENV['SUPERSET_API_USERNAME']` and `ENV['SUPERSET_API_PASSWORD']`
- for embedded user calls setup creds in `ENV['SUPERSET_EMBEDDED_USERNAME']` and `ENV['SUPERSET_EMBEDDED_PASSWORD']`
- configure your superset host in `ENV['SUPERSET_HOST']`

Copy the `env.sample` to `.env` and add edit values where applicable.  In your ruby console load the env vars with `load '.env'`

### API calls

Generally they follow the convention/path of the Superset API strucuture.

```
# some examples
Superset::Dashboard::List.call
Superset::Dashboard::Get.new(1).result
Superset::Dashboard::Export.new(1).perform
Superset::Dashboard::Import.new(zip_file: 'my_dashboard.zip').perform


All List endpoints have a `.call` method to pull the first 100 records or the ability to search.

```
Superset::Dashboard::List.call
DEBUG -- : Happi: GET https://your-superset-host.com/api/v1/dashboard/?q=(page:0,page_size:100), {}
+----+-----------------------------------+-----------+-----------------------------------------------------------------+
|                                             Superset::Dashboard::List                                                |
+----+-----------------------------------+-----------+-----------------------------------------------------------------+
| Id | Dashboard title                   | Status    | Url                                                             |
+----+-----------------------------------+-----------+-----------------------------------------------------------------+
| 15 | Innovation Day: Staging Test001   | published | https://your-superset-host.com/superset/dashboard/25/           |
| 66 | Acme EXPORT TEST                  | published | https://your-superset-host.com/superset/dashboard/36/   |
| 69 | Overview: Acme Stage              | draft     | https://your-superset-host.com/superset/dashboard/59/   |
...................
+----+-----------------------------------+-----------+-----------------------------------------------------------------------------+

# Optionally can add a search term to most list endpoints

Superset::Dashboard::List.new(title_contains: 'innov').list
DEBUG -- : Happi: GET https://your-superset-host.com/api/v1/dashboard/?q=(filters:!((col:dashboard_title,opr:ct,value:innov)),page:0,page_size:100), {}
+----+-----------------------------------+-----------+-----------------------------------------------------------------+
|                                             Superset::Dashboard::List                                                |
+----+-----------------------------------+-----------+-----------------------------------------------------------------+
| Id | Dashboard title                   | Status    | Url                                                             |
+----+-----------------------------------+-----------+-----------------------------------------------------------------+
| 15 | Innovation Day: Staging Test001   | published | https://your-superset-host.com/superset/dashboard/25/           |
+----+-------------------------------------------------+-----------+-------------------------------------------------------------------+

Superset::Dashboard::Embedded::Get.new(15).result
D, [2024-01-23T09:23:32.345514 #14893] DEBUG -- : Happi: GET https://your-superset-host.com/api/v1/dashboard/15/embedded, {}
=> [{"allowed_domains"=>["https://acme.com/", "https://acme-staging.com/"],
  "changed_by"=>{"first_name"=>"Jonathon", "id"=>9, "last_name"=>"Batson", "username"=>"some-superset-user-uuid"},
  "changed_on"=>"2023-12-19T05:38:06.923548",
  "dashboard_id"=>"15",
  "uuid"=>"some-superset-dashboard-uuid"}]

### Fetch a Guest Token

Assuming you have setup your Dashboard in Superset to be embedded and that your creds are setup in  `ENV['SUPERSET_EMBEDDED_USERNAME']` and `ENV['SUPERSET_EMBEDDED_PASSWORD']`

```
Superset::GuestToken.new(embedded_dashboard_id: '15').guest_token
=> "eyJ0eXAiOi............VV4mrMfsvg"

## Development

After checking out the repo, run `bundle exec rspec` to run the tests.

You can also run `bin/console` for an interactive pry prompt that will allow you to experiment.

Docker setup is also an option.

### Docker Setup

Use [Docker](https://docs.docker.com/docker-for-mac/install/) to run in containers.

Once Docker is installed on your system, you can use the following commands from the root of the application folder, e.g `/var/www/elcapitan`:

###### Build images:

`docker-compose build`

###### Bundle install and run specs:

`docker-compose run --rm app`

###### Bundle install:

`docker-compose run --rm app bundle install`

###### Run specs:

```
docker-compose run --rm app rspec
# or
docker-compose run --rm app /bin/bash      # then run rspec from inside the container.
```

## Releasing a new version

On develop branch make sure to update `Superset::VERSION` and `CHANGELOG.md` with the new version number and changes.
And of course that the lastest version is built and in the repo.

`gem build superset.gemspec`

### Publishing to RubyGems

WIP .. general idea is for this gem to be made public

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

Push to gemfury:

    git push fury master

## Contributing

WIP

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).