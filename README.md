# Superset Client

[![Build status](https://badge.buildkite.com/fc7ee4a03e119a5d859472865fc0bdc9a6e46d51b7f5b8cd62.svg)](https://buildkite.com/jobready/superset-client)

## Installation

```ruby
gem 'superset-client'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install superset-client


## Usage

Assumption is that this Gem would be used for general api calls and/or for guest token retrieval when setting up applications to use the superset embedded dashboard workflow.

The Superset API useage would fall into 2 general categories
- User for general api calls to endpoints for Dashboards, Datasets, Charts, Users, Roles etc
- User for guest token api call to use when embedding dashboards in a host application

Setup these users credential in env vars:
- general api calls,   `ENV['SUPERSET_API_USERNAME']` and `ENV['SUPERSET_API_PASSWORD']` 
- embedded user calls, `ENV['SUPERSET_EMBEDDED_USERNAME']` and `ENV['SUPERSET_EMBEDDED_PASSWORD']`

### API calls

WIP

### Fetch a Guest Token

WIP

## Development

After checking out the repo, run `bundle exed rspec` to run the tests. You can also run `bin/console` for an interactive pry prompt that will allow you to experiment.

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

## Contributing

WIP

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
