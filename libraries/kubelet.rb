require_relative 'command_generator'

module KubernetesCookbook
  # Resource for instantiating a kubelet
  class KubeletService < Chef::Resource
    resource_name :kubelet_service

    property :version, String, default: '1.7.5'
    property :remote, String,
      default: lazy { |r|
        'https://storage.googleapis.com/kubernetes-release' \
        "/release/v#{r.version}/bin/linux/amd64/kubelet"
      }
    property :checksum, String,
      default: '2ca46b4a9e6f1771d6d2ad529f525bc3154e4e13f31e265e1923a832eed11ab5'
    property :container_runtime_service, String, default: 'docker.service'
    property :run_user, String, default: 'kubernetes'

    # Reference: http://kubernetes.io/docs/admin/kubelet/
    property :api_servers

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
        only_if { new_resource.run_user == 'kubernetes' }
      end

      directory '/var/run/kubernetes' do
        owner new_resource.run_user
      end

      template '/etc/tmpfiles.d/kubernetes.conf' do
        source 'systemd/tmpfiles.erb'
        cookbook 'kube'
      end

      systemd_contents = {
        Unit: {
          Description: 'kubelet',
          Documentation: 'https://k8s.io',
          After: "network.target #{new_resource.container_runtime_service}",
          Wants: new_resource.container_runtime_service,
        },
        Service: {
          # User: new_resource.run_user,
          ExecStart: kubelet_command,
          Restart: 'on-failure',
        },
        Install: {
          WantedBy: 'multi-user.target',
        },
      }

      systemd_unit 'kubelet.service' do
        content(systemd_contents)
        action :create
        notifies :restart, 'service[kubelet]', :immediately
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
  # Reference: http://kubernetes.io/docs/admin/kubelet/
  class KubeletService
    property :address, default: '0.0.0.0'
    property :allow_privileged, default: false
    property :api_servers
    property :auth_path
    property :cadvisor_port, default: 4_194
    property :cert_dir, default: '/var/run/kubernetes'
    property :cgroup_root, default: ''
    property :chaos_chance, default: 0
    property :cloud_config
    property :cloud_provider, default: 'auto-detect'
    property :cluster_dns
    property :cluster_domain
    property :config
    property :configure_cbr0, default: false
    property :container_runtime, default: 'docker'
    property :container_runtime_endpoint, default: 'docker'
    property :containerized, default: false
    property :cpu_cfs_quota, default: true
    property :docker_endpoint, default: 'unix:///var/run/docker.sock'
    property :docker_exec_handler, default: 'native'
    property :enable_controller_attach_detach, default: true
    property :enable_custom_metrics, default: false
    property :enable_debugging_handlers, default: true
    property :enable_server, default: true
    property :event_burst, default: 10
    property :event_qps, default: 5
    property :eviction_hard, default: 'memory.available<100Mi'
    property :eviction_minimum_reclaim
    property :eviction_max_pod_grace_period, default: 0
    property :eviction_pressure_transition_period, default: '5m0s'
    property :eviction_soft
    property :eviction_soft_grace_period
    property :exit_on_lock_contention
    property :experimental_allowed_unsafe_sysctls, default: []
    property :experimental_bootstrap_kubeconfig
    property :experimental_flannel_overlay, default: false
    property :experimental_nvidia_gpus, default: 0
    property :feature_gates
    property :file_check_frequency, default: '20s'
    property :google_json_key
    property :hairpin_mode, default: 'promiscuous-bridge'
    property :healthz_bind_address, default: '127.0.0.1'
    property :healthz_port, default: 10_248
    property :host_ipc_sources, default: '*'
    property :host_network_sources, default: '*'
    property :host_pid_sources, default: '*'
    property :hostname_override
    property :http_check_frequency, default: '20s'
    property :image_gc_high_threshold, default: 90
    property :image_gc_low_threshold, default: 80
    property :image_service_endpoint
    property :iptables_drop_bit, default: 15
    property :iptables_masquerade_bit, default: 14
    property :kube_api_burst, default: 10
    property :kube_api_content_type, default: 'application/vnd.kubernetes.protobuf'
    property :kube_api_qps, default: 5
    property :kube_reserved
    property :kubeconfig, default: '/var/lib/kubelet/kubeconfig'
    property :kubelet_cgroups
    property :lock_file
    property :log_flush_frequency, default: '5s'
    property :low_diskspace_threshold_mb, default: 256
    property :make_iptables_util_chains, default: true
    property :manifest_url
    property :manifest_url_header
    property :master_service_namespace, default: 'default'
    property :max_open_files, default: 1_000_000
    property :max_pods, default: 110
    property :maximum_dead_containers, default: 100
    property :maximum_dead_containers_per_container, default: 2
    property :minimum_container_ttl_duration, default: '1m0s'
    property :minimum_image_ttl_duration, default: '2m0s'
    property :network_plugin
    property :network_plugin_dir,
             default: '/usr/libexec/kubernetes/kubelet-plugins/net/exec/'
    property :network_plugin_mtu
    property :node_ip
    property :node_labels
    property :node_status_update_frequency, default: '10s'
    property :non_masquerade_cidr, default: '10.0.0.0/8'
    property :oom_score_adj, default: -999
    property :outofdisk_transition_frequency, default: '5m0s'
    property :pod_cidr
    property :pods_per_core, default: 0
    property :pod_infra_container_image,
             default: 'gcr.io/google_containers/pause-amd64:3.0'
    property :pod_manifest_path
    property :pods_per_core
    property :port, default: 10_250
    property :protect_kernel_defaults
    property :read_only_port, default: 10_255
    property :really_crash_for_testing
    property :reconcile_cidr, default: true
    property :register_node, default: true
    property :register_schedulable, default: true
    property :registry_burst, default: 10
    property :registry_qps, default: 5
    property :require_kubeconfig
    property :resolv_conf, default: '/etc/resolv.conf'
    property :resource_container, default: '/kubelet'
    property :rkt_api_endpoint, default: 'localhost:15441'
    property :rkt_path
    property :rkt_stage1_image
    property :root_dir, default: '/var/lib/kubelet'
    property :runonce
    property :runtime_cgroups
    property :runtime_request_timeout, default: '2m0s'
    property :seccomp_profile_root
    property :serialize_image_pulls, default: true
    property :streaming_connection_idle_timeout, default: '4h0m0s'
    property :sync_frequency, default: '1m0s'
    property :system_cgroups, default: ''
    property :system_container
    property :system_reserved
    property :tls_cert_file
    property :tls_private_key_file
    property :volume_plugin_dir, default: '/usr/libexec/kubernetes/kubelet-plugins/volume/exec/'
    property :volume_stats_agg_period, default: '1m0s'

    property :v, default: 0
  end
end
