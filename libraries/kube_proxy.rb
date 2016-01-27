module KubernetesCookbook
  # Resource for managing a kube-proxy
  class KubeProxy < Chef::Resource
    resource_name :kube_proxy

    default_action :create

    action :create do
      remote_file 'kube-proxy binary' do
        path '/usr/sbin/kube-proxy'
        mode '0755'
        source 'https://storage.googleapis.com/kubernetes-release'\
               '/release/v1.1.3/bin/linux/amd64/kube-proxy'
        checksum 'b6f1cd2fc55f81bd700b92490a8be950'\
                 '446bd494067d1ed2a3ed9cc2ecf059f8'
      end
    end

    action :start do
      template '/etc/systemd/system/kube-proxy.service' do
        source 'systemd/kube-proxy.service.erb'
        cookbook 'kube'
        notifies :run, 'execute[systemctl daemon-reload]', :immediately
      end

      execute 'systemctl daemon-reload' do
        command 'systemctl daemon-reload'
        action :nothing
      end

      service 'kube-proxy' do
        action %w(enable start)
      end
    end
  end
end
