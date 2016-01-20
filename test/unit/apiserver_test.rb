require 'chef/resource'

require 'kube_apiserver'

require 'minitest/autorun'

class ApiserverTest < Minitest::Test
  include KubernetesCookbook

  def kube_apiserver
    KubeApiserver.new 'default'
  end

  def test_has_a_name
    assert_equal 'default', kube_apiserver.name
  end

  def test_default_action_is_create
    assert_equal [:create], kube_apiserver.action
  end

  def test_action_create_should_work
    skip 'need a real chef run context'
    kube_apiserver.run_action :create
  end
end
