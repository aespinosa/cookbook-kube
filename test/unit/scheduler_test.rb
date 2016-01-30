require 'command_generator'
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

class CommandTest < Minitest::Test
  def kube_scheduler(&block)
    @resource ||= begin
      resource = KubernetesCookbook::KubeScheduler.new 'command test'
      resource.instance_eval(&block) if block
      resource
    end
  end

  def test_default_property_values_renders_no_flags
    assert_equal '/usr/sbin/kube-scheduler',
                 kube_scheduler.kube_scheduler_command
  end

  def test_array_values_become_comma_separated_arguments
    kube_scheduler do
      algorithm_provider %w(DefaultProvider NonExistentProvider) # An array flag
    end

    assert_equal '/usr/sbin/kube-scheduler '\
        '--algorithm-provider=DefaultProvider,NonExistentProvider',
                 kube_scheduler.kube_scheduler_command
  end

  def test_multiple_flags_are_set
    kube_scheduler do
      address '0.0.0.0'
      algorithm_provider %w(DefaultProvider NonExistentProvider)
    end

    assert_equal '/usr/sbin/kube-scheduler '\
        '--address=0.0.0.0 '\
        '--algorithm-provider=DefaultProvider,NonExistentProvider',
                 kube_scheduler.kube_scheduler_command
  end

  def test_non_commandline_flag_properties_are_excluded
    kube_scheduler do
      run_user 'another-user' # non-commandline flag
      algorithm_provider %w(DefaultProvider NonExistentProvider) # commandline
    end

    assert_equal '/usr/sbin/kube-scheduler '\
        '--algorithm-provider=DefaultProvider,NonExistentProvider',
                 kube_scheduler.kube_scheduler_command
  end
end
