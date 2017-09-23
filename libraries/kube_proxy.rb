# Copyright 2016-2017 Allan Espinosa
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

module KubernetesCookbook
  # Resource for managing a kube-proxy
  class KubeProxy < Chef::Resource
    resource_name :kube_proxy

    property :version, String, default: '1.7.6'
    property :remote, String,
      default: lazy { |r|
        'https://storage.googleapis.com/kubernetes-release' \
        "/release/v#{r.version}/bin/linux/amd64/kube-proxy"
      }
    property :checksum, String,
      default: 'f9298a5b9e0a9fe3891f7a35bc13c012f1d9530f8a755b9038d3810873a2a843'
    property :file_ulimit, Integer, default: 65536

    default_action :create

    action :create do
      remote_file "kube-proxy binary version: #{new_resource.version}" do
        path proxy_path
        mode '0755'
        source new_resource.remote
        checksum new_resource.checksum
      end
    end

    action :start do
      systemd_contents = {
        Unit: {
          Description: 'Kubernetes Kube-Proxy Server',
          Documentation: 'https://k8s.io',
          After: 'network.target',
        },
        Service: {
          ExecStart: generator.generate,
          Restart: 'on-failure',
          LimitNOFILE: new_resource.file_ulimit,
        },
        Install: {
          WantedBy: 'multi-user.target',
        },
      }

      systemd_unit 'kube-proxy.service' do
        content(systemd_contents)
        action :create
        notifies :restart, 'service[kube-proxy]', :immediately
      end

      service 'kube-proxy' do
        action %w(enable start)
      end
    end

    def generator
      CommandGenerator.new proxy_path, self
    end

    def proxy_path
      '/usr/sbin/kube-proxy'
    end
  end

  # Command line properties for the kube-proxy
  # Reference: https://kubernetes.io/docs/admin/kube-proxy/
  class KubeProxy
    property :azure_container_registry_config
    property :bind_address, default: '0.0.0.0'
    property :cleanup_iptables
    property :cluster_cidr
    property :config
    property :config_sync_period, default: '15m0s'
    property :conntrack_max_per_core, default: 32_768
    property :conntrack_min, default: 131_072
    property :conntrack_tcp_timeout_close_wait, default: '1h0m0s'
    property :conntrack_tcp_timeout_established, default: '24h0m0s'
    property :feature_gates
    property :google_json_key
    property :healthz_bind_address, default: '0.0.0.0:10256'
    property :healthz_port, default: 10_249
    property :hostname_override
    property :iptables_masquerade_bit, default: 14
    property :iptables_min_sync_period
    property :iptables_sync_period, default: '30s'
    property :kube_api_burst, default: 10
    property :kube_api_content_type, default: 'application/vnd.kubernetes.protobuf'
    property :kube_api_qps, default: 5
    property :kubeconfig
    property :masquerade_all
    property :master, required: true
    property :oom_score_adj, default: -999
    property :proxy_mode
    property :profiling
    property :proxy_mode
    property :proxy_port_range
    property :udp_timeout, default: '250ms'

    property :v, default: 0
  end
end
