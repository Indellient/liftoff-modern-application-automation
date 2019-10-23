#!/bin/bash -e

echo "Starting ${0}"
export HAB_LICENSE=accept-no-persist

_install_hab(){
    local __HAB_VERSION=${1:-}

    # Setup Installation Arguments
    __INSTALL_ARGS=""
    if [ -n "${__HAB_VERSION}" ]; then
        echo "Found required version ${__HAB_VERSION} supplied for Habitat installation"
        __INSTALL_ARGS+=" -v ${__HAB_VERSION}"
    fi

    # Install habitat if it is not installed, or HAB_VERSION is supplied and does not match the hab version
    if command -v hab &> /dev/null; then
        local __INSTALLED_VERSION=$(hab --version)
        echo "Found Habitat installation, version ${__INSTALLED_VERSION}"

        if [ -z ${__HAB_VERSION} ]; then
            echo "No Habitat version provided"
            echo "You can provide a Habitat version using environment variable HAB_VERSION"
            echo "Skipping Habitat installation..."
            return 0
        elif [[ "${__INSTALLED_VERSION}" != *"${__HAB_VERSION}"* ]]; then
            echo "Installed version does not match required version ${__HAB_VERSION}"
        else
            echo "Installed Habitat version matches required version ${__HAB_VERSION}"
            return 0
        fi
    else
        echo "Habitat installation not found"
    fi

    # Install with arguments
    echo "Installing Habitat with arguments '${__INSTALL_ARGS}'"
    curl --silent https://raw.githubusercontent.com/habitat-sh/habitat/master/components/hab/install.sh \
        | sudo -E bash -s -- ${__INSTALL_ARGS}

    if ! command -v hab &> /dev/null; then
        echo "Habitat installation failed."
        exit 1
    fi
}

_install_habitat_supervisor() {
    echo "Preparing Habitat Supervisor..."
    local __SUPERVISOR_SERVICE_NAME=${1:-hab-supervisor}

    sudo bash -c "cat > /etc/systemd/system/${__SUPERVISOR_SERVICE_NAME}.service" <<SERVICE
Description=Habitat Supervisor

[Service]
Environment=HAB_LICENSE=accept-no-persist
ExecStart=/bin/hab sup run
Restart=on-failure

[Install]
WantedBy=network.target
SERVICE

    sudo systemctl daemon-reload
    sudo systemctl enable ${__SUPERVISOR_SERVICE_NAME}
}

_install_hab "${HAB_VERSION}"
_install_habitat_supervisor

# Add hab user if it does not exist
if ! id hab &>/dev/null; then
    echo "'hab' user does not exist. Adding..."
    sudo useradd hab
else
    echo "'hab' user exists. Skipping add user"
fi

# Add hab group if it does not exist
if ! getent group hab &>/dev/null; then
    echo "'hab' group does not exist. Adding..."
    sudo groupadd hab
else
    echo "'hab' group exists. Skipping add group"
fi
