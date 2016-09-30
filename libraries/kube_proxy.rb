module KubernetesCookbook
  # Resource for managing a kube-proxy
  class KubeProxy < Chef::Resource
    resource_name :kube_proxy

    property :remote, String,
      default: 'https://storage.googleapis.com/kubernetes-release' \
               '/release/v1.4.0/bin/linux/amd64/kube-proxy'
    property :checksum, String,
      default: '3cebe9f93af9fa7a2351012cc209b679' \
               '3d251b3679fe8e7d344a9eb79f9e6a2e'

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
  # Reference: http://kubernetes.io/docs/admin/kube-proxy/
  class KubeProxy < Chef::Resource
    property :bind_address, default: '0.0.0.0'
    property :cleanup_iptables
    property :cluster_cidr
    property :config_sync_period, default: '15m0s'
    property :conntrack_max, default: 0
    property :conntrack_max_per_core, default: 32_768
    property :conntrack_tcp_timeout_established, default: '24h0m0s'
    property :feature_gates
    property :google_json_key
    property :healthz_bind_address, default: '127.0.0.1'
    property :healthz_port, default: 10_249
    property :hostname_override
    property :iptables_masquerade_bit, default: 14
    property :iptables_sync_period, default: '30s'
    property :kube_api_burst, default: 10
    property :kube_api_content_type, default: 'application/vnd.kubernetes.protobuf'
    property :kube_api_qps, default: 5
    property :kubeconfig
    property :log_flush_frequency, default: '5s'
    property :masquerade_all
    property :master
    property :oom_score_adj, default: -999
    property :proxy_mode
    property :proxy_port_range
    property :resource_container, default: '/kube_proxy'
    property :udp_timeout, default: '250ms'

    property :v, default: 0
  end
end
