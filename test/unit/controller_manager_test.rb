require 'chef'
require 'cheffish/chef_run'

require 'kube_controller_manager'

require 'minitest/autorun'

class ControllerManagerTest < Minitest::Test
  def kube_controller_manager
    @controller ||= KubernetesCookbook::KubeControllerManager.new 'testing'
  end

  def test_has_a_name
    assert_equal 'testing', kube_controller_manager.name
  end

  def test_default_action_is_create
    assert_equal [:create], kube_controller_manager.action
  end
end

class ControllerManagerActionTest < Minitest::Test
  require_relative 'provider_helper'
  include ChefContext

  def provider
    @provider ||= begin
      resource = chefrun.compile_recipe do
        kube_controller_manager 'testing'
      end
      provider = resource.provider_for_action(:start)
      provider.extend ProviderInspection
    end
  end

  def test_passes_scheduler_command_to_systemd
    provider.action_start

    unit = provider.inline_resources.find 'systemd_unit[kube-controller-manager.service]'

    command = unit.content[:Service][:ExecStart]
    assert_equal '/usr/sbin/kube-controller-manager', command
  end

  def test_downloads_the_binary
    provider.action_create
    download = provider.inline_resources.find 'remote_file[kube-'\
        'controller-manager binary]'

    assert_equal '/usr/sbin/kube-controller-manager', download.path
  end
end
