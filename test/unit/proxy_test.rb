require 'command_generator'
require 'chef'
require 'cheffish/chef_run'
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

  def test_downloads_the_kube_proxy_binary
    provider.action_create

    download = provider.inline_resources.find 'remote_file[kube-proxy binary]'

    assert_equal '/usr/sbin/kube-proxy', download.path
  end
end
