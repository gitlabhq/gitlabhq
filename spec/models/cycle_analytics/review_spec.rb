require 'spec_helper'

describe 'CycleAnalytics#review', feature: true do
  let(:project) { create(:project) }
  let(:from_date) { 10.days.ago }
  let(:user) { create(:user, :admin) }
  subject { CycleAnalytics.new(project, from: from_date) }

  def create_merge_request_closing_issue(issue)
    source_branch = FFaker::Product.brand
    project.repository.add_branch(user, source_branch, 'master')
    sha = project.repository.commit_file(user, FFaker::Product.brand, "content", "commit message", source_branch, false)
    project.repository.commit(sha)

    opts = {
      title: 'Awesome merge_request',
      description: "Fixes #{issue.to_reference}",
      source_branch: source_branch,
      target_branch: 'master'
    }

    MergeRequests::CreateService.new(project, user, opts).execute
  end


  def merge_merge_requests_closing_issue(issue)
    merge_requests = issue.closed_by_merge_requests
    merge_requests.each { |merge_request| MergeRequests::MergeService.new(project, user).execute(merge_request) }
  end

  generate_cycle_analytics_spec(phase: :review,
                                data_fn: -> (context) { { issue: context.create(:issue, project: context.project) } },
                                start_time_conditions: [["merge request that closes issue is created", -> (context, data) { context.create_merge_request_closing_issue(data[:issue]) }]],
                                end_time_conditions:   [["merge request that closes issue is merged", -> (context, data) { context.merge_merge_requests_closing_issue(data[:issue]) }]])

  context "when a regular merge request (that doesn't close the issue) is created and merged" do
    it "returns nil" do
      5.times do
        MergeRequests::MergeService.new(project, user).execute(create(:merge_request))
      end

      expect(subject.review).to be_nil
    end
  end
end
