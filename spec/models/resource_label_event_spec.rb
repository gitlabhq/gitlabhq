require 'rails_helper'

RSpec.describe ResourceLabelEvent, type: :model do
  subject { build(:resource_label_event) }
  let(:issue) { create(:issue) }
  let(:merge_request) { create(:merge_request) }

  describe 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:issue) }
    it { is_expected.to belong_to(:merge_request) }
    it { is_expected.to belong_to(:label) }
  end

  describe 'validations' do
    it { is_expected.to be_valid }
    it { is_expected.to validate_presence_of(:label) }
    it { is_expected.to validate_presence_of(:user) }

    describe 'Issuable validation' do
      it 'is invalid if issue_id and merge_request_id are missing' do
        subject.attributes = { issue: nil, merge_request: nil }

        expect(subject).to be_invalid
      end

      it 'is invalid if issue_id and merge_request_id are set' do
        subject.attributes = { issue: issue, merge_request: merge_request }

        expect(subject).to be_invalid
      end

      it 'is valid if only issue_id is set' do
        subject.attributes = { issue: issue, merge_request: nil }

        expect(subject).to be_valid
      end

      it 'is valid if only merge_request_id is set' do
        subject.attributes = { merge_request: merge_request, issue: nil }

        expect(subject).to be_valid
      end
    end
  end
end
