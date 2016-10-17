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
    let!(:context) { create(:issue, project: project) }

    it 'has an issue diff' do
      expect(subject.issue_events['issue_diff']).to eq("-00:00:00.339259")
    end

    it 'has a title' do
      expect(subject.issue_events['title']).to eq(context.title)
    end

    it 'has an iid' do
      expect(subject.issue_events['iid']).to eq(context.iid)
    end

    it 'has a created_at timestamp' do
      expect(subject.issue_events['created_at']).to eq(context.created_at)
    end

    it "has the author's name" do
      expect(subject.issue_events['name']).to eq(context.author.name)
    end
  end

  def setup(context)
    milestone = create(:milestone, project: project)
    context.update(milestone: milestone)
    create_merge_request_closing_issue(context)
  end
end
