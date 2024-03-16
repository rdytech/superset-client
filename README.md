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


## Usage

Experiment with the API calls directly by open a pry console using  
`bin/console`

Primary usage is for general api calls and/or for guest token retrieval when setting up applications to use the superset embedded dashboard workflow.

The Superset API users may then fall into 2 categories
- a user for general api calls to endpoints for Dashboards, Datasets, Charts, Users, Roles etc.  ref `Superset::Credential::ApiUser`
which pulls credentials from  
`ENV['SUPERSET_API_USERNAME']` and `ENV['SUPERSET_API_PASSWORD']`

- a user for guest token api call to use when embedding dashboards in a host application. ref `Superset::Credential::EmbeddedUser`
which pulls credentials from  
`ENV['SUPERSET_EMBEDDED_USERNAME']` and `ENV['SUPERSET_EMBEDDED_PASSWORD']`

Configure your superset host in  
  `ENV['SUPERSET_HOST']`

Copy the `env.sample` to `.env` and add edit values where applicable.  
Opening a console with `bin/console` will then auto load the `.env` file.

See here to setup your users API creds [setting_up_personal_api_credentials](https://github.com/rdytech/superset-client/tree/develop/doc/setting_up_personal_api_credentials.md)


## API calls

Generally they follow the convention/path of the Superset API strucuture as per the swagger docs.

ref https://superset.apache.org/docs/api/

Limited support for filters is available on some list pages.  Pagination is supported.

Primary methods across majority of api calls are
- response : the full API response
- result : just the result attribute array
- list : displays a formatted output to console, handy for quick investigation of objects
- call : is a alias to list on Get and List requests

```
# some examples
Superset::Dashboard::Get.call(1)
+----------------------------+
|     World Bank's Data      |
+----------------------------+
| Charts                     |
+----------------------------+
| % Rural                    |
| Region Filter              |
| Life Expectancy VS Rural % |
| Box plot                   |
| Most Populated Countries   |
| World's Population         |
| World's Pop Growth         |
| Rural Breakdown            |
| Treemap                    |
| Growth Rate                |
+----------------------------+

Superset::Dashboard::List.new(title_contains: 'test').list
D, [2024-03-05T10:48:10.053139 #5095] DEBUG -- : Happi: GET https://your-ss-host/api/v1/dashboard/?q=(filters:!((col:dashboard_title,opr:ct,value:'test')),page:0,page_size:100), {}
+----+-------------------------------------+-----------+-------------------------------------------------------+
|                                     Superset::Dashboard::List                                                |
+----+-------------------------------------+-----------+-------------------------------------------------------+
| Id | Dashboard title                     | Status    | Url                                                   |
+----+-------------------------------------+-----------+-------------------------------------------------------+
| 22 | Embedded Test 1                     | published | https://your-ss-host/superset/dashboard/22/           |
| 36 | Test Embedded 2                     | published | https://your-ss-host/superset/dashboard/36/           |
| 7  | Unicode Test                        | published | https://your-ss-host/superset/dashboard/unicode-test/ |
+----+-------------------------------------+-----------+-------------------------------------------------------+


# Default page num is 100
Superset::Dashboard::List.new().list

# second set of 100 dashboards
Superset::Dashboard::List.new(page_num: 1).list

```


### Fetch a Guest Token

Assuming you have setup your Dashboard in Superset to be embedded and that your creds are setup in  
`ENV['SUPERSET_EMBEDDED_USERNAME']` and `ENV['SUPERSET_EMBEDDED_PASSWORD']`

```
Superset::GuestToken.new(embedded_dashboard_id: '15').guest_token
=> "eyJ0eXAiOi............VV4mrMfsvg"
```

## Development

After checking out the repo, run tests with  
`bundle exec rspec`

You can also run for an interactive pry prompt that will allow you to experiment.  
`bin/console`

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
Build the new version and upload to gemfury.

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

Push to gemfury or upload the build manually in the gemfury site.

    git push fury master

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
