require 'spec_helper'

describe Gitlab::CycleAnalytics::Events do
  let(:project) { create(:project) }
  let(:from_date) { 10.days.ago }
  let(:user) { create(:user, :admin) }

  subject { described_class.new(project: project, from: from_date) }

  before do
    setup(context)
  end

  describe '#issue_events' do
    let!(:context) { create(:issue, project: project, created_at: 2.days.ago) }

    it 'has the total time' do
      expect(subject.issue_events.first['total_time']).to eq('2 days')
    end

    it 'has a title' do
      expect(subject.issue_events.first['title']).to eq(context.title)
    end

    it 'has an iid' do
      expect(subject.issue_events.first['iid']).to eq(context.iid.to_s)
    end

    it 'has a created_at timestamp' do
      expect(subject.issue_events.first['created_at']).to end_with('ago')
    end

    it "has the author's name" do
      expect(subject.issue_events.first['name']).to eq(context.author.name)
    end
  end

  describe '#plan_events' do
    let!(:context) { create(:issue, project: project, created_at: 2.days.ago) }

    it 'has the first referenced commit' do
      expect(subject.plan_events.first['commit'].message).to eq('commit message')
    end

    it 'has the total time' do
      expect(subject.plan_events.first['total_time']).to eq('2 days')
    end
  end

  def setup(context)
    milestone = create(:milestone, project: project)
    context.update(milestone: milestone)
    create_merge_request_closing_issue(context)
  end
end
