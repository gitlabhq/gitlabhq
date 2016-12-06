require 'spec_helper'

describe 'CycleAnalytics#staging', feature: true do
  extend CycleAnalyticsHelpers::TestGeneration

  let(:project) { create(:project) }
  let(:from_date) { 10.days.ago }
  let(:user) { create(:user, :admin) }
  subject { CycleAnalytics.new(project, user, from: from_date) }

  generate_cycle_analytics_spec(
    phase: :staging,
    data_fn: lambda do |context|
      issue = context.create(:issue, project: context.project)
      { issue: issue, merge_request: context.create_merge_request_closing_issue(issue) }
    end,
    start_time_conditions: [["merge request that closes issue is merged",
                             -> (context, data) do
                               context.merge_merge_requests_closing_issue(data[:issue])
                             end ]],
    end_time_conditions:   [["merge request that closes issue is deployed to production",
                             -> (context, data) do
                               context.deploy_master
                             end],
                            ["production deploy happens after merge request is merged (along with other changes)",
                             lambda do |context, data|
                               # Make other changes on master
                               sha = context.project.repository.commit_file(
                                 context.user,
                                 context.random_git_name,
                                 "content",
                                 "commit message",
                                 'master',
                                 false)
                               context.project.repository.commit(sha)

                               context.deploy_master
                             end]])

  context "when a regular merge request (that doesn't close the issue) is merged and deployed" do
    it "returns nil" do
      5.times do
        merge_request = create(:merge_request)
        MergeRequests::MergeService.new(project, user).execute(merge_request)
        deploy_master
      end

      expect(subject.staging).to be_nil
    end
  end

  context "when the deployment happens to a non-production environment" do
    it "returns nil" do
      5.times do
        issue = create(:issue, project: project)
        merge_request = create_merge_request_closing_issue(issue)
        MergeRequests::MergeService.new(project, user).execute(merge_request)
        deploy_master(environment: 'staging')
      end

      expect(subject.staging).to be_nil
    end
  end
end
