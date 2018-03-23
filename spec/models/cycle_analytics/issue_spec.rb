require 'spec_helper'

describe 'CycleAnalytics#issue' do
  extend CycleAnalyticsHelpers::TestGeneration

  let(:project) { create(:project, :repository) }
  let(:from_date) { 10.days.ago }
  let(:user) { create(:user, :admin) }
  subject { CycleAnalytics.new(project, from: from_date) }

  generate_cycle_analytics_spec(
    phase: :issue,
    data_fn: -> (context) { { issue: context.build(:issue, project: context.project) } },
    start_time_conditions: [["issue created", -> (context, data) { data[:issue].save }]],
    end_time_conditions:   [["issue associated with a milestone",
                             -> (context, data) do
                               if data[:issue].persisted?
                                 data[:issue].update(milestone: context.create(:milestone, project: context.project))
                               end
                             end],
                            ["list label added to issue",
                             -> (context, data) do
                               if data[:issue].persisted?
                                 data[:issue].update(label_ids: [context.create(:label, lists: [context.create(:list)]).id])
                               end
                             end]],
    post_fn: -> (context, data) do
      if data[:issue].persisted?
        context.create_merge_request_closing_issue(context.user, context.project, data[:issue].reload)
        context.merge_merge_requests_closing_issue(context.user, context.project, data[:issue])
      end
    end)

  context "when a regular label (instead of a list label) is added to the issue" do
    it "returns nil" do
      regular_label = create(:label)
      issue = create(:issue, project: project)
      issue.update(label_ids: [regular_label.id])

      create_merge_request_closing_issue(user, project, issue)
      merge_merge_requests_closing_issue(user, project, issue)

      expect(subject[:issue].median).to be_nil
    end
  end
end
