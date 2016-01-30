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
        variables kube_proxy_command: generator.generate
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

    def generator
      CommandGenerator.new '/usr/sbin/kube-proxy', self
    end
  end

  # Command line properties for the kube-proxy
  # Reference: http://kubernetes.io/v1.1/docs/admin/kube-proxy.html
  class KubeProxy < Chef::Resource
    property :bind_address, default: '0.0.0.0'
    property :cleanup_iptables, default: false
    property :google_json_key
    property :healthz_bind_address, default: '127.0.0.1'
    property :healthz_port, default: 10_249
    property :hostname_override
    property :iptables_sync_period, default: '30s'
    property :kubeconfig
    property :log_flush_frequency, default: '5s'
    property :masquerade_all, default: false
    property :master
    property :oom_score_adj, default: -999
    property :proxy_mode
    property :proxy_port_range
    property :resource_container, default: '/kube_proxy'
    property :udp_timeout, default: '250ms'
  end
end
