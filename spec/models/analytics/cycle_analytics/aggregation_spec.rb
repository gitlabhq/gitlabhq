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
      record = described_class.safe_create_for_group(group)

      expect(record).to be_persisted
    end

    context 'when non top-level group is given' do
      it 'creates the aggregation record for the top-level group' do
        record = described_class.safe_create_for_group(subgroup)

        expect(record).to be_persisted
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

  describe '#load_batch' do
    let!(:aggregation1) { create(:cycle_analytics_aggregation, last_incremental_run_at: nil) }
    let!(:aggregation2) { create(:cycle_analytics_aggregation, last_incremental_run_at: 5.days.ago).reload }
    let!(:aggregation3) { create(:cycle_analytics_aggregation, last_incremental_run_at: nil) }
    let!(:aggregation5) { create(:cycle_analytics_aggregation, last_incremental_run_at: 10.days.ago).reload }

    before do
      create(:cycle_analytics_aggregation, :disabled) # disabled rows are skipped
      create(:cycle_analytics_aggregation, last_incremental_run_at: 1.day.ago) # "early" rows are filtered out
    end

    it 'loads records in priority order' do
      batch = described_class.load_batch(2.days.ago).to_a

      expect(batch.size).to eq(4)
      first_two = batch.first(2)
      last_two = batch.last(2)

      # Using match_array because the order can be undeterministic for nil values.
      expect(first_two).to match_array([aggregation1, aggregation3])
      expect(last_two).to eq([aggregation5, aggregation2])
    end
  end

  describe '#estimated_next_run_at' do
    around do |example|
      freeze_time { example.run }
    end

    context 'when aggregation was not yet executed for the given group' do
      let(:aggregation) { create(:cycle_analytics_aggregation, last_incremental_run_at: nil) }

      it { expect(aggregation.estimated_next_run_at).to eq(nil) }
    end

    context 'when aggregation was already run' do
      let!(:other_aggregation1) { create(:cycle_analytics_aggregation, last_incremental_run_at: 10.minutes.ago) }
      let!(:other_aggregation2) { create(:cycle_analytics_aggregation, last_incremental_run_at: 15.minutes.ago) }
      let!(:aggregation) { create(:cycle_analytics_aggregation, last_incremental_run_at: 5.minutes.ago) }

      it 'returns the duration between the previous run timestamp and the earliest last_incremental_run_at' do
        expect(aggregation.estimated_next_run_at).to eq(10.minutes.from_now)
      end

      context 'when the aggregation has persisted previous runtimes' do
        before do
          aggregation.update!(incremental_runtimes_in_seconds: [30, 60, 90])
        end

        it 'adds the runtime to the estimation' do
          expect(aggregation.estimated_next_run_at).to eq((10.minutes.seconds + 60.seconds).from_now)
        end
      end
    end

    context 'when no records are present in the DB' do
      it 'returns nil' do
        expect(described_class.new.estimated_next_run_at).to eq(nil)
      end
    end

    context 'when only one aggregation record present' do
      let!(:aggregation) { create(:cycle_analytics_aggregation, last_incremental_run_at: 5.minutes.ago) }

      it 'returns nil' do
        expect(aggregation.estimated_next_run_at).to eq(nil)
      end
    end

    context 'when the aggregation is disabled' do
      it 'returns nil' do
        expect(described_class.new(enabled: false).estimated_next_run_at).to eq(nil)
      end
    end
  end
end
