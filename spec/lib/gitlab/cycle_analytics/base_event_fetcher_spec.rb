require 'spec_helper'

describe Gitlab::CycleAnalytics::BaseEventFetcher do
  let(:max_events) { 2 }
  let(:project) { create(:project, :repository) }
  let(:user) { create(:user, :admin) }
  let(:start_time_attrs) { Issue.arel_table[:created_at] }
  let(:end_time_attrs) { [Issue::Metrics.arel_table[:first_associated_with_milestone_at]] }
  let(:options) do
    { start_time_attrs: start_time_attrs,
      end_time_attrs: end_time_attrs,
      from: 30.days.ago,
      project: project }
  end

  subject do
    described_class.new(stage: :issue,
                        options: options).fetch
  end

  before do
    allow_any_instance_of(Gitlab::ReferenceExtractor).to receive(:issues).and_return(Issue.all)
    allow_any_instance_of(described_class).to receive(:serialize) do |event|
      event
    end
    allow_any_instance_of(described_class)
      .to receive(:allowed_ids).and_return(nil)

    stub_const('Gitlab::CycleAnalytics::BaseEventFetcher::MAX_EVENTS', max_events)

    setup_events(count: 3)
  end

  it 'limits the rows to the max number' do
    expect(subject.count).to eq(max_events)
  end

  def setup_events(count:)
    count.times do
      issue = create(:issue, project: project, created_at: 2.days.ago)
      milestone = create(:milestone, project: project)

      issue.update(milestone: milestone)
      create_merge_request_closing_issue(user, project, issue)
    end
  end
end
