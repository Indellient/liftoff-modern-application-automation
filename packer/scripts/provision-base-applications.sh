#!/bin/bash

export HAB_LICENSE=accept-no-persist

if [ -n "${HAB_PACKAGE}" ]; then
    echo "Found package to bootstrap node with: ${HAB_PACKAGE}"

    echo "Installing package..."
    sudo -E hab pkg install "${HAB_PACKAGE}"

    # Run chef-client using the bootstrap config
    __PACKAGE_PATH=$(hab pkg path ${HAB_PACKAGE})
    pushd ${__PACKAGE_PATH}
        echo "Installing package..."
        BOOTSTRAP=true sudo -E hab pkg exec ${HAB_PACKAGE} chef-client -z -c ${__PACKAGE_PATH}/config/bootstrap-config.rb
    popd

    # Install spec file - this will cause application to start up with the Chef Habitat Supervisor
    echo "Enabling package to run at Supervisor Startup..."
    sudo mkdir -p /hab/sup/default/specs
    sudo bash -c "cat > /hab/sup/default/specs/$(echo ${HAB_PACKAGE} | awk -F/ '{print $2}').spec" <<SPEC
ident           = "${HAB_PACKAGE}"
group           = "default"
bldr_url        = "https://bldr.habitat.sh"
channel         = "stable"
topology        = "standalone"
update_strategy = "at-once"
binds           = []
binding_mode    = "strict"
desired_state   = "up"

[health_check_interval]
secs  = 30
nanos = 0
SPEC

else
    echo "No package found to bootstrap node with!"
    echo "Did you export HAB_PACKAGE?"
    echo "Exiting..."
fi

