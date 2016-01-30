require 'command_generator'
require 'kube_proxy'

require 'minitest/autorun'

class KubeProxyTest < Minitest::Test
  def kube_proxy
    @controller ||= KubernetesCookbook::KubeProxy.new 'testing'
  end

  def test_has_a_name
    assert_equal 'testing', kube_proxy.name
  end

  def test_default_action_is_create
    assert_equal [:create], kube_proxy.action
  end
end

class KubeProxyActionTest < Minitest::Test
  require_relative 'provider_helper'

  def provider
    @provider ||= begin
      run = Cheffish::ChefRun.new
      resource = run.compile_recipe do
        kube_proxy 'testing'
      end
      provider = resource.provider_for_action(:start)
      provider.extend ProviderInspection
    end
  end

  def test_passes_scheduler_command_to_systemd
    provider.action_start

    unit = provider.inline_resources.find 'template[/etc/systemd/system'\
        '/kube-proxy.service]'

    command = unit.variables[:kube_proxy_command]
    assert_equal '/usr/sbin/kube-proxy', command
  end
end
