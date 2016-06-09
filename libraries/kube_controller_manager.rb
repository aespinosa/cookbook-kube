module KubernetesCookbook
  # Resource for managing the Controller Manager
  class KubeControllerManager < Chef::Resource
    resource_name :kube_controller_manager

    property :remote, String,
      default: 'https://storage.googleapis.com/kubernetes-release' +
               '/release/v1.2.4/bin/linux/amd64/kube-controller-manager'
    property :checksum, String,
      default: '3cf545cd53a1f97525e47783ff608b1a' +
               '9d753298aad5cea04712351e81144884'
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
      ::File.join('/usr/sbin', PathNameHelper.kubernetes_file(remote))
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
    property :concurrent_endpoint_syncs, default: 5
    property :concurrent_rc_syncs, default: 5
    property :deleting_pods_burst, default: 10
    property :deleting_pods_qps, default: 0.1
    property :deployment_controller_sync_period, default: '30s'
    property :google_json_key
    property :horizontal_pod_autoscaler_sync_period, default: '30s'
    property :kubeconfig
    property :log_flush_frequency, default: '5s'
    property :master
    property :min_resync_period, default: '12h0m0s'
    property :namespace_sync_period, default: '5m0s'
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
    property :resource_quota_sync_period, default: '10s'
    property :root_ca_file
    property :service_account_private_key_file
    property :service_sync_period, default: '5m0s'
    property :terminated_pod_gc_threshold, default: 12_500
  end
end
