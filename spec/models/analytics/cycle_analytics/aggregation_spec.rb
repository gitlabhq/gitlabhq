# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Analytics::CycleAnalytics::Aggregation, type: :model, feature_category: :value_stream_management do
  describe 'associations' do
    it { is_expected.to belong_to(:namespace).required }
  end

  describe 'validations' do
    it { is_expected.not_to validate_presence_of(:namespace) }
    it { is_expected.not_to validate_presence_of(:enabled) }

    %i[incremental_runtimes_in_seconds incremental_processed_records full_runtimes_in_seconds full_processed_records].each do |column|
      it "validates the array length of #{column}" do
        record = described_class.new(column => Array.new(11, 1))

        expect(record).to be_invalid
        expect(record.errors).to have_key(column)
      end
    end

    it_behaves_like 'value stream analytics namespace models' do
      let(:factory_name) { :cycle_analytics_aggregation }
    end
  end

  describe 'attribute updater methods' do
    subject(:aggregation) { build(:cycle_analytics_aggregation) }

    describe '#cursor_for' do
      it 'returns empty cursors' do
        aggregation.last_full_issues_id = nil
        aggregation.last_full_issues_updated_at = nil

        expect(aggregation.cursor_for(:full, Issue)).to eq({})
      end

      context 'when cursor is not empty' do
        it 'returns the cursor values' do
          current_time = Time.current

          aggregation.last_full_issues_id = 1111
          aggregation.last_full_issues_updated_at = current_time

          expect(aggregation.cursor_for(:full, Issue)).to eq({ id: 1111, updated_at: current_time })
        end
      end
    end

    describe '#consistency_check_cursor_for' do
      it 'returns empty cursor' do
        expect(aggregation.consistency_check_cursor_for(Analytics::CycleAnalytics::IssueStageEvent)).to eq({})
        expect(aggregation.consistency_check_cursor_for(Analytics::CycleAnalytics::MergeRequestStageEvent)).to eq({})
      end

      it 'returns the cursor value for IssueStageEvent' do
        aggregation.last_consistency_check_issues_end_event_timestamp = 1.week.ago
        aggregation.last_consistency_check_issues_issuable_id = 42

        expect(aggregation.consistency_check_cursor_for(Analytics::CycleAnalytics::IssueStageEvent)).to eq({
          end_event_timestamp: aggregation.last_consistency_check_issues_end_event_timestamp,
          issue_id: aggregation.last_consistency_check_issues_issuable_id
        })
      end

      it 'returns the cursor value for MergeRequestStageEvent' do
        aggregation.last_consistency_check_merge_requests_end_event_timestamp = 1.week.ago
        aggregation.last_consistency_check_merge_requests_issuable_id = 42

        expect(aggregation.consistency_check_cursor_for(Analytics::CycleAnalytics::MergeRequestStageEvent)).to eq({
          end_event_timestamp: aggregation.last_consistency_check_merge_requests_end_event_timestamp,
          merge_request_id: aggregation.last_consistency_check_merge_requests_issuable_id
        })
      end
    end

    describe '#refresh_last_run' do
      it 'updates the run_at column' do
        freeze_time do
          aggregation.refresh_last_run(:incremental)

          expect(aggregation.last_incremental_run_at).to eq(Time.current)
        end
      end
    end

    describe '#complete' do
      it 'resets all full run cursors to nil' do
        aggregation.last_full_issues_id = 111
        aggregation.last_full_issues_updated_at = Time.current
        aggregation.last_full_merge_requests_id = 111
        aggregation.last_full_merge_requests_updated_at = Time.current

        aggregation.complete

        expect(aggregation).to have_attributes(
          last_full_issues_id: nil,
          last_full_issues_updated_at: nil,
          last_full_merge_requests_id: nil,
          last_full_merge_requests_updated_at: nil
        )
      end
    end

    describe '#set_cursor' do
      it 'sets the cursor values for the given mode' do
        aggregation.set_cursor(:full, Issue, { id: 2222, updated_at: nil })

        expect(aggregation).to have_attributes(
          last_full_issues_id: 2222,
          last_full_issues_updated_at: nil
        )
      end
    end

    describe '#set_stats' do
      it 'appends stats to the runtime and processed_records attributes' do
        aggregation.set_stats(:full, 10, 20)
        aggregation.set_stats(:full, 20, 30)

        expect(aggregation).to have_attributes(
          full_runtimes_in_seconds: [10, 20],
          full_processed_records: [20, 30]
        )
      end
    end
  end

  describe '#safe_create_for_namespace' do
    context 'when group namespace is provided' do
      let_it_be(:group) { create(:group) }
      let_it_be(:subgroup) { create(:group, parent: group) }

      it 'creates the aggregation record' do
        record = described_class.safe_create_for_namespace(group)

        expect(record).to be_persisted
      end

      context 'when non top-level group is given' do
        it 'creates the aggregation record for the top-level group' do
          record = described_class.safe_create_for_namespace(subgroup)

          expect(record).to be_persisted
        end
      end

      context 'when the record is already present' do
        it 'does nothing' do
          described_class.safe_create_for_namespace(group)

          expect do
            described_class.safe_create_for_namespace(group)
            described_class.safe_create_for_namespace(subgroup)
          end.not_to change { described_class.count }
        end
      end

      context 'when the aggregation was disabled for some reason' do
        it 're-enables the aggregation' do
          create(:cycle_analytics_aggregation, enabled: false, namespace: group)

          aggregation = described_class.safe_create_for_namespace(group)

          expect(aggregation).to be_enabled
        end
      end
    end

    context 'when personal namespace is provided' do
      let_it_be(:user2) { create(:user) }
      let_it_be(:project) { create(:project, :public, namespace: user2.namespace) }

      it 'is successful' do
        aggregation = described_class.safe_create_for_namespace(user2.namespace)

        expect(aggregation).to be_enabled
      end
    end
  end

  describe '#load_batch' do
    let!(:aggregation1) { create(:cycle_analytics_aggregation, last_incremental_run_at: nil, last_consistency_check_updated_at: 3.days.ago).reload }
    let!(:aggregation2) { create(:cycle_analytics_aggregation, last_incremental_run_at: 5.days.ago).reload }
    let!(:aggregation3) { create(:cycle_analytics_aggregation, last_incremental_run_at: nil, last_consistency_check_updated_at: 2.days.ago).reload }
    let!(:aggregation4) { create(:cycle_analytics_aggregation, last_incremental_run_at: 10.days.ago).reload }

    before do
      create(:cycle_analytics_aggregation, :disabled) # disabled rows are skipped
      create(:cycle_analytics_aggregation, last_incremental_run_at: 1.day.ago, last_consistency_check_updated_at: 1.hour.ago) # "early" rows are filtered out
    end

    it 'loads records in priority order' do
      batch = described_class.load_batch(2.days.ago).to_a

      expect(batch.size).to eq(4)
      first_two = batch.first(2)
      last_two = batch.last(2)

      # Using match_array because the order can be undeterministic for nil values.
      expect(first_two).to match_array([aggregation1, aggregation3])
      expect(last_two).to eq([aggregation4, aggregation2])
    end

    context 'when loading batch for last_consistency_check_updated_at' do
      it 'loads records in priority order' do
        batch = described_class.load_batch(1.day.ago, :last_consistency_check_updated_at).to_a

        expect(batch.size).to eq(4)
        first_two = batch.first(2)
        last_two = batch.last(2)

        expect(first_two).to match_array([aggregation2, aggregation4])
        expect(last_two).to eq([aggregation1, aggregation3])
      end
    end
  end

  describe '#estimated_next_run_at' do
    around do |example|
      travel_to(Time.utc(2019, 3, 17, 13, 3)) { example.run }
    end

    # aggregation runs on every 10 minutes
    let(:minutes_until_next_aggregation) { 7.minutes }

    context 'when aggregation was not yet executed for the given group' do
      let(:aggregation) { create(:cycle_analytics_aggregation, last_incremental_run_at: nil) }

      it { expect(aggregation.estimated_next_run_at).to eq(nil) }
    end

    context 'when aggregation was already run' do
      let!(:other_aggregation1) { create(:cycle_analytics_aggregation, last_incremental_run_at: 10.minutes.ago) }
      let!(:other_aggregation2) { create(:cycle_analytics_aggregation, last_incremental_run_at: 15.minutes.ago) }
      let!(:aggregation) { create(:cycle_analytics_aggregation, last_incremental_run_at: 5.minutes.ago) }

      it 'returns the duration between the previous run timestamp and the earliest last_incremental_run_at' do
        expect(aggregation.estimated_next_run_at).to eq((10.minutes + minutes_until_next_aggregation).from_now)
      end

      context 'when the aggregation has persisted previous runtimes' do
        before do
          aggregation.update!(incremental_runtimes_in_seconds: [30, 60, 90])
        end

        it 'adds the runtime to the estimation' do
          expect(aggregation.estimated_next_run_at).to eq((10.minutes.seconds + 60.seconds + minutes_until_next_aggregation).from_now)
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

      it 'returns the minutes until the next aggregation' do
        expect(aggregation.estimated_next_run_at).to eq(minutes_until_next_aggregation.from_now)
      end
    end
  end
end
