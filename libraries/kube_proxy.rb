module KubernetesCookbook
  # Resource for managing a kube-proxy
  class KubeProxy < Chef::Resource
    resource_name :kube_proxy

    property :remote, String,
      default: 'https://storage.googleapis.com/kubernetes-release' +
               '/release/v1.2.4/bin/linux/amd64/kube-proxy'
    property :checksum, String,
      default: '2f45f95fd48f4bfd7f988ece19ae06c6' +
               '8f161e9628dd6a495a5a867f14936917'
               
    default_action :create

    action :create do
      remote_file 'kube-proxy binary' do
        path proxy_path
        mode '0755'
        source new_resource.remote
        checksum new_resource.checksum
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
      CommandGenerator.new proxy_path, self
    end

    def proxy_path
      '/usr/sbin/kube-proxy'
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
