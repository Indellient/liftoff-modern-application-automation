# infra-linux-base-applications

This Chef Effortless-based Habitat packages makes use of Chef Infra scaffolding, directly modified from the example provided in the [effortless repository](https://github.com/chef/effortless/tree/master/examples/infra-linux-policyfile-cookbook) and is used to provision base applications for the demo machines.

This package makes use of two local cookbooks
 - A "base applications" cookbook that makes use of Habitat and allows the user to run the cookbook in two modes, a bootstrap mode and a regular mode. The bootstrap mode will install, but not run, all relevant service. The regular mode will load the services with the appropriate parameters (i.e. strategy, etc).
 
 - A Habitat cookbook. Forked from the [Supermarket Habitat Cookbook](https://github.com/chef-cookbooks/habitat), this is updated to support 0.88, and certain files were removed to slim down the directory.
