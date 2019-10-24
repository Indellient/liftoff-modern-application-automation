# Habitat package: grafana

## Description

This habitat package installs Grafana for linux using standalone binaries. By default, it does not include
any datasources, and listens on port 443 with a self-signed SSL certificate.

## Usage

When starting grafana svc with `--bind ds1:influxdb.default`, the pkg bind for that service will be automatically 
injected in to the Grafana datasources list when Grafana starts. Note that datasources defined in this manner are not 
editable by the Grafana UI.

If Grafana is started without datasources, it will come up in a blank state, ready for Datasources and Dashboards to be
added by the user.

## Adding Datasources

You can add more datasources by creating a new `[datasources.ds{N}]` entry in the default.toml, modifying and
`pkg_binds_optional` in `plan.sh`, and starting the grafana package with the new `--bind ds{X}:svc.group` flag added.

## Removing Datasources

If you remove one (or all) of the `--bind <...>` flags to the `hab svc load` command, the datasources will not be
written to the `datasources.yml` file.  However, Grafana still keeps a copy of those datasources in it's own config, and
they will be visible from the Grafana UI.
