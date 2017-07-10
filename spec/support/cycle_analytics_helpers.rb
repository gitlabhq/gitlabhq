module CycleAnalyticsHelpers
  def create_commit_referencing_issue(issue, branch_name: generate(:branch))
    project.repository.add_branch(user, branch_name, 'master')
    create_commit("Commit for ##{issue.iid}", issue.project, user, branch_name)
  end

  def create_commit(message, project, user, branch_name, count: 1)
    oldrev = project.repository.commit(branch_name).sha
    commit_shas = Array.new(count) do |index|
      commit_sha = project.repository.create_file(user, generate(:branch), "content", message: message, branch_name: branch_name)
      project.repository.commit(commit_sha)

      commit_sha
    end

    GitPushService.new(project,
                       user,
                       oldrev: oldrev,
                       newrev: commit_shas.last,
                       ref: 'refs/heads/master').execute
  end

  def create_merge_request_closing_issue(issue, message: nil, source_branch: nil, commit_message: 'commit message')
    if !source_branch || project.repository.commit(source_branch).blank?
      source_branch = generate(:branch)
      project.repository.add_branch(user, source_branch, 'master')
    end

    sha = project.repository.create_file(
      user,
      generate(:branch),
      'content',
      message: commit_message,
      branch_name: source_branch)
    project.repository.commit(sha)

    opts = {
      title: 'Awesome merge_request',
      description: message || "Fixes #{issue.to_reference}",
      source_branch: source_branch,
      target_branch: 'master'
    }

    MergeRequests::CreateService.new(project, user, opts).execute
  end

  def merge_merge_requests_closing_issue(issue)
    merge_requests = issue.closed_by_merge_requests(user)

    merge_requests.each { |merge_request| MergeRequests::MergeService.new(project, user).execute(merge_request) }
  end

  def deploy_master(environment: 'production')
    dummy_job =
      case environment
      when 'production'
        dummy_production_job
      when 'staging'
        dummy_staging_job
      else
        raise ArgumentError
      end

    CreateDeploymentService.new(dummy_job).execute
  end

  def dummy_production_job
    @dummy_job ||= new_dummy_job('production')
  end

  def dummy_staging_job
    @dummy_job ||= new_dummy_job('staging')
  end

  def dummy_pipeline
    @dummy_pipeline ||=
      Ci::Pipeline.new(
        sha: project.repository.commit('master').sha,
        project: project)
  end

  def new_dummy_job(environment)
    project.environments.find_or_create_by(name: environment)

    Ci::Build.new(
      project: project,
      user: user,
      environment: environment,
      ref: 'master',
      tag: false,
      name: 'dummy',
      pipeline: dummy_pipeline)
  end
end

RSpec.configure do |config|
  config.include CycleAnalyticsHelpers
end
