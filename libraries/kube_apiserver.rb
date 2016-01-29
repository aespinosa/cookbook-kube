module KubernetesCookbook
  # Resource to manage a Kubernetes API server
  class KubeApiserver < Chef::Resource
    resource_name :kube_apiserver

    property :run_user, String, default: 'kubernetes'

    default_action :create

    action :create do
      remote_file 'kube-apiserver binary' do
        path '/usr/sbin/kube-apiserver'
        mode '0755'
        source 'https://storage.googleapis.com/kubernetes-release'\
               '/release/v1.1.3/bin/linux/amd64/kube-apiserver'
        checksum '9eb61318ca422031ee1ec7ef12c81aa1'\
                 'ae11feb0c26bece5aa6c3d3698017e51'
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
        variables kube_apiserver_command: kube_apiserver_command
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

    def non_commandline_property?(property)
      [:name, :run_user].include? property
    end

    def list_commandline_flag_properties
      self.class.properties.reject do |property, description|
        value = send(property)
        non_commandline_property?(property) || (value == description.default)
      end
    end

    def kube_apiserver_command
      actual_flags = list_commandline_flag_properties.map do |property, _|
        value = send(property)
        value = value.join ',' if value.is_a? Array
        "--#{property.to_s.tr('_', '-')}=#{value}"
      end
      actual_flags.reduce '/usr/sbin/kube-apiserver' do |command, flag|
        command << " #{flag}"
      end
    end

    private

    def file_cache_path
      Chef::Config[:file_cache_path]
    end
  end

  # Commandline-related properties
  # Reference: http://kubernetes.io/v1.1/docs/admin/kube-apiserver.html
  class KubeApiserver < Chef::Resource
    property :admission_control, default: 'AlwaysAdmit'
    property :admission_control_config_file
    property :advertise_address
    property :allow_privileged, default: false
    property :authorization_mode, default: 'AlwaysAllow'
    property :authorization_policy_file
    property :basic_auth_file
    property :bind_address, default: '0.0.0.0'
    property :cert_dir, default: '/var/run/kubernetes'
    property :client_ca_file
    property :cloud_config
    property :cloud_provider
    property :cluster_name, default: 'kubernetes'
    property :cors_allowed_origins, default: []
    property :etcd_config
    property :etcd_prefix, default: '/registry'
    property :etcd_servers, default: []
    property :etcd_servers_overrides, default: []
    property :event_ttl, default: '1h0m0s'
    property :experimental_keystone_url
    property :external_hostname
    property :google_json_key
    property :insecure_bind_address, default: '127.0.0.1'
    property :insecure_port, default: 8080
    property :kubelet_certificate_authority
    property :kubelet_client_certificate
    property :kubelet_client_key
    property :kubelet_https, default: true
    property :kubelet_port, default: 10_250
    property :kubelet_timeout, default: '5s'
    property :log_flush_frequency, default: '5s'
    property :long_running_request_regexp,
             default: '(/|^)((watch|proxy)(/|$)|'\
                      '(logs?|portforward|exec|attach)/?$)'
    property :master_service_namespace, default: 'default'
    property :max_connection_bytes_per_sec, default: 0
    property :max_requests_inflight, default: 400
    property :min_request_timeout, default: 1800
    property :oidc_ca_file
    property :oidc_client_id
    property :oidc_issuer_url
    property :oidc_username_claim, default: 'sub'
    property :profiling, default: true
    property :runtime_config
    property :secure_port, default: 6443
    property :service_account_key_file
    property :service_account_lookup, default: false
    property :service_cluster_ip_range
    property :service_node_port_range
    property :ssh_keyfile
    property :ssh_user
    property :storage_versions, default: %w(extensions/v1beta1 v1)
    property :tls_cert_file
    property :tls_private_key_file
    property :token_auth_file
    property :watch_cache, default: true

    property :v, default: 0 # TODO: move to common class
  end
end
