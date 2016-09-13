module KubernetesCookbook
  # Resource to manage a scheduler
  class KubeScheduler < Chef::Resource
    resource_name :kube_scheduler

    property :remote, String,
      default: 'https://storage.googleapis.com/kubernetes-release' +
               '/release/v1.3.6/bin/linux/amd64/kube-scheduler'
    property :checksum, String,
      default: '555aad887e886b431fcc0d8e767b5aff'\
               '339ca8fdb6339f9c4b8b108b655112b1'
    property :run_user, String, default: 'kubernetes'

    default_action :create

    action :create do
      remote_file 'kube-scheduler binary' do
        path scheduler_path
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

      template '/etc/systemd/system/kube-scheduler.service' do
        source 'systemd/kube-scheduler.service.erb'
        cookbook 'kube'
        variables kube_scheduler_command: generator.generate
        notifies :run, 'execute[systemctl daemon-reload]', :immediately
      end

      execute 'systemctl daemon-reload' do
        command 'systemctl daemon-reload'
        action :nothing
      end

      service 'kube-scheduler' do
        action %w(enable start)
      end
    end

    def generator
      CommandGenerator.new(scheduler_path, self)
    end

    def scheduler_path
      '/usr/sbin/kube-scheduler'
    end
  end

  # scheduler commandline flags
  # Reference: http://kubernetes.io/v1.1/docs/admin/kube-scheduler.html
  class KubeScheduler < Chef::Resource
    property :address, default: '127.0.0.1'
    property :algorithm_provider, default: 'DefaultProvider'
    property :bind_pods_burst, default: 100
    property :bind_pods_qps, default: 50
    property :failure_domains, default: 'kubernetes.io/hostname,failure-domain.beta.kubernetes.io/zone,failure-domain.beta.kubernetes.io/region'
    property :google_json_key
    property :hard_pod_affinity_symmetric_weight, default: 1
    property :kube_api_burst, default: 100
    property :kube_api_content_type, default: 'application/vnd.kubernetes.protobuf'
    property :kube_api_qps, default: 50
    property :kubeconfig
    property :leader_elect, default: false
    property :leader_elect_lease_duration, default: '15s'
    property :leader_elect_renew_deadline, default: '10s'
    property :leader_elect_retry_period, default: '2s'
    property :log_flush_frequency, default: '5s'
    property :master
    property :policy_config_file
    property :port, default: 10_251
    property :profiling, default: true
    property :scheduler_name, default: 'default-scheduler'
  end

end
