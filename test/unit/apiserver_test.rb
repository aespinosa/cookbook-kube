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

class CommandTest < Minitest::Test
  def kube_apiserver(&block)
    @resource ||= begin
      resource = KubernetesCookbook::KubeApiserver.new 'command test'
      resource.instance_eval(&block) if block
      resource
    end
  end

  def test_default_property_values_renders_no_flags
    assert_equal '/usr/sbin/kube-apiserver',
                 kube_apiserver.kube_apiserver_command
  end

  def test_array_values_become_comma_separated_arguments
    kube_apiserver do
      admission_control %w(AlwaysDeny ServiceQuota) # An array flag
    end

    assert_equal '/usr/sbin/kube-apiserver '\
        '--admission-control=AlwaysDeny,ServiceQuota',
                 kube_apiserver.kube_apiserver_command
  end

  def test_multiple_flags_are_set
    kube_apiserver do
      admission_control %w(AlwaysDeny ServiceQuota)
      advertise_address '100.2.3.4'
    end

    assert_equal '/usr/sbin/kube-apiserver '\
        '--admission-control=AlwaysDeny,ServiceQuota '\
        '--advertise-address=100.2.3.4',
                 kube_apiserver.kube_apiserver_command
  end

  def test_non_commandline_flag_properties_are_excluded
    kube_apiserver do
      run_user 'another-user' # non-commandline flag
      admission_control %w(AlwaysDeny ServiceQuota) # commandline flag
    end

    assert_equal '/usr/sbin/kube-apiserver '\
        '--admission-control=AlwaysDeny,ServiceQuota',
                 kube_apiserver.kube_apiserver_command
  end

  # rubocop:disable Metrics/LineLength, Style/AsciiComments
  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  # しかたない
  # Demo of
  # https://github.com/kubernetes/kubernetes/blob/master/cluster/images/hyperkube/master-multi.json#L30-L44
  def test_master_multi_port
    kube_apiserver do
      service_cluster_ip_range '10.0.0.1/24'
      insecure_bind_address '0.0.0.0'
      etcd_servers 'http://127.0.0.1:4001'
      admission_control %w(NamespaceLifecycle LimitRanger SecurityContextDeny ServiceAccount ResourceQuota)
      client_ca_file '/srv/kubernetes/ca.crt'
      basic_auth_file '/srv/kubernetes/basic_auth.csv'
      min_request_timeout 300
      tls_cert_file '/srv/kubernetes/server.cert'
      tls_private_key_file '/srv/kubernetes/server.key'
      token_auth_file '/srv/kubernetes/known_tokens.csv'
      allow_privileged true
      v 4
    end

    assert_match(/--v=4/, kube_apiserver.kube_apiserver_command)
  end
end
