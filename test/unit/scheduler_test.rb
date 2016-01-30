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

module FakeCommand
  def kube_scheduler_command
    'fake scheduler command'
  end
end

class ActionStart < Minitest::Test
  require_relative 'provider_helper'

  def provider
    @provider ||= begin
      run = Cheffish::ChefRun.new
      resource = run.compile_recipe do
        kube_scheduler 'testing'
      end
      resource.extend FakeCommand
      provider = resource.provider_for_action(:start)
      provider.extend ProviderInspection
    end
  end

  def test_passes_scheduler_command_to_systemd
    provider.action_start

    unit = provider.inline_resources.find 'template[/etc/systemd/system'\
        '/kube-scheduler.service]'

    command = unit.variables[:kube_scheduler_command]
    assert_equal 'fake scheduler command', command
  end

end
