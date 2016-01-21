require 'chef/resource'

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

  def test_foo
    assert_equal 'foo', KubeApiserver.properties[:admission_control].default
  end

  def test_action_create_should_work
    skip 'need a real chef run context'
    kube_apiserver.run_action :create
  end
end
