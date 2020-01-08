# frozen_string_literal: true

require 'spec_helper'

describe 'CycleAnalytics#test' do
  extend CycleAnalyticsHelpers::TestGeneration

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:from_date) { 10.days.ago }
  let_it_be(:user) { create(:user, :admin) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:project_level) { CycleAnalytics::ProjectLevel.new(project, options: { from: from_date }) }
  let!(:merge_request) { create_merge_request_closing_issue(user, project, issue) }

  subject { project_level }

  generate_cycle_analytics_spec(
    phase: :test,
    data_fn: lambda do |context|
      issue = context.issue
      merge_request = context.create_merge_request_closing_issue(context.user, context.project, issue)
      pipeline = context.create(:ci_pipeline, ref: merge_request.source_branch, sha: merge_request.diff_head_sha, project: context.project, head_pipeline_of: merge_request)
      { pipeline: pipeline, issue: issue }
    end,
    start_time_conditions: [["pipeline is started", -> (context, data) { data[:pipeline].run! }]],
    end_time_conditions:   [["pipeline is finished", -> (context, data) { data[:pipeline].succeed! }]],
    post_fn: -> (context, data) do
    end)

  context "when the pipeline is for a regular merge request (that doesn't close an issue)" do
    it "returns nil" do
      pipeline = create(:ci_pipeline, ref: "refs/heads/#{merge_request.source_branch}", sha: merge_request.diff_head_sha)

      pipeline.run!
      pipeline.succeed!

      expect(subject[:test].project_median).to be_nil
    end
  end

  context "when the pipeline is not for a merge request" do
    it "returns nil" do
      pipeline = create(:ci_pipeline, ref: "refs/heads/master", sha: project.repository.commit('master').sha)

      pipeline.run!
      pipeline.succeed!

      expect(subject[:test].project_median).to be_nil
    end
  end

  context "when the pipeline is dropped (failed)" do
    it "returns nil" do
      pipeline = create(:ci_pipeline, ref: "refs/heads/#{merge_request.source_branch}", sha: merge_request.diff_head_sha)

      pipeline.run!
      pipeline.drop!

      expect(subject[:test].project_median).to be_nil
    end
  end

  context "when the pipeline is cancelled" do
    it "returns nil" do
      pipeline = create(:ci_pipeline, ref: "refs/heads/#{merge_request.source_branch}", sha: merge_request.diff_head_sha)

      pipeline.run!
      pipeline.cancel!

      expect(subject[:test].project_median).to be_nil
    end
  end
end
