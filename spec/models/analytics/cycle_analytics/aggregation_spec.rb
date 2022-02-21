# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Analytics::CycleAnalytics::Aggregation, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:group).required }
  end

  describe 'validations' do
    it { is_expected.not_to validate_presence_of(:group) }
    it { is_expected.not_to validate_presence_of(:enabled) }

    %i[incremental_runtimes_in_seconds incremental_processed_records last_full_run_runtimes_in_seconds last_full_run_processed_records].each do |column|
      it "validates the array length of #{column}" do
        record = described_class.new(column => [1] * 11)

        expect(record).to be_invalid
        expect(record.errors).to have_key(column)
      end
    end
  end

  describe '#safe_create_for_group' do
    let_it_be(:group) { create(:group) }
    let_it_be(:subgroup) { create(:group, parent: group) }

    it 'creates the aggregation record' do
      described_class.safe_create_for_group(group)

      record = described_class.find_by(group_id: group)
      expect(record).to be_present
    end

    context 'when non top-level group is given' do
      it 'creates the aggregation record for the top-level group' do
        described_class.safe_create_for_group(subgroup)

        record = described_class.find_by(group_id: group)
        expect(record).to be_present
      end
    end

    context 'when the record is already present' do
      it 'does nothing' do
        described_class.safe_create_for_group(group)

        expect do
          described_class.safe_create_for_group(group)
          described_class.safe_create_for_group(subgroup)
        end.not_to change { described_class.count }
      end
    end
  end
end
