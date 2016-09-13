require_relative 'command_generator'

module KubernetesCookbook
  # Resource for managing the Controller Manager
  class KubeControllerManager < Chef::Resource
    resource_name :kube_controller_manager

    property :remote, String,
      default: 'https://storage.googleapis.com/kubernetes-release' \
               '/release/v1.3.6/bin/linux/amd64/kube-controller-manager'
    property :checksum, String,
      default: 'ceca7a843b0a29fcb2b84ed91f114c30'\
               'c5e3c002589791fcf9ac2af8c2572e11'
    property :run_user, String, default: 'kubernetes'

    default_action :create

    action :create do
      remote_file 'kube-controller-manager binary' do
        path controller_manager_path
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

      template '/etc/systemd/system/kube-controller-manager.service' do
        source 'systemd/kube-controller-manager.service.erb'
        cookbook 'kube'
        variables kube_controller_manager_command: generator.generate
        notifies :run, 'execute[systemctl daemon-reload]', :immediately
      end

      execute 'systemctl daemon-reload' do
        command 'systemctl daemon-reload'
        action :nothing
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
  # Reference: http://kubernetes.io/v1.1/docs/admin/kube-controller-manager.html
  class KubeControllerManager < Chef::Resource
    property :address, default: '127.0.0.1'
    property :allocate_node_cidrs, default: false
    property :cloud_config
    property :cloud_provider
    property :cluster_cidr
    property :cluster_name, default: 'kubernetes'
    property :concurrent_deployment_syncs, default: 5
    property :concurrent_endpoint_syncs, default: 5
    property :concurrent_namespace_syncs, default: 2
    property :concurrent_rc_syncs, default: 5
    property :concurrent_replicaset_syncs, default: 5
    property :concurrent_resource_quota_syncs, default: 5
    property :configure_cloud_routes, default: true
    property :controller_start_interval, default: 0
    property :daemonset_lookup_cache_size, default: 1024
    property :deleting_pods_burst, default: 10
    property :deleting_pods_qps, default: 0.1
    property :deployment_controller_sync_period, default: '30s'
    property :enable_dynamic_provisioning, default: true
    property :enable_garbage_collector, default: false
    property :enable_hostpath_provisioner, default: false
    property :flex_volume_plugin_dir, default: '/usr/libexec/kubernetes/kubelet_plugins/volume/exec/'
    property :google_json_key
    property :horizontal_pod_autoscaler_sync_period, default: '30s'
    property :kube_api_burst, default: 30
    property :kube_api_content_type, default: 'application/vnd.kubernetes.protobuf'
    property :kube_api_qps, default: 20
    property :kubeconfig
    property :leader_elect, default: false
    property :leader_elect_lease_duration, default: '15s'
    property :leader_elect_renew_deadline, default: '10s'
    property :leader_elect_retry_period, default: '2s'
    property :log_flush_frequency, default: '5s'
    property :master
    property :min_resync_period, default: '12h0m0s'
    property :namespace_sync_period, default: '5m0s'
    property :node_cidr_mask_size, default: 24
    property :node_monitor_grace_period, default: '40s'
    property :node_monitor_period, default: '5s'
    property :node_startup_grace_period, default: '1m0s'
    property :node_sync_period, default: '10s'
    property :pod_eviction_timeout, default: '5m0s'
    property :port, default: 10_252
    property :profiling, default: true
    property :pv_recycler_increment_timeout_nfs, default: 30
    property :pv_recycler_minimum_timeout_hostpath, default: 60
    property :pv_recycler_minimum_timeout_nfs, default: 300
    property :pv_recycler_pod_template_filepath_hostpath
    property :pv_recycler_pod_template_filepath_nfs
    property :pv_recycler_timeout_increment_hostpath, default: 30
    property :pvclaimbinder_sync_period, default: '10s'
    property :replicaset_lookup_cache_size, default: 4096
    property :replication_controller_lookup_cache_size, default: 4096
    property :resource_quota_sync_period, default: '10s'
    property :root_ca_file
    property :service_account_private_key_file
    property :service_cluster_ip_range
    property :service_sync_period, default: '5m0s'
    property :terminated_pod_gc_threshold, default: 12_500
  end
end
