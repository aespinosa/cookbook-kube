require 'cheffish/chef_run'
require 'chef'

require 'command_generator'
require 'kube_apiserver'

require 'minitest/autorun'

class ApiServerTest < Minitest::Test
  include KubernetesCookbook

  def kube_apiserver
    @server ||= KubeApiserver.new 'default'
  end

  def test_has_a_name
    assert_equal 'default', kube_apiserver.name
  end

  def test_default_action_is_create
    assert_equal [:create], kube_apiserver.action
  end

  def test_default_admission_control_is_always_admit
    assert_equal 'AlwaysAdmit', kube_apiserver.admission_control
  end

  def test_can_set_a_single_admission_control_plugin
    plugins = 'ResourceQuota'
    kube_apiserver.admission_control plugins
    assert_equal plugins, kube_apiserver.admission_control
  end

  def test_can_set_multiple_admission_control_plugins
    plugins = %w(ResourceQuota ServiceAccount)
    kube_apiserver.admission_control plugins
    assert_equal plugins, kube_apiserver.admission_control
  end

  def test_default_admission_control_config_file_is_nil
    assert_nil kube_apiserver.admission_control_config_file
  end

  def test_accepts_a_string_for_admission_control_file
    kube_apiserver.admission_control_config_file '/etc/some-file'
    assert_equal '/etc/some-file', kube_apiserver.admission_control_config_file
  end

  def test_default_advertise_address_is_nil
    assert_nil kube_apiserver.advertise_address
  end

  def test_accepts_an_ipaddress_string_for_advertise_address
    kube_apiserver.advertise_address '127.0.0.1'
    assert_equal '127.0.0.1', kube_apiserver.advertise_address
  end
end

module Provider
  require_relative 'provider_helper'

  def provider(action = :start, &block)
    @provider ||= begin
      run = Cheffish::ChefRun.new
      resource = run.compile_recipe do
        kube_apiserver 'testing', &block
      end
      provider = resource.provider_for_action(:create)
      provider.extend ProviderInspection
    end
  end
end

class ActionCreateTest < Minitest::Test
  include Provider

  def test_passes_the_source_remote
    provider do
      remote 'https://somewhere/kube-apiserver'
    end

    provider.action_create

    binary = provider.inline_resources.find 'remote_file[kube-apiserver binary]'

    assert_equal 'https:///kube-apiserver', binary.source
  end

  def test_passes_the_source_remote
    provider :create do
      checksum 'the-checksum'
    end

    provider.action_create

    binary = provider.inline_resources.find 'remote_file[kube-apiserver binary]'

    assert_equal 'the-checksum', binary.checksum
  end
end

class ActionStartTest < Minitest::Test
  include Provider

  def test_passes_apiserver_command_to_systemd_unit
    provider.action_start
    unit = provider.inline_resources.find 'template[/etc/systemd/system'\
        '/kube-apiserver.service]'

    command = unit.variables[:kube_apiserver_command]
    assert_equal '/usr/sbin/kube-apiserver', command
  end
end
