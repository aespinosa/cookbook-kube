require_relative 'command_generator'

module KubernetesCookbook
  # Resource for instantiating a kubelet
  class KubeletService < Chef::Resource
    resource_name :kubelet_service

    property :remote, String,
      default: 'https://storage.googleapis.com/kubernetes-release' +
               '/release/v1.3.6/bin/linux/amd64/kubelet'
    property :checksum, String,
      default: '12e43bdf19bc70f4eba68dc97d0ef71f' \
               '02568011b884f3606b9b9ea9be666a95'
    property :container_runtime_service, String, default: 'docker.service'
    property :run_user, String, default: 'kubernetes'

    # Reference: http://kubernetes.io/v1.1/docs/admin/kubelet.html
    property :api_servers, default: nil

    default_action :create

    action :create do
      remote_file 'kubelet binary' do
        path kubelet_path
        mode '0755'
        source new_resource.remote
        checksum new_resource.checksum
      end
    end

    action :start do
      user 'kubernetes' do
        action :create
        only_if { run_user == 'kubernetes' }
      end

      directory '/var/run/kubernetes' do
        owner run_user
      end

      template '/etc/tmpfiles.d/kubernetes.conf' do
        source 'systemd/tmpfiles.erb'
        cookbook 'kube'
      end

      template '/etc/systemd/system/kubelet.service' do
        source 'systemd/kubelet.service.erb'
        cookbook 'kube'
        variables kubelet_command: kubelet_command,
          container_runtime_service: container_runtime_service
        notifies :run, 'execute[systemctl daemon-reload]', :immediately
      end

      execute 'systemctl daemon-reload' do
        command 'systemctl daemon-reload'
        action :nothing
      end

      service 'kubelet' do
        action %w(enable start)
      end
    end

    def kubelet_path
      '/usr/sbin/kubelet'
    end

    def kubelet_command
      generator = CommandGenerator.new kubelet_path, self
      generator.generate
    end
  end

  # Commandline properties of a Kubelet
  # Reference: http://kubernetes.io/v1.1/docs/admin/kubelet.html
  class KubeletService < Chef::Resource
    property :address, default: '0.0.0.0'
    property :allow_privileged, default: false
    property :api_servers
    property :cadvisor_port, default: 4_194
    property :cert_dir, default: '/var/run/kubernetes'
    property :cgroup_root
    property :chaos_chance, default: 0
    property :cloud_config
    property :cloud_provider
    property :cluster_dns
    property :cluster_domain
    property :config
    property :configure_cbr0, default: false
    property :container_runtime, default: 'docker'
    property :containerized, default: false
    property :cpu_cfs_quota, default: false
    property :docker_endpoint
    property :docker_exec_handler, default: 'native'
    property :enable_debugging_handlers, default: true
    property :enable_server, default: true
    property :event_burst, default: 0
    property :event_qps, default: 0
    property :file_check_frequency, default: '20s'
    property :google_json_key
    property :healthz_bind_address, default: '127.0.0.1'
    property :healthz_port, default: 10_248
    property :host_ipc_sources, default: '*'
    property :host_network_sources, default: '*'
    property :host_pid_sources, default: '*'
    property :hostname_override
    property :http_check_frequency, default: '20s'
    property :image_gc_high_threshold, default: 90
    property :image_gc_low_threshold, default: 80
    property :kubeconfig, default: '/var/lib/kubelet/kubeconfig'
    property :log_flush_frequency, default: '5s'
    property :low_diskspace_threshold_mb, default: 256
    property :manifest_url
    property :manifest_url_header
    property :master_service_namespace
    property :max_open_files, default: 1_000_000
    property :max_pods, default: 40
    property :maximum_dead_containers, default: 100
    property :maximum_dead_containers_per_container, default: 2
    property :minimum_container_ttl_duration, default: '1m0s'
    property :network_plugin
    property :network_plugin_dir,
             default: '/usr/libexec/kubernetes/kubelet_plugins/net/exec/'
    property :node_status_update_frequency, default: '10s'
    property :oom_score_adj, default: -999
    property :pod_cidr
    property :pod_infra_container_image,
             default: 'gcr.io/google_containers/pause'
    property :port, default: 10_250
    property :read_only_port, default: 10_255
    property :really_crash_for_testing, default: false
    property :register_node, default: true
    property :registry_burst, default: 10
    property :registry_qps, default: 0
    property :resolv_conf, default: '/etc/resolv.conf'
    property :resource_container, default: '/kubelet'
    property :rkt_path
    property :rkt_stage1_image
    property :root_dir, default: '/var/lib/kubelet'
    property :runonce, default: false
    property :serialize_image_pulls, default: true
    property :streaming_connection_idle_timeout, default: 0
    property :sync_frequency, default: '10s'
    property :system_container
    property :tls_cert_file
    property :tls_private_key_file
  end
end
