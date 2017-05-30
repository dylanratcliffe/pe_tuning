# pe_tuning

**NOTE: This is an initial release and the values are mostly guesses. I will not be standing behind the recommendation until v1.0.0**

## Description

This module provides guidance for tuning Puppet Enterprise masters given current system size.

The module provides the following sets of values: `monolithic`, `mom` and `compile`. Monolithic values are for Puppet masters which are the only master in an environment. MoM values are tailored the master of masters in a setup that has compile masters. Compile values are for the compile masters in these environments. Unsurprisingly.

## Facts


## Usage

This module is designed to produce facts that are interpreted in hiera data. The below example is hieradata that will configure a monolithic master with optimal values:

```yaml
# common.yaml

puppet_enterprise::master::puppetserver::jruby_max_active_instances: "%{pe_tuning.puppetserver.monolithic.jruby_max_active_instances}"
puppet_enterprise::profile::master::java_args: "%{pe_tuning.puppetserver.monolithic.java_args}"

puppet_enterprise::puppetdb::command_processing_threads: "%{pe_tuning.puppetdb.monolithic.command_processing_threads}"
puppet_enterprise::profile::puppetdb::java_args: "%{pe_tuning.puppetdb.monolithic.java_args}"

puppet_enterprise::profile::console::java_args: "%{pe_tuning.console.monolithic.java_args}"
puppet_enterprise::profile::orchesrator::java_args: "%{pe_tuning.orchesrator.monolithic.java_args}"
```
