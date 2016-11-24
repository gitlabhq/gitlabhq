module CycleAnalyticsHelpers
  def create_commit_referencing_issue(issue, branch_name: random_git_name)
    project.repository.add_branch(user, branch_name, 'master')
    create_commit("Commit for ##{issue.iid}", issue.project, user, branch_name)
  end

  def create_commit(message, project, user, branch_name, count: 1)
    oldrev = project.repository.commit(branch_name).sha
    commit_shas = Array.new(count) do |index|
      filename = random_git_name

      options = {
        committer: project.repository.user_to_committer(user),
        author: project.repository.user_to_committer(user),
        commit: { message: message, branch: branch_name, update_ref: true },
        file: { content: "content", path: filename, update: false }
      }

      commit_sha = Gitlab::Git::Blob.commit(project.repository, options)
      project.repository.commit(commit_sha)

      commit_sha
    end

    GitPushService.new(project,
                       user,
                       oldrev: oldrev,
                       newrev: commit_shas.last,
                       ref: 'refs/heads/master').execute
  end

  def create_merge_request_closing_issue(issue, message: nil, source_branch: nil)
    if !source_branch || project.repository.commit(source_branch).blank?
      source_branch = random_git_name
      project.repository.add_branch(user, source_branch, 'master')
    end

    sha = project.repository.commit_file(user, random_git_name, "content", "commit message", source_branch, false)
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
    CreateDeploymentService.new(project, user, {
                                  environment: environment,
                                  ref: 'master',
                                  tag: false,
                                  sha: project.repository.commit('master').sha
                                }).execute
  end
end

RSpec.configure do |config|
  config.include CycleAnalyticsHelpers
end
