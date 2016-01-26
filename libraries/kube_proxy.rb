module KubernetesCookbook
  class KubeProxy < Chef::Resource
    resource_name :kube_proxy

    default_action :create

    action :create do
      remote_file 'kube-proxy binary' do
        path '/usr/sbin/kube-proxy'
        mode '0755'
        source 'https://storage.googleapis.com/kubernetes-release/release/v1.1.3/bin/linux/amd64/kube-proxy'
        #checksum '62191c66f2d670dd52ddf1d88ef81048977abf1ffaa95ee6333299447eb6a482'
      end
    end

    action :start do
      template '/etc/systemd/system/kube-proxy.service' do
        source 'systemd/kube-proxy.service.erb' 
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
