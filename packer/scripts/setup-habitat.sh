#!/bin/bash -e

export HAB_LICENSE=accept-no-persist

_install_hab(){
    echo "Installing Habitat..."
    local __HAB_VERSION=${1:-}

    # Setup Installation Arguments
    __INSTALL_ARGS=""
    if [ -n "${__HAB_VERSION}" ]; then
        echo "Found version ${__HAB_VERSION} supplied for Habitat installation"
        __INSTALL_ARGS+=" -v ${__HAB_VERSION}"
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

# Install habitat if it is not installed, or HAB_VERSION is supplied and does not match the hab version
if command -v hab &> /dev/null; then
    __INSTALLED_VERSION=$(hab --version)
    echo "Found Habitat installation, version ${__INSTALLED_VERSION}"

    if [ -z ${HAB_VERSION} ]; then
        echo "No Habitat version provided"
        echo "You can provide a Habitat version using environment variable HAB_VERSION"
        echo "Skipping Habitat installation..."
    elif [[ "${__INSTALLED_VERSION}" != *"${HAB_VERSION}"* ]]; then
        echo "Installed version does not match required version ${HAB_VERSION}"
        _install_hab "${HAB_VERSION}"
    else
        echo "Installed Habitat version matches required version ${HAB_VERSION}"
    fi
else
    echo "Hab installation not found"
    _install_hab "${HAB_VERSION}"
fi

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
