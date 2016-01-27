require 'cheffish/chef_run'
require 'chef'

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

module ProviderInspection
  def compile_and_converge_action(&block)
    old_run_context = @run_context
    @run_context = @run_context.create_child
    return_value = instance_eval(&block)
    @inline_run_context = @run_context
    @run_context = old_run_context
    return_value
  end

  def inline_resources
    @inline_run_context.resource_collection
  end
end

module FakeCommand
  def kube_apiserver_command
    'fake apiserver command'
  end
end

class ActionStartTest < Minitest::Test
  def provider
    @provider ||= begin
      run = Cheffish::ChefRun.new
      resource = run.compile_recipe do
        kube_apiserver 'testing'
      end
      resource.extend FakeCommand
      provider = resource.provider_for_action(:start)
      provider.extend ProviderInspection
    end
  end

  def test_passes_apiserver_command_to_systemd_unit
    provider.action_start
    unit = provider.inline_resources.find 'template[/etc/systemd/system'\
        '/kube-apiserver.service]'

    command = unit.variables[:kube_apiserver_command]
    assert_equal 'fake apiserver command', command
  end
end
