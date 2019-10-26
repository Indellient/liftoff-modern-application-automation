# Policyfile.rb - Describe how you want Chef to build your system.
#
# For more information on the Policyfile feature, visit
# https://docs.chef.io/policyfile.html

# A name that describes what the system you're building with Chef does.
name 'linux-base-applications'

# Where to find external cookbooks:
default_source :supermarket
default_source :chef_repo, './cookbooks' do |s|
    s.preferred_for 'base-applications', 'habitat'
end

named_run_list 'bootstrap', 'base-applications::default'

# run_list: chef-client will run these recipes in the order specified.
run_list 'base-applications::default'

default['applications'] = {
    :linux => {
        'liftoff-modern-application-delivery/inspec-linux-audit' => {},
        'liftoff-modern-application-delivery/infra-linux-hardening' => {}
    }
}
