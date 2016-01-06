module KubernetesCookbook
  class KubeControllerManager < Chef::Resource
    resource_name :kube_controller_manager

    property :run_user, String, default: 'kubernetes'

    default_action :create

    action :create do
      remote_file 'kube-controller-manager binary' do
        path '/usr/sbin/kube-controller-manager'
        mode '0755'
        source 'http://proxy.dev:3142/HTTPS///storage.googleapis.com/kubernetes-release/release/v1.1.3/bin/linux/amd64/kube-controller-manager'
        checksum '1b011b45217005ebe776f1de1b5acec2a6ca1defa8ecbff2dc0aa16e936fc32a'
      end
    end

    action :start do
      user 'kubernetes' do
        action :create
        only_if { run_user == 'kubernetes' }
      end

      template '/etc/systemd/system/kube-controller-manager.service' do
        source 'systemd/kube-controller-manager.service.erb' 
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
  end
end
