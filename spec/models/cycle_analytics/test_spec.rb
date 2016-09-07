require 'spec_helper'

describe 'CycleAnalytics#test', feature: true do
  let(:project) { create(:project) }
  let(:from_date) { 10.days.ago }
  let(:user) { create(:user, :admin) }
  subject { CycleAnalytics.new(project, from: from_date) }

  generate_cycle_analytics_spec(phase: :test,
                                data_fn: lambda do |context|
                                  issue = context.create(:issue, project: context.project)
                                  merge_request = context.create_merge_request_closing_issue(issue)
                                  { pipeline: context.create(:ci_pipeline, ref: "refs/heads/#{merge_request.source_branch}", sha: merge_request.diff_head_sha) }
                                end,
                                start_time_conditions: [["pipeline is started", -> (context, data) { data[:pipeline].run! }]],
                                end_time_conditions:   [["pipeline is finished", -> (context, data) { data[:pipeline].succeed! }]])

  context "when the pipeline is for a regular merge request (that doesn't close an issue)" do
    it "returns nil" do
      5.times do
        merge_request = create(:merge_request)
        pipeline = create(:ci_pipeline, ref: "refs/heads/#{merge_request.source_branch}", sha: merge_request.diff_head_sha)

        pipeline.run!
        pipeline.succeed!
      end

      expect(subject.test).to be_nil
    end
  end

  context "when the pipeline is not for a merge request" do
    it "returns nil" do
      5.times do
        pipeline = create(:ci_pipeline, ref: "refs/heads/master", sha: project.repository.commit('master').sha)

        pipeline.run!
        pipeline.succeed!
      end

      expect(subject.test).to be_nil
    end
  end

  context "when the pipeline is dropped (failed)" do
    it "returns nil" do
      5.times do
        issue = create(:issue, project: project)
        merge_request = create_merge_request_closing_issue(issue)
        pipeline = create(:ci_pipeline, ref: "refs/heads/#{merge_request.source_branch}", sha: merge_request.diff_head_sha)

        pipeline.run!
        pipeline.drop!
      end

      expect(subject.test).to be_nil
    end
  end

  context "when the pipeline is cancelled" do
    it "returns nil" do
      5.times do
        issue = create(:issue, project: project)
        merge_request = create_merge_request_closing_issue(issue)
        pipeline = create(:ci_pipeline, ref: "refs/heads/#{merge_request.source_branch}", sha: merge_request.diff_head_sha)

        pipeline.run!
        pipeline.cancel!
      end

      expect(subject.test).to be_nil
    end
  end
end
