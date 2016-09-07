module CycleAnalyticsHelpers
  def create_commit_referencing_issue(issue)
    sha = project.repository.commit_file(user, random_git_name, "content", "Commit for ##{issue.iid}", "master", false)
    commit = project.repository.commit(sha)
    commit.create_cross_references!(user)
  end

  def create_merge_request_closing_issue(issue, message: nil)
    source_branch = random_git_name
    project.repository.add_branch(user, source_branch, 'master')
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
    merge_requests = issue.closed_by_merge_requests
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
