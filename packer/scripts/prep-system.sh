#!/bin/bash

# From https://github.com/Azure/WALinuxAgent#commands
# `-deprovision`: Attempt to clean the system and make it suitable for re-provisioning, by deleting the following:
#
#   * All SSH host keys (if Provisioning.RegenerateSshHostKeyPair is 'y' in the configuration file)
#   * Nameserver configuration in /etc/resolv.conf
#   * Root password from /etc/shadow (if Provisioning.DeleteRootPassword is 'y' in the configuration file)
#   * Cached DHCP client leases
#   * Resets host name to localhost.localdomain
#
#  **WARNING!** Deprovision does not guarantee that the image is cleared of all sensitive information and suitable for redistribution.
#
#` -deprovision+user`: Performs everything under deprovision (above) and also deletes the last provisioned user account and associated data.
sudo /usr/sbin/waagent -force -deprovision+user

# Sync: Force changed blocks to disk, update the super block.
# HISTSIZE=0 to not append to history
HISTSIZE=0 sync
