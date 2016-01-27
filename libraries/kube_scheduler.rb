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
  end
end
