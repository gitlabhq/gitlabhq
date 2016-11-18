require 'spec_helper'

describe 'CycleAnalytics#code', feature: true do
  extend CycleAnalyticsHelpers::TestGeneration

  let(:project) { create(:project) }
  let(:from_date) { 10.days.ago }
  let(:user) { create(:user, :admin) }
  subject { CycleAnalytics.new(project, user, from: from_date) }

  context 'with deployment' do
    generate_cycle_analytics_spec(
      phase: :code,
      data_fn: -> (context) { { issue: context.create(:issue, project: context.project) } },
      start_time_conditions: [["issue mentioned in a commit",
                               -> (context, data) do
                                 context.create_commit_referencing_issue(data[:issue])
                               end]],
      end_time_conditions:   [["merge request that closes issue is created",
                               -> (context, data) do
                                 context.create_merge_request_closing_issue(data[:issue])
                               end]],
      post_fn: -> (context, data) do
        context.merge_merge_requests_closing_issue(data[:issue])
        context.deploy_master
      end)

    context "when a regular merge request (that doesn't close the issue) is created" do
      it "returns nil" do
        5.times do
          issue = create(:issue, project: project)

          create_commit_referencing_issue(issue)
          create_merge_request_closing_issue(issue, message: "Closes nothing")

          merge_merge_requests_closing_issue(issue)
          deploy_master
        end

        expect(subject.code).to be_nil
      end
    end
  end

  context 'without deployment' do
    generate_cycle_analytics_spec(
      phase: :code,
      data_fn: -> (context) { { issue: context.create(:issue, project: context.project) } },
      start_time_conditions: [["issue mentioned in a commit",
                               -> (context, data) do
                                 context.create_commit_referencing_issue(data[:issue])
                               end]],
      end_time_conditions:   [["merge request that closes issue is created",
                               -> (context, data) do
                                 context.create_merge_request_closing_issue(data[:issue])
                               end]],
      post_fn: -> (context, data) do
        context.merge_merge_requests_closing_issue(data[:issue])
      end)

    context "when a regular merge request (that doesn't close the issue) is created" do
      it "returns nil" do
        5.times do
          issue = create(:issue, project: project)

          create_commit_referencing_issue(issue)
          create_merge_request_closing_issue(issue, message: "Closes nothing")

          merge_merge_requests_closing_issue(issue)
        end

        expect(subject.code).to be_nil
      end
    end
  end
end
