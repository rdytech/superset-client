# Transferring Dashboards across Environments

In this document, we will discuss how to transfer dashboards across Superset hosting environments with the goal of heading towards an API call to automate the process.

Current process is limited to dashboards with all datasets based on a single database connection.

## Short Version

Assuming you want to transfer a dashboard from Env1 to Env2.

You will need the following:
- a Env1 Dashboard Export Zip file
- a Env2 Database config export yaml
- a Env2 schema to point your datasets to

Assuming your API env for ruby is setup for your target superset environment.
( ie using API creds for Env2 for this example )

```ruby

new_import_zip = Superset::Services::ImportDashboardAcrossEnvironments.new(
  dashboard_export_zip:      'path_to/dashboard_101_export_20241010.zip',
  target_database_yaml_file: 'path_to/env2_db_config.yaml', 
  target_database_schema:    'acme', 
  ).perform

# now import the adjusted zip to the target superset env
Superset::Dashboard::Import.new(source_zip_file: new_import_file).perform

```

## Background

A common practice is to set up infrastructure to deploy multiple Superset environments. For example, a simple setup might be:
- Local development environment for testing version upgrades and feature exploration
- Staging Superset environment for testing in a production-like environment
- Production Superset environment that requires a higher level of stability and uptime

For the above example, the Superset staging environment often holds connections to staging databases, and the Superset production environment will hold connections to the production databases.

In the event where the database schema structure for the local development, staging, and production databases are exactly the same, dashboards can be replicated and transferred across Superset hosting environments.

That process does require some manual updating of the exported YAML files before importing them into the target environment. Also required is some understanding of the underlying dashboard export structure and how the object UUIDs work and relate to each other, especially in the context of databases and datasets.

## Dashboard Export/Import within the Same Environment

This is a fairly straightforward process.

There are multiple methods for exporting a dashboard:
- Export from the dashboard list page in the GUI
- Export via the Superset API
- Export via the Superset CLI

Each export method will result in a zip file that contains a set of YAML files as per this list below, which is an export of customized version of the test Sales dashboard from the default example dashboards.

Test fixture is: https://github.com/rdytech/superset-client/blob/develop/spec/fixtures/dashboard_18_export_20240322.zip

```
└── dashboard_export_20240321T214117
    ├── charts
    │   ├── Boy_Name_Cloud_53920.yaml
    │   ├── Names_Sorted_by_Num_in_California_53929.yaml
    │   ├── Number_of_Girls_53930.yaml
    │   ├── Pivot_Table_53931.yaml
    │   └── Top_10_Girl_Name_Share_53921.yaml
    ├── dashboards
    │   └── Birth_Names_18.yaml
    ├── databases
    │   └── examples.yaml
    ├── datasets
    │   └── examples
    │       └── birth_names.yaml
    └── metadata.yaml
```

Each of the above YAML files holds UUID values for the primary object and any related objects.

- Database YAMLs hold the database connection string as well as a UUID for the database
- Dataset YAMLs have their own UUID as well as a reference to the database UUID
- Chart YAMLs have their own UUID as well as a reference to their dataset UUID

Example of the database YAML file:

```
cat databases/examples.yaml
database_name: examples
sqlalchemy_uri: postgresql+psycopg2://superset:XXXXXXXXXX@superset-host:5432/superset
cache_timeout: null
expose_in_sqllab: true
allow_run_async: true
allow_ctas: true
allow_cvas: true
allow_dml: true
allow_file_upload: true
extra:
  metadata_params: {}
  engine_params: {}
  metadata_cache_timeout: {}
  schemas_allowed_for_file_upload:
  - examples
  allows_virtual_table_explore: true
uuid: a2dc77af-e654-49bb-b321-40f6b559a1ee
version: 1.0.0
```

If we grep the database/examples.yaml we can see the UUID of the database.

```
grep -r uuid databases/
  databases/examples.yaml:uuid: a2dc77af-e654-49bb-b321-40f6b559a1ee

```

Now if we look at the UUID values in the datasets, you will see both the dataset UUID and the reference to the database UUID.

```
grep -r uuid datasets
datasets/examples/birth_names.yaml:uuid: 283f5023-0814-40f6-b12d-96f6a86b984f
datasets/examples/birth_names.yaml:database_uuid: a2dc77af-e654-49bb-b321-40f6b559a1ee
```

If the above dashboard zip file `dashboard_18_export_20240322.zip` was imported as is to the same superset environment as it was exported from, this would mean all UUID's would already exist in superset and these objects would be found and updated with the imported zip data.

If the above zip file was imported as is to a different target Superset environment, it would fail as there would be no matching database UUID entry in that target Superset environment.

**Key Point:** When importing a dashboard to a different Superset environment than the original environment, the database configuration in the zip export must exist in the target Superset environment and all datasets must point to the database config.

## Migrate a Dashboard to a Different Superset Environment

With the above knowledge, we can now think about how to migrate dashboards between Superset environments.

Each Superset object is given a UUID. Within the exported dashboard files, we are primarily concerned with:
- Replacing the staging database configuration with the production configuration
- Updating all staging datasets to point to the new production database UUID

Given we have a request to 'transfer' a dashboard across to a different environment, say staging to production, how would we then proceed?

With the condition that the database in staging and production are structurally exactly the same schema, from the above discussion on UUIDs, you can then see that if we want to import a staging dashboard export into the production environment, we will need to perform the following steps:

1. Export the staging dashboard and unzip
2. Note the staging database UUIDs in the `databases/` directory
3. Get a copy of the production database YAML configuration file
4. In the exported dashboard files, replace the staging database YAML with the production YAML
5. In the dataset YAML files, replace all instances of the previously noted staging database UUID with the new production UUID
6. Zip the files and import them to the production environment

The process above assumes that whoever is migrating the dashboard has a copy of the target database YAML files so that in steps 3 and 4 we can then replace the staging database YAML with the production one.

## Requirements

The overall process requires the following:
- The source dashboard zip file
- The target Superset environment database YAML file
- Ability to copy and manipulate the source dashboard zip file
- The ability to import via API to the target Superset environment


## Gotchas!

Migrating a dashboard once to a new target environment, database, schema will result in:
- Creating a new dashboard with the UUID from the import zip
- Creating a new set of charts with their UUIDs from the import zip
- Creating a new set of datasets with their UUIDs from the import zip

Migrating the same dashboard a second time to the same target environment, database, but different schema will NOT create a new dashboard.

It will attempt to update the same dashboard as the UUID for the dashboard has not changed. It will also NOT change any of the datasets to the new schema. This appears to be a limitation of the import process, which may lead to some confusing results.

## References

Some helpful references relating to cross-environment workflows:
- [Managing Content Across Workspaces](https://docs.preset.io/docs/managing-content-across-workspaces)
- [Superset Slack AI Explanation](https://apache-superset.slack.com/archives/C072KSLBTC1/p1722382347022689)