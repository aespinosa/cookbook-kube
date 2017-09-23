require 'command_generator'
require 'chef'
require 'kube_apiserver'

require 'minitest/autorun'

class CommandGeneratorTest < Minitest::Test
  include KubernetesCookbook

  def resource(&block)
    @resource ||= begin
      resource = KubernetesCookbook::KubeApiserver.new 'command test'
      resource.instance_eval(&block) if block
      resource
    end
  end

  def command_generator
    @command_generator ||= begin
      CommandGenerator.new '/the-command', resource
    end
  end

  def test_default_property_values_renders_no_flags
    assert_equal '/the-command',
                 command_generator.generate
  end

  def test_array_values_become_comma_separated_arguments
    resource do
      admission_control %w(AlwaysDeny ServiceQuota) # An array flag
    end

    assert_equal '/the-command '\
        '--admission-control=AlwaysDeny,ServiceQuota',
                 command_generator.generate
  end

  def test_multiple_flags_are_set
    resource do
      admission_control %w(AlwaysDeny ServiceQuota)
      advertise_address '100.2.3.4'
    end

    assert_equal '/the-command '\
        '--admission-control=AlwaysDeny,ServiceQuota '\
        '--advertise-address=100.2.3.4',
                 command_generator.generate
  end

  def test_non_commandline_flag_properties_are_excluded
    resource do
      # non-commandline flag
      run_user 'another-user'
      remote 'a-url'
      checksum 'a-checksum'
      version 'some-version'
      # commandline flag
      admission_control %w(AlwaysDeny ServiceQuota)
    end

    assert_equal '/the-command '\
        '--admission-control=AlwaysDeny,ServiceQuota',
                 command_generator.generate
  end

  # rubocop:disable Metrics/MethodLength
  # しかたない
  # Demo of
  # https://github.com/kubernetes/kubernetes/blob/master/cluster/images/hyperkube/master-multi.json#L30-L44
  def test_master_multi_port
    resource do
      service_cluster_ip_range '10.0.0.1/24'
      insecure_bind_address '0.0.0.0'
      etcd_servers 'http://127.0.0.1:2379'
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

    assert_match(/--v=4/, command_generator.generate)
  end
end
