require 'chef'
require 'cheffish/chef_run'

require 'kubelet'

require 'minitest/autorun'

class KubeletTest < Minitest::Test
  def kubelet
    @kubelet ||= KubernetesCookbook::KubeletService.new 'testing'
  end

  def test_has_a_name
    assert_equal 'testing', kubelet.name
  end

  def test_default_action_is_create
    assert_equal [:create], kubelet.action
  end

  def test_default_api_server_is_nil
    assert_nil kubelet.api_servers
  end
end

class KubeletActionStartTest < Minitest::Test
  require_relative 'provider_helper'
  include ChefContext

  def provider
    @provider ||= begin
      resource = chefrun.compile_recipe do
        kubelet_service 'testing'
      end
      provider = resource.provider_for_action(:start)
      provider.extend ProviderInspection
    end
  end

  def test_passes_scheduler_command_to_systemd
    provider.action_start

    unit = provider.inline_resources.find 'systemd_unit[kubelet.service]'

    command = unit.content[:Service][:ExecStart]
    assert_equal '/usr/sbin/kubelet', command
  end

  def test_kubelet_command_with_apiserver_flags
    provider.new_resource.api_servers 'http://127.0.0.1:8080'
    provider.action_start

    unit = provider.inline_resources.find 'systemd_unit[kubelet.service]'

    command = unit.content[:Service][:ExecStart]
    assert_match %r{--api-servers=http://127.0.0.1:8080},
                 command
  end

  def test_multiple_apiservers
    provider.new_resource
            .api_servers %w(http://127.0.0.1:8080 https://10.0.0.1:6443)
    provider.action_start

    unit = provider.inline_resources.find 'systemd_unit[kubelet.service]'

    command = unit.content[:Service][:ExecStart]

    assert_match %r{--api-servers=http://127.0.0.1:8080,https://10.0.0.1:6443},
                 command
  end

  def test_download_binary
    provider.action_create
    download = provider.inline_resources.find 'remote_file[kubelet binary]'

    assert_equal '/usr/sbin/kubelet', download.path
  end
end
