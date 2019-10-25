# Chef Habitat package: Grafana

## Description

This Chef Habitat package installs Grafana for linux using standalone binaries. By default, it does not include any datasources and listens on port 8000, and can be configured with a certificate/key.

Note this is based off `core/grafana` (https://github.com/habitat-sh/core-plans/blob/master/grafana), though slightly slimmed down and updated.

## Usage

The package can be loaded using `hab svc load` and will come up in a blank state, ready for DataSources and Dashboards to be added by the user.
