# Puppetlabs-Onceover-Lookup

Lookup (hiera) support for 
[Onceover](https://github.com/dylanratcliffe/onceover) - _The gateway drug to 
automated infrastructure testing with Puppet_.

Debugging failed or unexpected lookups usually requires access to the Puppet
Master. This plugin aims to enable onceover users to perform _basic_ lookups
from the comfort of their workstation.

## How it works
The plugin configures and wraps the `puppet lookup` command to work with a onceover enabled control
repository. 

Users may then use the `--passthru` argument to pass arguments through to the 
raw `puppet lookup` command and the plugin also provides a means to re-write
factsets to work with the the `puppet lookup` command.

## Installation
Add `puppetlabs-onceover-lookup` to your `Gemfile` and run `bundle install`:

**Gemfile**
```ruby
gem 'puppetlabs-onceover-lookup'
```

## Configuration
Onceover-lookup requires a valid puppet configuration file at 
`.puppet.conf.onceover` which must exist before you can perform lookups.

To create this file initially or to reset to defaults:
 
```shell
bundle exec puppetlabs-onceover run lookup setup
```

Once the file is created, you can edit/maintain it yourself.

This command also creates a skeleton directory structure for a mock puppet CA at
`spec/ssl` and includes instructions on how to create one, should you wish to.

### /spec/hiera.yaml
If your project contains `spec/hiera.yaml` then we will automatically configure
onceover-lookup to use it via `.puppet.conf.onceover`

Using this file lets you have a specific hierarchy for testing or lets you
place a _test_ hierarchy above the regular one.

**Example**

```yaml
# /hiera.yaml
#
# Configure hiera to mirror real customer data, inserting mock data for testing
# at the top level of the hierarchy
---
version: 5

hierarchy:
  - name: 'mock hiera data for testing'
    data_hash: yaml_data
    datadir: "mockdata"
    paths:
      - "os/%{facts.safe_os.family}_%{facts.safe_os.release.major}.yaml"

  - name: "live customer data"
    data_hash: yaml_data
    datadir: "../data"
    paths:
      - "node/%{trusted.certname}.yaml"
      - "customer_env/%{trusted.extensions.pp_environment}.yaml"
      - "os/%{facts.safe_os.family}_%{facts.safe_os.release.major}.yaml"
      - 'common.yaml'
```

* In this example we have used the 
  [safe_roles](https://forge.puppet.com/geoffwilliams/safe_roles/readme) puppet
  module to normalise OS names and versions
* You can use a custom factset to mock these as required

### /hiera.yaml
If you have a `hiera.yaml` at the top of your control repository and do not have
a `spec/hiera.yaml` file, we will use this to configure a test hierarchy.

You must create this file yourself if missing.

### Factsets
Onceover can be configured to use 
[factsets](https://github.com/dylanratcliffe/onceover#factsets) and 
`puppet lookup` can use the `--facts` argument to specify a list of facts to use
during the lookup, overriding those obtained from PuppetDB which we do not use.

The format of these two files is incompatible:
* Factsets are obtained from the `puppet facts` command, fact output is stored
  in the `values` key
* Fact files for `puppet lookup` are created manually and are simple key-value
  pairs
  
Attempting to use Onceover factsets with `puppet lookup` will result in an error
from Puppet:

```shell
Error: Could not run: Cannot reassign variable '$name'
``` 

To workaround this, use the `--factset` argument to onceover-lookup (not inside
`--passthru`) and we will rewrite the factset to a format that `puppet lookup`
can use.

### Limitation
It is an error have _neither_ `/hiera.yaml` or `/spec/hiera.yaml`.

## Usage

### Help on onceover-lookup

```shell
bundle exec puppetlabs-onceover run lookup --help
```

### Help on puppet lookup
```shell
bundle exec puppetlabs-onceover run lookup --passthru="--help"
```

### Lookup a value and explain
```shell
bundle exec puppetlabs-onceover run lookup --passthru="profile::foo::bar --explain"
```

### Lookup a value using a named factset from onceover

```shell
bundle exec puppetlabs-onceover run lookup --passthru="profile::foo::bar --explain" --factset CentOS-7.0-64
```

* Since factsets are files, names are case-sensitive

### Lookup a value using your own custom factset

```shell
bundle exec puppetlabs-onceover run lookup --passthru="profile::foo::bar --explain" --factset spec/factsets/Windows_Server-2012r2-64-choco.json
```

* Since factsets are files, names are case-sensitive

### Debug Puppet during a lookup/provide trace information

```shell
bundle exec puppetlabs-onceover run lookup --passthru="profile::foo::bar --explain --trace --evaltrace --debug"
```

* Parameters in `--passthru` are sent straight through to the `puppet lookup`
  command so you can use any supported option  

## FAQ/Gotchas

**Command Ordering**

To avoid the shell misinterpreting your `--passthru` argument, use the form:

```shell
--passthru="xxx"
```

**Confusing --facts and --factset**

You can run with `--passthru="blah blah --facts /path/to/facts/file.json"` and
`puppet lookup` itself will attempt to resolve facts from the named file (which
must not be a _factset_!)

Alternatively, specify `--factset` outside the `--passthru` argument and 
onceover-lookup will rewrite the named factset for you and use it for the
lookup.

It is an error to use both `--facts` and `--factset`.

**I see strange access denied errors when I do lookups - what gives? Are you trying to hack my system?**

When the `puppet lookup` command is run, any facts in your `Puppetfile` and 
claimed by the current operating will also run. Since many of these facts expect
to run as `root` this can cause permission denied errors.

If the output of these facts is required, it can be added to a custom factset
and used at runtime with the `--factset` argument. The errors can otherwise be
ignored.

Full source code is available and you are welcome and encouraged to read and
understand what it does.

## Development

PRs welcome :)

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/puppetlabs/puppetlabs-onceover-lookup
