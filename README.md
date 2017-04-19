# kube cookbook

The kube cookbook is a Library cookbook that provides custom resources for
managing various components of a Kubernetes cluster.

## Requirements

* Chef 12.5 or higher. Chef 11 and 12.0-12.4 is NOT SUPPORTED.  Please do not
  open issues about it.
* Network accessible web server hosting the Kubernetes binaries.

## Cookbook Dependencies

None

## Custom Resources

Components for a kubernetes node:

* kubelet
* kube_proxy

Components for a kubernetes master:

* kube_apiserver
* kube_scheduler
* kube_controller_manager

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
