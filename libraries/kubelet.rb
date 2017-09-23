# Copyright 2016-2017 Allan Espinosa
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require_relative 'command_generator'

module KubernetesCookbook
  # Resource for instantiating a kubelet
  class KubeletService < Chef::Resource
    resource_name :kubelet_service

    property :version, String, default: '1.7.6'
    property :remote, String,
      default: lazy { |r|
        'https://storage.googleapis.com/kubernetes-release' \
        "/release/v#{r.version}/bin/linux/amd64/kubelet"
      }
    property :checksum, String,
      default: '6178cb17d3c34ebe31dfc572d17ae077ce19d2a936bbe90999bac87ebf6e06eb'
    property :container_runtime_service, String, default: 'docker.service'
    property :run_user, String, default: 'kubernetes'
    property :file_ulimit, Integer, default: 65536

    # Reference: http://kubernetes.io/docs/admin/kubelet/
    property :api_servers

    default_action :create

    action :create do
      remote_file "kubelet binary version: #{new_resource.version}" do
        path kubelet_path
        mode '0755'
        source new_resource.remote
        checksum new_resource.checksum
      end

      pkgs = case node['platform_family']
             when 'debian'
               %w(iptables iproute2 socat util-linux mount ebtables ethtool)
             when 'rhel', 'fedora', 'amazon'
               %w(socat shadow-utils conntrack-tools ethtool)
             else
               %w()
             end

      package pkgs
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
          Description: 'Kubernetes Kubelet Server',
          Documentation: 'http://kubernetes.io/docs/',
          After: "network.target #{new_resource.container_runtime_service}",
          Wants: new_resource.container_runtime_service,
        },
        Service: {
          # User: new_resource.run_user,
          ExecStart: kubelet_command,
          Restart: 'on-failure',
          RestartSec: 10,
          LimitNOFILE: new_resource.file_ulimit,
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
    property :anonymous_auth, default: true
    property :authentication_token_webhook
    property :authentication_token_webhook_cache_ttl, default: '2m0s'
    property :authorization_mode, default: 'AlwaysAllow'
    property :authorization_webhook_cache_authorized_ttl, default: '5m0s'
    property :authorization_webhook_cache_unauthorized_ttl, default: '30s'
    property :azure_container_registry_config
    property :bootstrap_kubeconfig
    property :cadvisor_port, default: 4_194
    property :cert_dir, default: '/var/run/kubernetes'
    property :cgroup_driver, default: 'cgroupfs'
    property :cgroup_root, default: ''
    property :cgroups_per_qos, default: true
    property :chaos_chance, default: 0
    property :client_ca_file
    property :cloud_config
    property :cloud_provider, default: 'auto-detect'
    property :cluster_dns
    property :cluster_domain
    property :cni_bin_dir, default: '/opt/cni/bin'
    property :cni_conf_dir, default: '/etc/cni/net.d'
    property :container_runtime, default: 'docker'
    property :container_runtime_endpoint, default: 'unix:///var/run/dockershim.sock'
    property :containerized, default: false
    property :cpu_cfs_quota, default: true
    property :contention_profiling
    property :cpu_cfs_quota, default: true
    property :docker_disable_shared_pid
    property :docker_endpoint, default: 'unix:///var/run/docker.sock'
    property :enable_controller_attach_detach, default: true
    property :enable_controller_attach_detach
    property :enable_custom_metrics, default: false
    property :enable_debugging_handlers, default: true
    property :enable_server, default: true
    property :enforce_node_allocatable, default: 'pods'
    property :event_burst, default: 10
    property :event_qps, default: 5
    property :eviction_hard, default: 'memory.available<100Mi,nodefs.available<10%,nodefs.inodesFree<5%'
    property :eviction_max_pod_grace_period, default: 0
    property :eviction_minimum_reclaim
    property :eviction_pressure_transition_period, default: '5m0s'
    property :eviction_soft
    property :eviction_soft_grace_period
    property :exit_on_lock_contention
    property :experimental_allocatable_ignore_eviction
    property :experimental_allowed_unsafe_sysctls, default: []
    property :experimental_bootstrap_kubeconfig
    property :experimental_check_node_capabilities_before_mount
    property :experimental_fail_swap_on
    property :experimental_kernel_memcg_notification
    property :experimental_mounter_path
    property :experimental_qos_reserved
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
    property :image_gc_high_threshold, default: 85
    property :image_gc_low_threshold, default: 80
    property :image_pull_progress_deadline, default: '1m0s'
    property :image_service_endpoint
    property :iptables_drop_bit, default: 15
    property :iptables_masquerade_bit, default: 14
    property :keep_terminated_pod_volumes
    property :kube_api_burst, default: 10
    property :kube_api_content_type, default: 'application/vnd.kubernetes.protobuf'
    property :kube_api_qps, default: 5
    property :kube_reserved
    property :kube_reserved_cgroup
    property :kubeconfig, default: '/var/lib/kubelet/kubeconfig'
    property :kubelet_cgroups
    property :lock_file
    property :make_iptables_util_chains, default: true
    property :manifest_url
    property :manifest_url_header
    property :max_open_files, default: 1_000_000
    property :max_pods, default: 110
    property :minimum_image_ttl_duration, default: '2m0s'
    property :network_plugin
    property :network_plugin_mtu, default: 0
    property :node_ip
    property :node_labels
    property :node_status_update_frequency, default: '10s'
    property :oom_score_adj, default: -999
    property :pod_cidr
    property :pod_infra_container_image,
             default: 'gcr.io/google_containers/pause-amd64:3.0'
    property :pod_manifest_path
    property :pods_per_core
    property :port, default: 10_250
    property :protect_kernel_defaults
    property :provider_id
    property :read_only_port, default: 10_255
    property :really_crash_for_testing
    property :register_node, default: true
    property :register_with_taints, default: false
    property :registry_burst, default: 10
    property :registry_qps, default: 5
    property :require_kubeconfig
    property :resolv_conf, default: '/etc/resolv.conf'
    property :rkt_api_endpoint, default: 'localhost:15441'
    property :rkt_path
    property :rkt_stage1_image
    property :root_dir, default: '/var/lib/kubelet'
    property :runonce
    property :runtime_cgroups
    property :runtime_request_timeout, default: '2m0s'
    property :seccomp_profile_root, default: '/var/lib/kubelet/seccomp'
    property :serialize_image_pulls, default: true
    property :streaming_connection_idle_timeout, default: '4h0m0s'
    property :sync_frequency, default: '1m0s'
    property :system_cgroups
    property :system_reserved, default: 'none'
    property :system_reserved_cgroup, default: ''
    property :tls_cert_file
    property :tls_private_key_file
    property :volume_plugin_dir, default: '/usr/libexec/kubernetes/kubelet-plugins/volume/exec/'
    property :volume_stats_agg_period, default: '1m0s'

    property :v, default: 0
  end
end
