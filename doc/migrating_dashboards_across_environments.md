# Transfering Dashboards across Environments

Research document relating to Migrating dashboard across Superset Environments.

In this doc, we will discuss how to transfer dashboards across Superset hosting environments.

A common practice is to setup infrastructure to deploy multiple Superset environments. For example a simple setup might be:
- local development env for testing version upgrades and feature exploration
- staging superset env for testing in a production like environment
- production superset env that requires a higher level of stability and uptime

For the above example, the Superset staging env often holds connections to staging databases, and the Superset production staging env will hold connections to the production databases.

In the event where the database schema structure for the local dev, staging and production databases are exactly the same, then dashboards can be transfered across Superset hosting environments.

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
    │   ├── Number_of_Deals_for_each_Combination_147.yaml
    │   ├── Overall_Sales_By_Product_Line_150.yaml
    │   ├── Proportion_of_Revenue_by_Product_Line_190.yaml
    │   ├── Quarterly_Sales_198.yaml
    │   ├── Quarterly_Sales_By_Product_Line_178.yaml
    │   ├── Revenue_by_Deal_Size_162.yaml
    │   ├── Seasonality_of_Revenue_per_Product_Line_180.yaml
    │   ├── Total_Items_Sold_158.yaml
    │   ├── Total_Items_Sold_By_Product_Line_191.yaml
    │   └── Total_Revenue_194.yaml
    ├── dashboards
    │   └── Sales_Dashboard_8.yaml
    ├── databases
    │   └── examples.yaml
    ├── datasets
    │   └── examples
    │       └── cleaned_sales_data.yaml
    └── metadata.yaml
```

Each of the above yaml files holds UUID values for the primary object and any related objects.

- database yamls hold the database conn string as well as a UUID for the database
- dataset yamls have their own UUID as well as a referene to the database UUID
- chart yamls have their own UUID as well as a reference to their dataset UUID

If we grep the database/examples.yaml we can see the UUID of the database.

```
grep -r uuid databases/
  databases/examples.yaml:uuid: a2dc77af-e654-49bb-b321-40f6b559a1ee

```

Now if we look at the UUID values in the datasets, you will see both the dataset UUID and the referenc to the database UUID.

```
grep -r uuid datasets
datasets/examples/cleaned_sales_data.yaml:uuid: 2ebaf597-6bb6-4e1a-b3dd-f2d808bdd1ce
datasets/examples/cleaned_sales_data.yaml:database_uuid: a2dc77af-e654-49bb-b321-40f6b559a1ee
```

If we have an export from Staging Env, and an export from the Production Env, and we compared the database UUIDs and dataset UUIDs you would see that the UUIDs are unique to the Environment or Supserset instance and that the database connection string would also be unique to each env.

# Migrate a dashboard across to a different Superset Environment

Given we have a request to 'transfer' a dashboard across to a different environment, say Staging to Production.

With the condition that the database in Staging and Production are structuraly exactly the same schema.  From above discussion on UUIDs, you can then see that if we want to import a Staging dashboard export into the Production environment we will need to perform the following steps:

- 1. export the staging dashboard and unzip
- 2. note the staging database UUIDs in the `databases/` directiory
- 3. get a copy of the production database yaml file ( from a production dashboard export )
- 4. in the exported dashboard files, replace the staging database yaml with the production yaml
- 5. in the dataset yaml files, replace all instances of the previous noted staging database uuid with the new production UUID
- 6. zip the files and import to the production environment

## Assumptions / Directions

The process above assumes that whoever is migrating the dashboard has a copy of the target database yml files so that
in step 3 and 4 we can then replace the staging database yaml with the production one.

Potentially we could store all database yml files in the superset-acumania repo, where we currently store the dashboard backups.

Then we could use that list, as part of the script class calls to Export -> manipulate yaml file -> Import to new Env

Some more helpful references relating to cross environment workflows.

- https://docs.preset.io/docs/managing-content-across-workspaces
- also SS Slack AI provides a good explanation https://apache-superset.slack.com/archives/C072KSLBTC1/p1722382347022689

