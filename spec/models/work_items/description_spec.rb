# frozen_string_literal: true

require "spec_helper"

RSpec.describe WorkItems::Description, feature_category: :team_planning do
  describe 'associations' do
    it { is_expected.to belong_to(:work_item) }
    it { is_expected.to belong_to(:namespace) }

    it { is_expected.to belong_to(:root_namespace).class_name('Namespace') }
    it { is_expected.to belong_to(:last_editing_user).class_name('User') }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:namespace) }
    it { is_expected.to validate_presence_of(:root_namespace) }
    it { is_expected.to validate_presence_of(:work_item) }

    it 'ensures to use work_item namespace' do
      work_item = create(:work_item)
      description = described_class.new(work_item: work_item)

      expect(description).to be_valid
      expect(description.namespace).to eq(work_item.namespace)
    end

    context 'for description length' do
      let(:description_record) { build(:work_item_description, description: description) }

      context 'when the description is under DESCRIPTION_LENGTH_MAX' do
        let(:description) { 'This is a sample work item description' }

        it 'is valid' do
          description_record.validate(:create)

          expect(description_record).to be_valid
        end
      end

      context 'when the description is over DESCRIPTION_LENGTH_MAX' do
        let(:description) { 'x' * (described_class::DESCRIPTION_LENGTH_MAX + 1) }

        it 'is not valid' do
          description_record.validate(:create)

          expect(description_record).not_to be_valid
          expect(description_record.errors[:description].first).to include("is too long")
        end
      end

      context 'when updating description' do
        let(:description) { 'a' }

        it 'description length is validated' do
          description_record.save!(validate: false)

          update_result = description_record.update(description: 'b' * (described_class::DESCRIPTION_LENGTH_MAX + 1))
          expect(update_result).to be false
          expect(description_record).not_to be_valid
          expect(description_record.errors[:description].first).to include("is too long")
        end
      end

      context 'when updating other attributes than description' do
        let(:description) { 'a' * (described_class::DESCRIPTION_LENGTH_MAX + 1) }

        it 'description length is not validated' do
          description_record.save!(validate: false)

          description_record.validate(:update)

          expect(description_record).to be_valid
        end
      end
    end
  end
end
