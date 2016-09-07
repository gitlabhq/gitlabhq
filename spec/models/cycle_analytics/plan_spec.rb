require 'spec_helper'

describe 'CycleAnalytics#plan', feature: true do
  let(:project) { create(:project) }
  let(:from_date) { 10.days.ago }
  let(:user) { create(:user, :admin) }
  subject { CycleAnalytics.new(project, from: from_date) }

  generate_cycle_analytics_spec(phase: :plan,
                                data_fn: -> (context) { { issue: context.create(:issue, project: context.project) } },
                                start_time_conditions: [["issue associated with a milestone", -> (context, data) { data[:issue].update(milestone: context.create(:milestone, project: context.project)) }],
                                                        ["list label added to issue", -> (context, data) { data[:issue].update(label_ids: [context.create(:label, lists: [context.create(:list)]).id]) }]],
                                end_time_conditions:   [["issue mentioned in a commit", -> (context, data) { context.create_commit_referencing_issue(data[:issue]) }]])

  context "when a regular label (instead of a list label) is added to the issue" do
    it "returns nil" do
      label = create(:label)
      issue = create(:issue, project: project)
      issue.update(label_ids: [label.id])
      create_commit_referencing_issue(issue)

      expect(subject.issue).to be_nil
    end
  end
end
