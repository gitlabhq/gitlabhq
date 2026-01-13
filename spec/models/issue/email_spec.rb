# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issue::Email, feature_category: :team_planning do
  describe 'Associations' do
    it { is_expected.to belong_to(:issue) }
  end

  describe 'Validations' do
    subject { build(:issue_email) }

    it { is_expected.to validate_presence_of(:issue) }
    it { is_expected.to validate_uniqueness_of(:issue) }
    it { is_expected.to validate_uniqueness_of(:email_message_id) }
    it { is_expected.to validate_length_of(:email_message_id).is_at_most(1000) }
    it { is_expected.to validate_presence_of(:email_message_id) }
  end

  describe '#work_item' do
    let(:work_item) { nil }
    let(:issue_email) { build(:issue_email, issue_id: work_item&.id) }

    it 'is nil' do
      expect(issue_email.work_item).to be_nil
    end

    context 'when issue_id references an issue work item' do
      let(:work_item) { create(:work_item) }

      it 'returns the associated work item' do
        expect(issue_email.work_item).to eq(work_item)
        expect(issue_email.work_item).to be_a(WorkItem)
      end
    end

    context 'when issue_id references a ticket work item' do
      let(:work_item) { create(:work_item, :ticket) }

      it 'returns the associated work item' do
        expect(issue_email.work_item).to eq(work_item)
        expect(issue_email.work_item).to be_a(WorkItem)
      end
    end
  end
end
