require 'kube_scheduler'

require 'minitest/autorun'

class SchedulerTest < Minitest::Test
  def kube_scheduler
    @server ||= KubernetesCookbook::KubeScheduler.new 'testing'
  end

  def test_has_a_name
    assert_equal 'testing', kube_scheduler.name
  end

  def test_default_action_is_create
    assert_equal [:create], kube_scheduler.action
  end
end
