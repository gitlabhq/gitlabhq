require 'spec_helper'

describe IssueLinks::DestroyService, service: true do
  describe '#execute' do
    let(:user) { create :user }
    let!(:issue_link) { create :issue_link }

    subject { described_class.new(issue_link, user).execute }

    it 'removes related issue' do
      expect { subject }.to change(IssueLink, :count).from(1).to(0)
    end

    it 'creates notes' do
      # Two-way notes creation
      expect(SystemNoteService).to receive(:unrelate_issue)
        .with(issue_link.source, issue_link.target, user)
      expect(SystemNoteService).to receive(:unrelate_issue)
        .with(issue_link.target, issue_link.source, user)

      subject
    end

    it 'returns success message' do
      is_expected.to eq(message: 'Relation was removed', status: :success)
    end
  end
end
