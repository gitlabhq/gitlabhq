module CycleAnalyticsHelpers
  def create_commit_referencing_issue(issue, branch_name: generate(:branch))
    project.repository.add_branch(user, branch_name, 'master')
    create_commit("Commit for ##{issue.iid}", issue.project, user, branch_name)
  end

  def create_commit(message, project, user, branch_name, count: 1)
    repository = project.repository
    oldrev = repository.commit(branch_name).sha

    if Timecop.frozen? && Gitlab::GitalyClient.feature_enabled?(:operation_user_commit_files)
      mock_gitaly_multi_action_dates(repository.raw)
    end

    commit_shas = Array.new(count) do |index|
      commit_sha = repository.create_file(user, generate(:branch), "content", message: message, branch_name: branch_name)
      repository.commit(commit_sha)

      commit_sha
    end

    GitPushService.new(project,
                       user,
                       oldrev: oldrev,
                       newrev: commit_shas.last,
                       ref: 'refs/heads/master').execute
  end

  def create_cycle(user, project, issue, mr, milestone, pipeline)
    issue.update(milestone: milestone)
    pipeline.run

    ci_build = create(:ci_build, pipeline: pipeline, status: :success, author: user)

    merge_merge_requests_closing_issue(user, project, issue)
    ProcessCommitWorker.new.perform(project.id, user.id, mr.commits.last.to_hash)

    ci_build
  end

  def create_merge_request_closing_issue(user, project, issue, message: nil, source_branch: nil, commit_message: 'commit message')
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

    mr = MergeRequests::CreateService.new(project, user, opts).execute
    NewMergeRequestWorker.new.perform(mr, user)
    mr
  end

  def merge_merge_requests_closing_issue(user, project, issue)
    merge_requests = issue.closed_by_merge_requests(user)

    merge_requests.each { |merge_request| MergeRequests::MergeService.new(project, user).execute(merge_request) }
  end

  def deploy_master(user, project, environment: 'production')
    dummy_job =
      case environment
      when 'production'
        dummy_production_job(user, project)
      when 'staging'
        dummy_staging_job(user, project)
      else
        raise ArgumentError
      end

    CreateDeploymentService.new(dummy_job).execute
  end

  def dummy_production_job(user, project)
    new_dummy_job(user, project, 'production')
  end

  def dummy_staging_job(user, project)
    new_dummy_job(user, project, 'staging')
  end

  def dummy_pipeline(project)
    Ci::Pipeline.new(
      sha: project.repository.commit('master').sha,
      ref: 'master',
      source: :push,
      project: project,
      protected: false)
  end

  def new_dummy_job(user, project, environment)
    project.environments.find_or_create_by(name: environment)

    Ci::Build.new(
      project: project,
      user: user,
      environment: environment,
      ref: 'master',
      tag: false,
      name: 'dummy',
      stage: 'dummy',
      pipeline: dummy_pipeline(project),
      protected: false)
  end

  def mock_gitaly_multi_action_dates(raw_repository)
    allow(raw_repository).to receive(:multi_action).and_wrap_original do |m, *args|
      new_date = Time.now
      branch_update = m.call(*args)

      if branch_update.newrev
        _, opts = args
        commit = raw_repository.commit(branch_update.newrev).rugged_commit
        branch_update.newrev = commit.amend(
          update_ref: "#{Gitlab::Git::BRANCH_REF_PREFIX}#{opts[:branch_name]}",
          author: commit.author.merge(time: new_date),
          committer: commit.committer.merge(time: new_date)
        )
      end

      branch_update
    end
  end
end

RSpec.configure do |config|
  config.include CycleAnalyticsHelpers
end
