module KubernetesCookbook
  # Resource to manage a Kubernetes API server
  class KubeApiserver < Chef::Resource
    resource_name :kube_apiserver

    property :remote, String,
      default: 'https://storage.googleapis.com/kubernetes-release' \
               '/release/v1.7.5/bin/linux/amd64/kube-apiserver'
    property :checksum, String,
      default: 'ba4b74b3b0832818c27accb8004cccba0ded1ffbb5028d85703dbb8345b5dc21'
    property :run_user, String, default: 'kubernetes'

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
        only_if { new_resource.run_user == 'kubernetes' }
      end

      directory '/var/run/kubernetes' do
        owner new_resource.run_user
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

  # Commandline-related properties
  # Reference: http://kubernetes.io/docs/admin/kube-apiserver/
  class KubeApiserver
    property :admission_control, default: 'AlwaysAdmit'
    property :admission_control_config_file
    property :advertise_address
    property :allow_privileged
    property :apiserver_count, default: 1
    property :audit_log_maxage
    property :audit_log_maxbackup
    property :audit_log_maxsize
    property :audit_log_path
    property :authentication_token_webhook_cache_ttl, default: '2m0s'
    property :authentication_token_webhook_config_file
    property :authorization_mode, default: 'AlwaysAllow'
    property :authorization_policy_file
    property :authorization_rbac_super_user
    property :authorization_webhook_cache_authorized_ttl, default: '5m0s'
    property :authorization_webhook_cache_unauthorized_ttl, default: '30s'
    property :authorization_webhook_config_file
    property :basic_auth_file
    property :bind_address, default: '0.0.0.0'
    property :cert_dir, default: '/var/run/kubernetes'
    property :client_ca_file
    property :cloud_config
    property :cloud_provider
    property :cors_allowed_origins, default: []
    property :delete_collection_workers, default: 1
    property :deserialization_cache_size, default: 50_000
    property :enable_garbage_collector, default: true
    property :enable_swagger_ui
    property :etcd_cafile
    property :etcd_certfile
    property :etcd_keyfile
    property :etcd_prefix, default: '/registry'
    property :etcd_servers, default: []
    property :etcd_servers_overrides, default: []
    property :etcd_quorum_read
    property :event_ttl, default: '1h0m0s'
    property :experimental_keystone_url
    property :external_hostname
    property :feature_gates
    property :google_json_key
    property :insecure_bind_address, default: '127.0.0.1'
    property :insecure_port, default: 8080
    property :kubelet_certificate_authority
    property :kubelet_client_certificate
    property :kubelet_client_key
    property :kubelet_https, default: true
    property :kubelet_port, default: 10_250
    property :kubelet_timeout, default: '5s'
    property :kubernetes_service_node_port
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
    property :oidc_groups_claim
    property :oidc_issuer_url
    property :oidc_username_claim, default: 'sub'
    property :profiling, default: true
    property :repair_malformed_updates, default: true
    property :runtime_config
    property :secure_port, default: 6443
    property :service_account_key_file
    property :service_account_lookup
    property :service_cluster_ip_range
    property :service_node_port_range, default: '30000-32767'
    property :ssh_keyfile
    property :ssh_user
    property :storage_backend
    property :storage_media_type, default: 'application/json'
    property :storage_versions
    property :target_ram_mb
    property :tls_cert_file
    property :tls_private_key_file
    property :token_auth_file
    property :watch_cache, default: true
    property :watch_cache_sizes, default: []

    property :v, default: 0 # TODO: move to common class
  end
end
