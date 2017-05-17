require 'spec_helper'

describe RelatedIssue do
  describe 'Associations' do
    it { is_expected.to belong_to(:issue) }
    it { is_expected.to belong_to(:related_issue).class_name('Issue') }
  end

  describe 'Validation' do
    subject { create :related_issue }

    it { is_expected.to validate_presence_of(:issue) }
    it { is_expected.to validate_presence_of(:related_issue) }
    it do
      is_expected.to validate_uniqueness_of(:issue)
        .scoped_to(:related_issue_id)
        .with_message(/already related/)
    end

    context 'self relation' do
      it 'invalidates object' do
        issue = create :issue
        related_issue = build :related_issue, issue: issue, related_issue: issue

        expect(related_issue).to be_invalid
        expect(related_issue.errors[:issue]).to include("cannot be related to itself")
      end
    end
  end
end
