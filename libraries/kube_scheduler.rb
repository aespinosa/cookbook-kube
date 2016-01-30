module KubernetesCookbook
  # Resource to manage a scheduler
  class KubeScheduler < Chef::Resource
    resource_name :kube_scheduler

    property :run_user, String, default: 'kubernetes'

    default_action :create

    action :create do
      remote_file 'kube-scheduler binary' do
        path '/usr/sbin/kube-scheduler'
        mode '0755'
        source 'https://storage.googleapis.com/kubernetes-release'\
               '/release/v1.1.3/bin/linux/amd64/kube-scheduler'
        checksum '0b56e4e8f96b51abdaf151d462fea52b'\
                 'f52e382ae7ed75ed262ed862530c98ae'
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
      CommandGenerator.new('/usr/sbin/kube-scheduler', self)
    end
  end

  # scheduler commandline flags
  # Reference: http://kubernetes.io/v1.1/docs/admin/kube-scheduler.html
  class KubeScheduler < Chef::Resource
    property :address, default: '127.0.0.1'
    property :algorithm_provider, default: 'DefaultProvider'
    property :bind_pods_burst, default: 100
    property :bind_pods_qps, default: 50
    property :google_json_key
    property :kubeconfig
    property :log_flush_frequency, default: '5s'
    property :master
    property :policy_config_file
    property :port, default: 10_251
    property :profiling, default: true
  end
end
