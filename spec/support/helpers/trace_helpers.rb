# frozen_string_literal: true

module TraceHelpers
  def create_legacy_trace(build, content)
    File.open(legacy_trace_path(build), 'wb') { |stream| stream.write(content) }
  end

  def create_legacy_trace_in_db(build, content)
    build.update_column(:trace, content)
  end

  def legacy_trace_path(build)
    legacy_trace_dir = File.join(Settings.gitlab_ci.builds_path,
      build.created_at.utc.strftime("%Y_%m"),
      build.project_id.to_s)

    FileUtils.mkdir_p(legacy_trace_dir)

    File.join(legacy_trace_dir, "#{build.id}.log")
  end

  def archived_trace_path(job_artifact)
    disk_hash = Digest::SHA2.hexdigest(job_artifact.project_id.to_s)
    creation_date = job_artifact.created_at.utc.strftime('%Y_%m_%d')

    File.join(Gitlab.config.artifacts.path, disk_hash[0..1], disk_hash[2..3], disk_hash,
      creation_date, job_artifact.job_id.to_s, job_artifact.id.to_s, 'job.log')
  end
end
