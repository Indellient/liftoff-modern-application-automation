# Habitat Services

Used to load Habitat-packaged applications. You can specify the applications per-platform with the following syntax in your Policyfile:
```
default['applications'] = {
  'bldr_url' => '<optional-builder-url>',
  'linux' => {
    '<origin>/<service-1>' => {
        'version' => '<optional-version>'
    },
    '<origin>/<service-2>' => {}
  },
  'windows' => {
    '<origin>/<service-1>' => {}
  }
}
```

Note that this cookbook will recognize a `BOOTSTRAP` environment variable which allows the chef-client to run once, installing the packages but not running them to create an image for deployment. This may be used when installed in the Habitat package as so:

```
BOOTSTRAP=true sudo -E hab pkg exec $pkg_ident chef-client -z -c $(hab pkg path $pkg_ident)/chef/client-config.rb
``` 

