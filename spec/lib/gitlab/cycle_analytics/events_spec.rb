require 'spec_helper'

describe Gitlab::CycleAnalytics::Events do
  let(:project) { create(:project) }
  let(:from_date) { 10.days.ago }
  let(:user) { create(:user, :admin) }

  subject { described_class.new(project: project, from: from_date) }

  before do
    setup(context)
  end

  describe '#issue' do
    let!(:context) { create(:issue, project: project, created_at: 2.days.ago) }

    it 'has an issue diff' do
      expect(subject.issue_events.first['issue_diff']).to eq('2 days ago')
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

  def setup(context)
    milestone = create(:milestone, project: project)
    context.update(milestone: milestone)
    create_merge_request_closing_issue(context)
  end
end
