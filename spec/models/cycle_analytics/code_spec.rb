# frozen_string_literal: true

require 'spec_helper'

describe 'CycleAnalytics#code' do
  extend CycleAnalyticsHelpers::TestGeneration

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:from_date) { 10.days.ago }
  let_it_be(:user) { create(:user, :admin) }
  let_it_be(:project_level) { CycleAnalytics::ProjectLevel.new(project, options: { from: from_date }) }

  subject { project_level }

  context 'with deployment' do
    generate_cycle_analytics_spec(
      phase: :code,
      data_fn: -> (context) { { issue: context.create(:issue, project: context.project) } },
      start_time_conditions: [["issue mentioned in a commit",
                               -> (context, data) do
                                 context.create_commit_referencing_issue(data[:issue])
                               end]],
      end_time_conditions: [["merge request that closes issue is created",
                             -> (context, data) do
                               context.create_merge_request_closing_issue(context.user, context.project, data[:issue])
                             end]],
      post_fn: -> (context, data) do
      end)

    context "when a regular merge request (that doesn't close the issue) is created" do
      it "returns nil" do
        issue = create(:issue, project: project)

        create_commit_referencing_issue(issue)
        create_merge_request_closing_issue(user, project, issue, message: "Closes nothing")

        merge_merge_requests_closing_issue(user, project, issue)
        deploy_master(user, project)

        expect(subject[:code].project_median).to be_nil
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
      end_time_conditions: [["merge request that closes issue is created",
                             -> (context, data) do
                               context.create_merge_request_closing_issue(context.user, context.project, data[:issue])
                             end]],
      post_fn: -> (context, data) do
      end)

    context "when a regular merge request (that doesn't close the issue) is created" do
      it "returns nil" do
        issue = create(:issue, project: project)

        create_commit_referencing_issue(issue)
        create_merge_request_closing_issue(user, project, issue, message: "Closes nothing")

        merge_merge_requests_closing_issue(user, project, issue)

        expect(subject[:code].project_median).to be_nil
      end
    end
  end
end
