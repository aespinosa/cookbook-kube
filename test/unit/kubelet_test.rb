require 'chef/resource'
require 'kubelet'

require 'minitest/autorun'

class KubeletTest < Minitest::Test
  def kubelet
    @kubelet ||= KubernetesCookbook::KubeletService.new 'test'
  end

  def test_default_api_server_is_nil
    assert_nil kubelet.api_servers
  end

  def test_default_kubelet_command_is_just_the_binary
    assert_equal '/usr/sbin/kubelet', kubelet.kubelet_command
  end

  def test_kubelet_command_with_apiserver_flags
    kubelet.api_servers 'http://127.0.0.1:8080'
    assert_match %r{--api-servers=http://127.0.0.1:8080},
                 kubelet.kubelet_command
  end

  def test_multiple_apiservers
    kubelet.api_servers %w(http://127.0.0.1:8080 https://10.0.0.1:6443)
    assert_match %r{--api-servers=http://127.0.0.1:8080,https://10.0.0.1:6443},
                 kubelet.kubelet_command
  end
end
