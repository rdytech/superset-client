## Change Log

## 0.2.1 - 2024-09-17

* add Superset::Database::Export class for exporting database configurations
* add Superset::Dashboard::Import class for importing a dashboards

## 0.2.0 - 2024-08-19

* Adding RLS filter clause to the 'api/v1/security/guest_token/' API params in guest_token.rb - https://github.com/rdytech/superset-client/pull/31
* Any filter that needs to applied to the dataset's final where condition can be passed here. Ex: [{ "clause": "publisher = 'Nintendo'" }]. Refer this: https://github.com/apache/superset/tree/master/superset-embedded-sdk#creating-a-guest-token

## 0.1.7 - 2024-08-27

* adds filter title_equals to dashboard list class - https://github.com/rdytech/superset-client/pull/33

## 0.1.6 - 2024-07-10

* added a class **WarmUpCache** to hit the 'api/v1/dataset/warm_up_cache' endpoint to warm up the cache of all the datasets for a particular dashaboard being passed to the class - https://github.com/rdytech/superset-client/pull/28

## 0.1.5 - 2024-05-10

* add multi config for multi env creds https://github.com/rdytech/superset-client/pull/22
* add endpoint for sqllab/execute https://github.com/rdytech/superset-client/pull/22
* add endpoint for database/list https://github.com/rdytech/superset-client/pull/22
* add delete cascade endpoint by @jbat in https://github.com/rdytech/superset-client/pull/21

## 0.1.4 - 2024-05-01

* Filter dashboards by array of tags by @jbat in https://github.com/rdytech/superset-client/pull/20
* adds endpoints for Delete of dashboards, charts, datasets @jbat in https://github.com/rdytech/superset-client/pull/20
* adds endpoints for BulkDelete of dashboards, charts, datasets @jbat in https://github.com/rdytech/superset-client/pull/20

## 0.1.3 - 2024-04-23

* duplicate dashboard should also create embedded setting by @jbat in https://github.com/rdytech/superset-client/pull/14
* Validate and duplicate filters to new dashboard by @vidishaweddy-readytech in https://github.com/rdytech/superset-client/pull/17
* duplicate cross filters by @jbat in https://github.com/rdytech/superset-client/pull/18

## 0.1.2 - 2024-03-22

* adds export endpoint

## 0.1.1 - 2024-03-14

* superset pipeline part 1 with supported endpoints by @jbat in https://github.com/rdytech/superset-client/pull/4
* API update chart to new dataset by @hanpeic in https://github.com/rdytech/superset-client/pull/5
* Adds DuplicateDashboard class and fixes by @jbat in https://github.com/rdytech/superset-client/pull/6
* Update Docs by @jbat in https://github.com/rdytech/superset-client/pull/7
* update cred docs by @jbat in https://github.com/rdytech/superset-client/pull/8
* more updates to DuplicateDashboard, extra endpoints by @jbat in https://github.com/rdytech/superset-client/pull/9

## 0.1.0 - 2023-12-12

- add base classes for credentials, authentication, client, request
- add dashboard endpoints
- add security/user endpoints
- add security/role endpoints
- add security/role/permission endpoints



