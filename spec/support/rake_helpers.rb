module RakeHelpers
  def run_rake_task(task_name, *args)
    Rake::Task[task_name].reenable
    Rake.application.invoke_task("#{task_name}[#{args.join(',')}]")
  end

  def stub_warn_user_is_not_gitlab
    allow(main_object).to receive(:warn_user_is_not_gitlab)
  end

  def silence_output
    allow(main_object).to receive(:puts)
    allow(main_object).to receive(:print)
  end

  def main_object
    @main_object ||= TOPLEVEL_BINDING.eval('self')
  end
end
