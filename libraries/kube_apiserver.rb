module KubernetesCookbook
  class KubeApiserver < Chef::Resource
    resource_name :kube_apiserver

    # Reference: http://kubernetes.io/v1.1/docs/admin/kube-apiserver.html
    property :admission_control, [String, Array], default: 'AlwaysAdmit'
    property :admission_control_config_file, String, default: nil
    property :advertise_address, String, default: nil

    property :run_user, String, default: 'kubernetes'

    default_action :create

    action :create do
      remote_file 'kube-apiserver binary' do
        path '/usr/sbin/kube-apiserver'
        mode '0755'
        source 'http://proxy.dev:3142/HTTPS///storage.googleapis.com/kubernetes-release/release/v1.1.3/bin/linux/amd64/kube-apiserver'
        checksum '9eb61318ca422031ee1ec7ef12c81aa1ae11feb0c26bece5aa6c3d3698017e51'
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

      template '/etc/systemd/system/kube-apiserver.service' do
        source 'systemd/kube-apiserver.service.erb' 
        notifies :run, 'execute[systemctl daemon-reload]', :immediately
      end

      execute 'systemctl daemon-reload' do
        command 'systemctl daemon-reload'
        action :nothing
      end

      service 'kube-apiserver' do
        action %w(enable start)
      end
    end

    private

    def file_cache_path
      Chef::Config[:file_cache_path]
    end
  end
end
