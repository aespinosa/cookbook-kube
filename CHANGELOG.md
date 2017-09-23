# 3.0.0

* Use kubernetes 1.7.6 by default.
* Add the `:version` property to pull version binaries upstream.
* Support other systemd-based platforms like CentOS and Ubuntu.
* Bump the minimum version required for the chef-client.
* Document how to anticipate newer versions of Kubernetes.

# 2.0.3

* Bump more metadata to pass Supermarket quality metrics.

# 2.0.2

* Bump documentation and other metadata information to pass Supermarket quality
  metrics.

# 2.0.1

* Document how to use the custom resources
* Update unit tests for Chef 13

# 2.0.0

* Update resource properties to commandline flags in 1.4.0

# 1.1.0

* Update resource properties to reflect kube 1.3.x commandline flags (#13)

# 1.0.0

* Bump kubernetes binaries to 1.3.6
* Remove cluster-name to the api-server parameters (#12)

# 0.4.0

* Set systemd unit flags to automatically start on boot
* Boot the kubelet only after the container runtime is available

# 0.3.0

* Introduce `remote` and `checksum` properties for downloading the binaries
* Fix hard-wired kube-proxy command in its systemd unit

# 0.2.0

* Complete commandline flags as resource properties for all the custom resources:

# 0.1.1

* Specify the cookbook in inline templates
* Move recipe to a test cookbook fixture

# 0.1.0

* Bare resources to boot a cluster
