name 'base-applications'
maintainer 'Indellient DevOps'
maintainer_email 'Indellient DevOps <devops@indellient.com>'
license 'All Rights Reserved'
description 'Installs/Configures Chef Habitat services'
long_description 'Installs/Configures Chef Habitat services'
version '0.1.0'
chef_version '>= 12.1' if respond_to?(:chef_version)

depends 'habitat'

# The `issues_url` points to the location where issues for this cookbook are
# tracked.  A `View Issues` link will be displayed on this cookbook's page when
# uploaded to a Supermarket.
#
# issues_url 'https://github.com/<insert_org_here>/bp_applications/issues'

# The `source_url` points to the development repository for this cookbook.  A
# `View Source` link will be displayed on this cookbook's page when uploaded to
# a Supermarket.
#
# source_url 'https://github.com/<insert_org_here>/bp_applications'
