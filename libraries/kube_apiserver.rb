module KubernetesCookbook
  # Resource to manage a Kubernetes API server
  class KubeApiserver < Chef::Resource
    resource_name :kube_apiserver

    property :remote, String,
      default: 'https://storage.googleapis.com/kubernetes-release' \
               '/release/v1.4.0/bin/linux/amd64/kube-apiserver'
    property :checksum, String,
      default: '1638e88dec8e33e7099006638507916f' \
               '889087a98790a3e485db03204291ec9a'
    property :run_user, String, default: 'kubernetes'
    property :options, Hash, default: {}

    default_action :create

    action :create do
      remote_file 'kube-apiserver binary' do
        path apiserver_path
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

      directory '/var/run/kubernetes' do
        owner run_user
      end

      template '/etc/tmpfiles.d/kubernetes.conf' do
        source 'systemd/tmpfiles.erb'
        cookbook 'kube'
      end

      template '/etc/systemd/system/kube-apiserver.service' do
        source 'systemd/kube-apiserver.service.erb'
        cookbook 'kube'
        variables kube_apiserver_command: generator.generate
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

    def generator
      CommandGenerator.new apiserver_path, self
    end

    def apiserver_path
      '/usr/sbin/kube-apiserver'
    end

    private

    def file_cache_path
      Chef::Config[:file_cache_path]
    end
  end
end
