module TraceHelpers
  def create_trace_file(builds_path, yyyy_mm, project_id_or_ci_id, job_id, trace_content)
    trace_dir = "#{builds_path}/#{yyyy_mm}/#{project_id_or_ci_id}"
    trace_path = File.join(trace_dir, "#{job_id}.log")

    FileUtils.mkdir_p(trace_dir)

    File.open(File.join(trace_dir, "#{job_id}.log"), 'w') do |file|
      file.write(trace_content)
    end

    yield trace_path if block_given?
  end

  def artifacts_path?(path)
    %r{.{2}/.{2}/.{64}/\d{4}_\d{2}_\d{2}/\d{1,}/\d{1,}/\d{1,}.log} =~ path
  end

  def simulate_backup_path(path, status)
    case status
    when :not_found
      path.gsub(/(\d{4}_\d{2})/, '\1_not_found')
    when :migratable
      path.gsub(/(\d{4}_\d{2})/, '\1_migrated')
    end
  end

  def not_completed_path(path)
    path.gsub(/(\d{4}_\d{2})/, '\1_not_found')
  end
end
