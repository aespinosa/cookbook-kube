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
