include_recipe 'apt'

docker_service 'default' do
  version '1.9.1'
end

kube_master 'default' do
  action :create
end
