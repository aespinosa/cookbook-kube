# kube cookbook

The kube cookbook is a Library cookbook that provides custom resources for
managing various components of a Kubernetes cluster.

## Requirements

### Chef

* Chef 12.11 or higher

### Platforms

* Ubuntu 16.04+
* Debian 8+
* RHEL 7+

### Cookbook Dependencies

- None

## Usage

* Add `'kube', '~> 2.0'` to your cookbook's `metadata.rb`.
* Use the resources shipped in this cookbook in your recipes the same way you
  use core Chef resources like file, template, directory, package, etc.

```ruby
# Master
kube_apiserver 'default' do
  service_cluster_ip_range '10.0.0.1/24'
  etcd_servers 'http://127.0.0.1:2379'
  insecure_bind_address '0.0.0.0' # for convenience
  action %w(create start)
end

kube_scheduler 'default' do
  master '127.0.0.1:8080'
  action %w(create start)
end

kube_controller_manager 'default' do
  master '127.0.0.1:8080'
  action %w(create start)
end

# Node

kubelet_service 'default' do
  api_servers 'http://127.0.0.1:8080'
  config '/etc/kubernetes/manifests'
  cluster_dns '10.0.0.10'
  cluster_domain 'cluster.local'
  action %w(create start)
end

kube_proxy 'default' do
  master '127.0.0.1:8080'
  action %w(create start)
end
```

The test cookbook ran under test-kitchen provide good usage examples.  It is
found in `test/cookbooks/kube_test`.

## Resources Overview

Components for a Kubernetes node:

* `kubelet`
* `kube_proxy`

Components for a Kubernetes master:

* `kube_apiserver`
* `kube_scheduler`
* `kube_controller_manager`

### Common Properties

All the above resources will contain the following properties:

* `remote` - The URL of where a corresponding component's binary can be
  downloaded.  The default value points to the official Kubernetes release URL of
  each component.  Check each resource for the default value of each component.
* `version` - The version of the Kubernetes artifact to pull down.  Defaults to
  `'1.7.5'`.  NOTE: This will be ignored if you set the `remote` property
  instead.
* `checksum` - The SHA256 hash of the Kubernetes component's binary.
* `run_user` - The user in which to run the Kubernetes user.  Defaults to
  `'kubernetes'`.
* `file_ulimit` - The file ulimit value to set for the services - Integer.
  Defaults to `65536`

### Common Actions

All the above resources will contain the following actions:

* `create` - Download the Kubernetes component's binary to `/usr/bin`.
* `start` - Starts the Kubernetes component managed through a systemd unit.

## Resource Properties

Each resource' set of unique properties corresponds to the options in the
Kubernetes component they represent:

* `kube_apiserver` - <https://github.com/kubernetes/kubernetes.github.io/blob/release-1.7/docs/admin/kube-apiserver.md>
* `kube_controller_manager` - <https://github.com/kubernetes/kubernetes.github.io/blob/release-1.7/docs/admin/kube-controller-manager.md>
* `kube_scheduler` - <https://github.com/kubernetes/kubernetes.github.io/blob/release-1.7/docs/admin/kube-scheduler.md>
* `kubelet` - <https://github.com/kubernetes/kubernetes.github.io/blob/release-1.7/docs/admin/kubelet.md>
* `kube_proxy` - <https://github.com/kubernetes/kubernetes.github.io/blob/release-1.7/docs/admin/kube-proxy.md>

In general, a command line flag of the form `--long-option` will correspond to a
custom resource property called `long_option`.

### Extending Properties

When newer versions of Kubernetes are released, components might introduce and
deprecate some commandline flags that are not yet hard-coded as properties.

To add these properties, a wrapper cookbook can be written like the following:

```ruby
# wrapper-cookbook/metadata.rb
name 'wrapper-cookbook'
depends 'kube', '~> 2.0' # Make sure you have this

# wrapper-cookbook/libraries/apiserver.rb
class KubernetesCookbook::KubeApiserver
  property :something_only_in_kubernetes9000
end
```

The `kube_apiserver` resource can now use the new commandline flag available in
Kubernetes v9000 like the following:

```ruby
# wrapper-cookbook/recipes/default.rb
kube_apiserver 'default' do
  something_only_in_kubernetes9000 'someflag'
end
```

## License

Copyright 2016-2017 Allan Espinosa

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
