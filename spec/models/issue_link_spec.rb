require 'spec_helper'

describe IssueLink do
  describe 'Associations' do
    it { is_expected.to belong_to(:source).class_name('Issue') }
    it { is_expected.to belong_to(:target).class_name('Issue') }
  end

  describe 'Validation' do
    subject { create :issue_link }

    it { is_expected.to validate_presence_of(:source) }
    it { is_expected.to validate_presence_of(:target) }
    it do
      is_expected.to validate_uniqueness_of(:source)
        .scoped_to(:target_id)
        .with_message(/already related/)
    end

    context 'self relation' do
      let(:issue) { create :issue }

      context 'cannot be validated' do
        it 'does not invalidate object with self relation error' do
          issue_link = build :issue_link, source: issue, target: nil

          issue_link.valid?

          expect(issue_link.errors[:source]).to be_empty
        end
      end

      context 'can be invalidated' do
        it 'invalidates object' do
          issue_link = build :issue_link, source: issue, target: issue

          expect(issue_link).to be_invalid
          expect(issue_link.errors[:source]).to include('cannot be related to itself')
        end
      end
    end
  end
end
