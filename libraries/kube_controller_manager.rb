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
  # Resource for managing the Controller Manager
  class KubeControllerManager < Chef::Resource
    resource_name :kube_controller_manager

    property :version, String, default: '1.7.6'
    property :remote, String,
      default: lazy { |r|
        'https://storage.googleapis.com/kubernetes-release' \
        "/release/v#{r.version}/bin/linux/amd64/kube-controller-manager"
      }
    property :checksum, String,
      default: 'ec1c6fada5a4d5136678f25e35d273cb3f871a50ed9b06fad6b9d08ab12153ed'
    property :run_user, String, default: 'kubernetes'
    property :file_ulimit, Integer, default: 65536

    default_action :create

    action :create do
      remote_file "kube-controller-manager version: #{new_resource.version}" do
        path controller_manager_path
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

      systemd_contents = {
        Unit: {
          Description: 'Kubernetes Controller Manager',
          Documentation: 'https://k8s.io',
          After: 'network.target',
        },
        Service: {
          User: new_resource.run_user,
          ExecStart: generator.generate,
          Restart: 'on-failure',
          LimitNOFILE: new_resource.file_ulimit,
        },
        Install: {
          WantedBy: 'multi-user.target',
        },
      }

      systemd_unit 'kube-controller-manager.service' do
        content(systemd_contents)
        action :create
        notifies :restart, 'service[kube-controller-manager]', :immediately
      end

      service 'kube-controller-manager' do
        action %w(enable start)
      end
    end

    def generator
      CommandGenerator.new controller_manager_path, self
    end

    def controller_manager_path
      '/usr/sbin/kube-controller-manager'
    end
  end

  # Commandline properties for the Controller Manager
  # Reference: https://kubernetes.io/docs/admin/kube-controller-manager/
  class KubeControllerManager
    property :address, default: '0.0.0.0'
    property :allocate_node_cidrs
    property :attach_detach_reconcile_sync_period, default: '1m0s'
    property :azure_container_registry_config
    property :cidr_allocator_type, default: 'RangeAllocator'
    property :cloud_config
    property :cloud_provider
    property :cluster_cidr
    property :cluster_name, default: 'kubernetes'
    property :cluster_signing_cert_file, default: '/etc/kubernetes/ca/ca.pem'
    property :cluster_signing_key_file, default: '/etc/kubernetes/ca/ca.key'
    property :concurrent_deployment_syncs, default: 5
    property :concurrent_endpoint_syncs, default: 5
    property :concurrent_gc_syncs, default: 20
    property :concurrent_namespace_syncs, default: 2
    property :concurrent_rc_syncs, default: 5
    property :concurrent_replicaset_syncs, default: 5
    property :concurrent_resource_quota_syncs, default: 5
    property :concurrent_service_syncs, default: 1
    property :concurrent_serviceaccount_token_syncs, default: 5
    property :configure_cloud_routes, default: true
    property :contention_profiling
    property :controller_start_interval
    property :controllers
    property :deployment_controller_sync_period, default: '30s'
    property :disable_attach_detach_reconcile_sync, default: '1m0s'
    property :enable_dynamic_provisioning, default: true
    property :enable_garbage_collector, default: true
    property :enable_hostpath_provisioner
    property :enable_taint_manager, default: true
    property :experimental_cluster_signing_duration, default: '8760h0m0s'
    property :feature_gates
    property :flex_volume_plugin_dir, default: '/usr/libexec/kubernetes/kubelet-plugins/volume/exec/'
    property :google_json_key
    property :horizontal_pod_autoscaler_downscale_delay, default: '5m0s'
    property :horizontal_pod_autoscaler_sync_period, default: '30s'
    property :horizontal_pod_autoscaler_upscale_delay, default: '3m0s'
    property :horizontal_pod_autoscaler_use_rest_clients
    property :insecure_experimental_approve_all_kubelet_csrs_for_group
    property :kube_api_burst, default: 30
    property :kube_api_content_type, default: 'application/vnd.kubernetes.protobuf'
    property :kube_api_qps, default: 20
    property :kubeconfig
    property :large_cluster_size_threshold, default: 50
    property :leader_elect, default: true
    property :leader_elect_lease_duration, default: '15s'
    property :leader_elect_renew_deadline, default: '10s'
    property :leader_elect_resource_lock, default: 'endpoints'
    property :leader_elect_retry_period, default: '2s'
    property :log_flush_frequency, default: '5s'
    property :master, required: true
    property :min_resync_period, default: '12h0m0s'
    property :namespace_sync_period, default: '5m0s'
    property :node_cidr_mask_size, default: 24
    property :node_eviction_rate, default: 0.1
    property :node_monitor_grace_period, default: '40s'
    property :node_monitor_period, default: '5s'
    property :node_startup_grace_period, default: '1m0s'
    property :pod_eviction_timeout, default: '5m0s'
    property :port, default: 10_252
    property :profiling, default: true
    property :pv_recycler_increment_timeout_nfs, default: 30
    property :pv_recycler_minimum_timeout_hostpath, default: 60
    property :pv_recycler_minimum_timeout_nfs, default: 300
    property :pv_recycler_pod_template_filepath_hostpath
    property :pv_recycler_pod_template_filepath_nfs
    property :pv_recycler_timeout_increment_hostpath, default: 30
    property :pvclaimbinder_sync_period, default: '15s'
    property :resource_quota_sync_period, default: '5m0s'
    property :root_ca_file
    property :route_reconciliation_period, default: '10s'
    property :secondary_node_eviction_rate, default: 0.01
    property :service_account_private_key_file
    property :service_cluster_ip_range
    property :service_sync_period, default: '5m0s'
    property :terminated_pod_gc_threshold, default: 12_500
    property :unhealthy_zone_threshold, default: 0.55
    property :use_service_account_credentials

    property :v, default: 0
  end
end
