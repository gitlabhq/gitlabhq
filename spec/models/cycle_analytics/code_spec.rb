require 'spec_helper'

describe 'CycleAnalytics#code', feature: true do
  let(:project) { create(:project) }
  let(:from_date) { 10.days.ago }
  let(:user) { create(:user, :admin) }
  subject { CycleAnalytics.new(project, from: from_date) }

  def create_commit_referencing_issue(issue)
    sha = project.repository.commit_file(user, random_git_name, "content", "Commit for ##{issue.iid}", "master", false)
    commit = project.repository.commit(sha)
    commit.create_cross_references!(user)
  end

  def create_merge_request_closing_issue(issue, message: nil)
    source_branch = random_git_name
    project.repository.add_branch(user, source_branch, 'master')

    opts = {
      title: 'Awesome merge_request',
      description: message || "Fixes #{issue.to_reference}",
      source_branch: source_branch,
      target_branch: 'master'
    }

    MergeRequests::CreateService.new(project, user, opts).execute
  end

  generate_cycle_analytics_spec(phase: :code,
                                data_fn: -> (context) { { issue: context.create(:issue, project: context.project) } },
                                start_time_conditions: [["issue mentioned in a commit", -> (context, data) { context.create_commit_referencing_issue(data[:issue]) }]],
                                end_time_conditions:   [["merge request that closes issue is created", -> (context, data) { context.create_merge_request_closing_issue(data[:issue]) }]])

  context "when a regular merge request (that doesn't close the issue) is created" do
    it "returns nil" do
      5.times do
        issue = create(:issue, project: project)

        create_commit_referencing_issue(issue)
        create_merge_request_closing_issue(issue, message: "Closes nothing")
      end

      expect(subject.code).to be_nil
    end
  end
end
