require 'spec_helper'

describe 'CycleAnalytics#review', feature: true do
  let(:project) { create(:project) }
  let(:from_date) { 10.days.ago }
  let(:user) { create(:user, :admin) }
  subject { CycleAnalytics.new(project, from: from_date) }

  generate_cycle_analytics_spec(phase: :review,
                                data_fn: -> (context) { { issue: context.create(:issue, project: context.project) } },
                                start_time_conditions: [["merge request that closes issue is created", -> (context, data) { context.create_merge_request_closing_issue(data[:issue]) }]],
                                end_time_conditions:   [["merge request that closes issue is merged", -> (context, data) { context.merge_merge_requests_closing_issue(data[:issue]) }]],
                                post_fn: -> (context, data) { context.deploy_master })

  context "when a regular merge request (that doesn't close the issue) is created and merged" do
    it "returns nil" do
      5.times do
        MergeRequests::MergeService.new(project, user).execute(create(:merge_request))

        deploy_master
      end

      expect(subject.review).to be_nil
    end
  end
end
