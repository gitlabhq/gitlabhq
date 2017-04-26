require 'spec_helper'

describe RelatedIssues::DestroyService, service: true do
  describe '#execute' do
    let(:user) { create :user }
    let!(:related_issue) { create :related_issue }

    subject { described_class.new(related_issue, user).execute }

    it 'remove related issue' do
      expect { subject }.to change(RelatedIssue, :count).from(1).to(0)
    end

    it 'create notes' do
      # Two-way notes creation
      expect(SystemNoteService).to receive(:unrelate_issue)
        .with(related_issue.issue, related_issue.related_issue, user)
      expect(SystemNoteService).to receive(:unrelate_issue)
        .with(related_issue.related_issue, related_issue.issue, user)

      subject
    end

    it 'returns success message' do
      is_expected.to eq(message: 'Relation was removed', status: :success)
    end
  end
end
