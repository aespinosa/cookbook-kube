include_recipe 'apt'

apt_repository 'docker' do
  uri 'http://proxy.dev:3142/apt.dockerproject.org/repo'
  components %w(debian-jessie main)
  keyserver 'p80.pool.sks-keyservers.net'
  key '58118E89F3A912897C070ADBF76221572C52609D'
  cache_rebuild true
end

etcd_service 'default' do
  source 'http://proxy.dev:3142/github.com/coreos/etcd/releases/download/v2.2.3/etcd-v2.2.3-linux-amd64.tar.gz '
  version '2.2.3'
  service_manager 'systemd'
  action %w(create start)
end

flannel_service 'default' do
  action %w(create start)
end.extend FlannelCookbook::SubnetParser

docker_service 'default' do
  bip lazy { resources('flannel_service[default]').subnetfile_subnet }
  mtu lazy { resources('flannel_service[default]').subnetfile_mtu }
  install_method 'package'
  version '1.9.1'
end
