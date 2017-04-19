# kube cookbook

The kube cookbook is a Library cookbook that provides custom resources for
managing various components of a Kubernetes cluster.

## Requirements

* Chef 12.5 or higher. Chef 11 and 12.0-12.4 is NOT SUPPORTED.  Please do not
  open issues about it.
* Network accessible web server hosting the Kubernetes binaries.

## Cookbook Dependencies

None

## Usage

* Add `'kube', '~> 2.0'` to your cookbook's `metadata.rb`.
* Use the resources shipped in this cookbook in your recipes the same way you
  use core Chef resources like file, template, directory, package, etc.

```
# Master
kube_apiserver 'default' do
  service_cluster_ip_range '10.0.0.1/24'
  etcd_servers 'http://127.0.0.1:4001'
  insecure_bind_address '0.0.0.0' # for convenience
  action %w(create start)
end

kube_scheduler 'default' do
  action %w(create start)
end

kube_controller_manager 'default' do
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
  action %w(create start)
end
```

The test cookbook ran under test-kitchen provide good usage examples.   It is
found in `test/cookbooks/kube_test`.

## Resources Overview

Components for a Kubernetes node:

* `kubelet`
* `kube_proxy`

Components for a Kubernetes master:

* `kube_apiserver`
* `kube_scheduler`
* `kube_controller_manager`

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
