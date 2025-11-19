# Superset Client

[![Build status](https://badge.buildkite.com/fc7ee4a03e119a5d859472865fc0bdc9a6e46d51b7f5b8cd62.svg)](https://buildkite.com/jobready/superset-client)

The Repo is `superset-client` with the ruby gem named `superset`

All ruby classes are namespaced under `Superset::`

# Installation

## Setup API Credentials

Follow this to [setup your users API creds](https://github.com/rdytech/superset-client/tree/develop/doc/setting_up_personal_api_credentials.md)

Short version is .. copy the `env.sample` to `.env` and add edit values where applicable.  Opening a console with `bin/console` will then auto load the `.env` file.

## Docker Setup

Build, bundle and open a ruby console

```
docker-compose build
docker-compose run --rm app bundle install
docker-compose run --rm app bin/console

# note .. windows users may need to call ruby the bin/console file
docker-compose run --rm app ruby bin/console
```

## Setup Locally ( no docker )

Requires Ruby >= 3.0.0

Bundle install and open a ruby console.

```
bundle install
bin/console
```

## Including in a Ruby app

Add to your Gemfile `gem 'superset'`
And then execute: `bundle install`  
Or install it yourself as `gem install superset`

## Run specs

```
docker-compose run --rm app rspec
# or 
docker-compose run --rm app bash      # then run 'bundle exec rspec' from the container.
```


## Usage

Experiment with the API calls directly by open a pry console using  `bin/console`.

```ruby
Superset::Dashboard::List.call

superset_class_list # helper method to list all classes under Superset::
sshelp              # aliased for superset_class_list
```

More examples [listed here](https://github.com/rdytech/superset-client/tree/develop/doc/usage.md)


## Duplicating Dashboards

One Primary motivation behind this gem was to use the Superset API to duplicate dashboards, charts, datasets across multiple database connections.

Targeted use case was for superset embedded functionality implemented in a application resting on multi tenanted database setup.

See examples in [Duplicate Dashboards](https://github.com/rdytech/superset-client/tree/develop/doc/duplicate_dashboards.md)

## Moving / Transferring Dashboards across Environments

With a few configuration changes to an import file, the process can be codified to transfer a dashboard between environments.

See example in [Transferring Dashboards across Environments](https://github.com/rdytech/superset-client/tree/develop/doc/migrating_dashboards_across_environments.md)

## Contributing

- Fork it
- Create your feature branch (git checkout -b my-new-feature)
- Commit your changes (git commit -am 'Add some feature')
- Push to the branch (git push origin my-new-feature)
- Create new Pull Request



### Publishing to RubyGems

WIP .. direction is for this gem to be made public

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
