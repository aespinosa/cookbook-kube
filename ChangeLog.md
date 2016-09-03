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
