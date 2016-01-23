module KubernetesCookbook
  class KubeletService < Chef::Resource
    resource_name :kubelet_service

    property :run_user, String, default: 'kubernetes'

    # Reference: http://kubernetes.io/v1.1/docs/admin/kubelet.html 
    property :api_servers, default: nil

    default_action :create

    action :create do
      remote_file 'kubelet binary' do
        path '/usr/sbin/kubelet'
        mode '0755'
        source 'http://proxy.dev:3142/HTTPS///storage.googleapis.com/kubernetes-release/release/v1.1.3/bin/linux/amd64/kubelet'
        checksum '62191c66f2d670dd52ddf1d88ef81048977abf1ffaa95ee6333299447eb6a482'
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
      end

      template '/etc/systemd/system/kubelet.service' do
        source 'systemd/kubelet.service.erb' 
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

    def kubelet_command
      cmd = "/usr/sbin/kubelet"
      if api_servers.kind_of? Array
        cmd << " --api-servers=#{api_servers.join ','}"
      elsif api_servers.kind_of? String
        cmd <<  "--api-servers=#{api_servers}"
      end
      cmd
    end

  end
end
