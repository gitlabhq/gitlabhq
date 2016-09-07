require 'spec_helper'

describe 'CycleAnalytics#issue', models: true do
  let(:project) { create(:project) }
  let(:from_date) { 10.days.ago }
  subject { CycleAnalytics.new(project, from: from_date) }

  generate_cycle_analytics_spec(phase: :issue,
                                data_fn: -> (context) { { issue: context.build(:issue, project: context.project) } },
                                start_time_conditions: [["issue created", -> (context, data) { data[:issue].save }]],
                                end_time_conditions:   [["issue associated with a milestone", -> (context, data) { data[:issue].update(milestone: context.create(:milestone, project: context.project)) if data[:issue].persisted? }],
                                                        ["list label added to issue", -> (context, data) { data[:issue].update(label_ids: [context.create(:label, lists: [context.create(:list)]).id]) if data[:issue].persisted? }]])

  context "when a regular label (instead of a list label) is added to the issue" do
    it "returns nil" do
      5.times do
        regular_label = create(:label)
        issue = create(:issue, project: project)
        issue.update(label_ids: [regular_label.id])
      end

      expect(subject.issue).to be_nil
    end
  end
end
