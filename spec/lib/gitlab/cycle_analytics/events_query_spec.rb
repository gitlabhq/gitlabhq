require 'spec_helper'

describe Gitlab::CycleAnalytics::EventsQuery do
  let(:max_events) { 3 }
  let(:project) { create(:project) }
  let(:user) { create(:user, :admin) }
  let(:options) { { from: 30.days.ago } }

  let(:issue_event) do
    Gitlab::CycleAnalytics::IssueEvent.new(project: project, options: options)
  end

  subject { described_class.new(project: project, options: options).execute(issue_event) }

  before do
    allow_any_instance_of(Gitlab::ReferenceExtractor).to receive(:issues).and_return(Issue.all)
    stub_const('Gitlab::CycleAnalytics::EventsQuery::MAX_EVENTS', max_events)

    setup_events(count: 5)
  end

  it 'limits the rows the max number' do
    expect(subject.count).to eq(max_events)
  end

  def setup_events(count:)
    count.times do
      issue = create(:issue, project: project, created_at: 2.days.ago)
      milestone = create(:milestone, project: project)

      issue.update(milestone: milestone)
      create_merge_request_closing_issue(issue)
    end
  end
end
