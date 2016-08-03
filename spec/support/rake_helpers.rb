module RakeHelpers
  def run_rake_task(task_name)
    Rake::Task[task_name].reenable
    Rake.application.invoke_task task_name
  end

  def stub_warn_user_is_not_gitlab
    allow_any_instance_of(Object).to receive(:warn_user_is_not_gitlab)
  end
end
