# Transferring Dashboards across Environments

In this doc, we will discuss how to transfer dashboards across Superset hosting environments with the goal of heading towards an API call to automate the process.

## Background

A common practice is to setup infrastructure to deploy multiple Superset environments. For example a simple setup might be:
- local development env for testing version upgrades and feature exploration
- staging superset env for testing in a production like environment
- production superset env that requires a higher level of stability and uptime

For the above example, the Superset staging env often holds connections to staging databases, and the Superset production staging env will hold connections to the production databases.

In the event where the database schema structure for the local dev, staging and production databases are exactly the same, then dashboards can be transferred across Superset hosting environments.

It requires some manual updating of the exported yaml files before importing into the target environment.  Also required is some understanding of the underlying dashboard export structure and how the a object UUIDs work and relate to each other expecially in the context of databases and datasets.

## Dashboard Export/Import within same Environment

This is a fairly straight forward process.

There are multiple methods for exporting a dashboard.
- Export from the dashboard list page
- Export via the Superset API
- Export via the Superset CLI

Each method will result in zip file that contains a set of yaml files as per this list below which is an export of the Sales dashboard from the default examples dashboards.

```
.
├── dashboard_8_export_20240731.zip
└── dashboard_export_20240730T231449
    ├── charts
    │   ├── Number_of_Deals_for_each_Combination_147.yaml
    │   ├── Overall_Sales_By_Product_Line_150.yaml
    │   ├── Proportion_of_Revenue_by_Product_Line_190.yaml
    │   ├── Quarterly_Sales_198.yaml
    │   ├── Quarterly_Sales_By_Product_Line_178.yaml
    │   ├── Revenue_by_Deal_Size_162.yaml
    │   ├── Seasonality_of_Revenue_per_Product_Line_180.yaml
    │   ├── Total_Items_Sold_158.yaml
    │   ├── Total_Items_Sold_By_Product_Line_191.yaml
    │   └── Total_Revenue_194.yaml
    ├── dashboards
    │   └── Sales_Dashboard_8.yaml
    ├── databases
    │   └── examples.yaml
    ├── datasets
    │   └── examples
    │       └── cleaned_sales_data.yaml
    └── metadata.yaml
```

Each of the above yaml files holds UUID values for the primary object and any related objects.

- database yamls hold the database conn string as well as a UUID for the database
- dataset yamls have their own UUID as well as a referene to the database UUID
- chart yamls have their own UUID as well as a reference to their dataset UUID

Example of the database yml file.

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
datasets/examples/cleaned_sales_data.yaml:uuid: 2ebaf597-6bb6-4e1a-b3dd-f2d808bdd1ce
datasets/examples/cleaned_sales_data.yaml:database_uuid: a2dc77af-e654-49bb-b321-40f6b559a1ee
```

If the above zip file was imported as is to the same superset environment, this would mean all UUID's exist in superset and these objects would be found an updated with the imported zip data.

If the above zip file was imported to a different target superset environment, it would fail as there would be no matching database UUID entry in that target superset environment.

# Migrate a dashboard across to a different Superset Environment

Give the above knowledge, we can now think about how to migrate boards between superset environments. 

If we have an export from Staging Env, and an export from the Production Env, and we compared the database UUIDs and dataset UUIDs you would see that the UUIDs are unique to the Environment or Supserset instance and that the database connection string would also be unique to each env.

Given we have a request to 'transfer' a dashboard across to a different environment, say Staging to Production, how would we then proceed?

With the condition that the database in Staging and Production are structurally exactly the same schema.  From above discussion on UUIDs, you can then see that if we want to import a Staging dashboard export into the Production environment we will need to perform the following steps:

- 1. export the staging dashboard and unzip
- 2. note the staging database UUIDs in the `databases/` directory
- 3. get a copy of the production database yaml file ( from a production dashboard export )
- 4. in the exported dashboard files, replace the staging database yaml with the production yaml
- 5. in the dataset yaml files, replace all instances of the previous noted staging database uuid with the new production UUID
- 6. zip the files and import to the production environment

The process above assumes that whoever is migrating the dashboard has a copy of the target database yml files so that
in step 3 and 4 we can then replace the staging database yaml with the production one.


## Requirements

For the above process we need to know or have access to the following:

- the source dashboard zip file
- the target SS environment database yaml file
- ability to copy then manipulate the source dashboard zip file
- the ability to import via api to the target SS environment

The ideal process for creating a dashboard is to create the initial template version on the staging (or edge) environment, then backup that dashboard.
As this template can be considered the source dashboard, it makes logical sense to use that backup to replicate into a different environment.

Potentially an export of database yml files could be stored into a separate repo/location, similar to where you may store Superset dashboard backup exports.

Then with those database yaml files available, the process would be something like Dashboard Export -> add new target database yml -> manipulate yaml files -> Import to new Env


## Gotchas !

Migrating a Dashboard ONCE .. to a new target env, database, schema will result in 
- creating a new Dashboard with the uuid from the import zip
- creating a new set of Charts with their uuid's from the import zip
- creating a new set of Datasets with their uuid's form the import zip


Migrating the same Dashboard a second time, to the same target env, database, BUT different schema will NOT create a new Dashboard.

It will attempt to update the same Dashboard .. as the UUID for the dashboard has not changed.
It will also NOT change any of the Datasets to the new schema.  Looks to be a limitation of the import process

This may lead to some confusing results.


## References

Some more helpful references relating to cross environment workflows.

- https://docs.preset.io/docs/managing-content-across-workspaces
- also SS Slack AI provides a good explanation https://apache-superset.slack.com/archives/C072KSLBTC1/p1722382347022689
