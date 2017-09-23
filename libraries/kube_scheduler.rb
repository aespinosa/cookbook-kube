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
  # Resource to manage a scheduler
  class KubeScheduler < Chef::Resource
    resource_name :kube_scheduler

    property :version, String, default: '1.7.6'
    property :remote, String,
      default: lazy { |r|
        'https://storage.googleapis.com/kubernetes-release' \
        "/release/v#{r.version}/bin/linux/amd64/kube-scheduler"
      }
    property :checksum, String,
      default: '391b105aa43143120960c7be8312b6685f2008ea5c21e1360610c1677752549c'
    property :run_user, String, default: 'kubernetes'
    property :file_ulimit, Integer, default: 65536

    default_action :create

    action :create do
      remote_file "kube-scheduler binary version: #{new_resource.version}" do
        path scheduler_path
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

      systemd_contents = {
        Unit: {
          Description: 'Kubernetes Scheduler Plugin',
          Documentation: 'https://k8s.io',
          After: 'network.target',
        },
        Service: {
          User: new_resource.run_user,
          ExecStart: generator.generate,
          Restart: 'on-failure',
          LimitNOFILE: new_resource.file_ulimit,
        },
        Install: {
          WantedBy: 'multi-user.target',
        },
      }

      systemd_unit 'kube-scheduler.service' do
        content(systemd_contents)
        action :create
        notifies :restart, 'service[kube-scheduler]', :immediately
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
  # Reference: https://kubernetes.io/docs/admin/kube-scheduler/
  class KubeScheduler
    property :address, default: '0.0.0.0'
    property :algorithm_provider, default: 'DefaultProvider'
    property :azure_container_registry_config
    property :contention_profiling
    property :feature_gates
    property :google_json_key
    property :kube_api_burst, default: 100
    property :kube_api_content_type, default: 'application/vnd.kubernetes.protobuf'
    property :kube_api_qps, default: 50
    property :kubeconfig
    property :leader_elect, default: true
    property :leader_elect_lease_duration, default: '15s'
    property :leader_elect_renew_deadline, default: '10s'
    property :leader_elect_resource_lock
    property :leader_elect_retry_period, default: '2s'
    property :lock_object_name, default: 'kube-scheduler'
    property :lock_object_namespace, default: 'kube-system'
    property :master, required: true
    property :policy_config_file
    property :policy_configmap
    property :policy_configmap_namespace, default: 'kube-system'
    property :port, default: 10_251
    property :profiling, default: true
    property :scheduler_name, default: 'default-scheduler'
    property :use_legacy_policy_config

    property :v, default: 0
  end
end
