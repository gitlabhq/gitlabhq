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

    xit 'does something' do
      expect(subject.issue_events).to eq([])
    end
  end

  def setup(context)
    create(:milestone, project: project)
    create_merge_request_closing_issue(context)
  end
end
