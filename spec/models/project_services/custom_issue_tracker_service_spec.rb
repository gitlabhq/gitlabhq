require 'spec_helper'

describe CustomIssueTrackerService do
  describe 'Associations' do
    it { is_expected.to belong_to :project }
    it { is_expected.to have_one :service_hook }
  end

  describe 'Validations' do
    context 'when service is active' do
      before do
        subject.active = true
      end

      it { is_expected.to validate_presence_of(:project_url) }
      it { is_expected.to validate_presence_of(:issues_url) }
      it { is_expected.to validate_presence_of(:new_issue_url) }
      it_behaves_like 'issue tracker service URL attribute', :project_url
      it_behaves_like 'issue tracker service URL attribute', :issues_url
      it_behaves_like 'issue tracker service URL attribute', :new_issue_url
    end

    context 'when service is inactive' do
      before do
        subject.active = false
      end

      it { is_expected.not_to validate_presence_of(:project_url) }
      it { is_expected.not_to validate_presence_of(:issues_url) }
      it { is_expected.not_to validate_presence_of(:new_issue_url) }
    end

    context 'title' do
      let(:issue_tracker) { described_class.new(properties: {}) }

      it 'sets a default title' do
        issue_tracker.title = nil

        expect(issue_tracker.title).to eq('Custom Issue Tracker')
      end

      it 'sets the custom title' do
        issue_tracker.title = 'test title'

        expect(issue_tracker.title).to eq('test title')
      end
    end
  end
end
