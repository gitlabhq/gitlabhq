require 'spec_helper'

describe 'CycleAnalytics#issue', models: true do
  let(:project) { create(:project) }
  let(:from_date) { 10.days.ago }
  let(:user) { create(:user, :admin) }
  subject { CycleAnalytics.new(project, from: from_date) }

  generate_cycle_analytics_spec(phase: :issue,
                                data_fn: -> (context) { { issue: context.build(:issue, project: context.project) } },
                                start_time_conditions: [["issue created", -> (context, data) { data[:issue].save }]],
                                end_time_conditions:   [["issue associated with a milestone", -> (context, data) { data[:issue].update(milestone: context.create(:milestone, project: context.project)) if data[:issue].persisted? }],
                                                        ["list label added to issue", -> (context, data) { data[:issue].update(label_ids: [context.create(:label, lists: [context.create(:list)]).id]) if data[:issue].persisted? }]],
                                post_fn: -> (context, data) do
                                  if data[:issue].persisted?
                                    context.create_merge_request_closing_issue(data[:issue].reload)
                                    context.merge_merge_requests_closing_issue(data[:issue])
                                    context.deploy_master
                                  end
                                end)

  context "when a regular label (instead of a list label) is added to the issue" do
    it "returns nil" do
      5.times do
        regular_label = create(:label)
        issue = create(:issue, project: project)
        issue.update(label_ids: [regular_label.id])

        create_merge_request_closing_issue(issue)
        merge_merge_requests_closing_issue(issue)
        deploy_master
      end

      expect(subject.issue).to be_nil
    end
  end
end
