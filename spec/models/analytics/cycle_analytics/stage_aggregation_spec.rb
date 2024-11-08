# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::CycleAnalytics::StageAggregation, type: :model, feature_category: :value_stream_management do
  describe 'associations' do
    it { is_expected.to belong_to(:namespace).required }
    it { is_expected.to belong_to(:stage).required }
  end

  describe 'validations' do
    it { is_expected.not_to validate_presence_of(:namespace) }
    it { is_expected.not_to validate_presence_of(:stage) }
    it { is_expected.not_to validate_presence_of(:enabled) }

    %i[runtimes_in_seconds processed_records].each do |column|
      it "validates the array length of #{column}" do
        record = described_class.new(column => Array.new(11, 1))

        expect(record).to be_invalid
        expect(record.errors).to have_key(column)
      end
    end

    it_behaves_like 'value stream analytics namespace models' do
      let(:factory_name) { :cycle_analytics_stage_aggregation }
    end
  end

  describe 'attribute updater methods' do
    subject(:aggregation) { build(:cycle_analytics_stage_aggregation) }

    shared_examples 'has cursor fields' do |model|
      describe "#cursor_for #{model.table_name}" do
        it 'returns empty cursors' do
          aggregation["last_#{model.table_name}_id"] = nil
          aggregation["last_#{model.table_name}_updated_at"] = nil
          expect(aggregation.cursor_for(model)).to eq({})
        end

        context 'when cursor is not empty' do
          it 'returns the cursor values' do
            current_time = Time.current

            aggregation["last_#{model.table_name}_id"] = 12345
            aggregation["last_#{model.table_name}_updated_at"] = current_time
            expect(aggregation.cursor_for(model)).to eq({ id: 12345, updated_at: current_time })
          end
        end
      end

      describe '#set_cursor' do
        it "sets the cursor values for #{model.table_name}" do
          aggregation.set_cursor(model, { id: 2222, updated_at: nil })

          expect(aggregation).to have_attributes(
            "last_#{model.table_name}_id": 2222,
            "last_#{model.table_name}_updated_at": nil
          )
        end
      end
    end

    it_behaves_like 'has cursor fields', Issue
    it_behaves_like 'has cursor fields', MergeRequest

    describe '#refresh_last_run', :freeze_time do
      it 'updates last_run_at column' do
        expect { aggregation.refresh_last_run }.to change { aggregation.last_run_at }.to(Time.current)
      end
    end

    describe '#complete', :freeze_time do
      it 'updates last_completed_at column' do
        expect { aggregation.complete }.to change { aggregation.last_completed_at }.to(Time.current)
      end
    end

    describe '#set_stats' do
      it 'appends stats to the runtime and processed_records attributes' do
        aggregation.set_stats(10, 20)
        aggregation.set_stats(20, 30)

        expect(aggregation).to have_attributes(
          runtimes_in_seconds: [10, 20],
          processed_records: [20, 30]
        )
      end
    end
  end

  describe '.load_batch' do
    let_it_be(:namespace) { create(:group) }
    let_it_be(:new_aggregation) { create(:cycle_analytics_stage_aggregation, namespace: namespace) }
    let_it_be(:aggregation_with_run) do
      create(:cycle_analytics_stage_aggregation, namespace: namespace, last_run_at: 1.day.ago)
    end

    let_it_be(:aggregation_with_old_run) do
      create(:cycle_analytics_stage_aggregation, namespace: namespace, last_run_at: 10.days.ago)
    end

    let_it_be(:disabled_aggregation) { create(:cycle_analytics_stage_aggregation, :disabled, namespace: namespace) }
    let_it_be(:completed_aggregation) { create(:cycle_analytics_stage_aggregation, :completed, namespace: namespace) }

    it 'returns incomplete enabled aggregations sorted by last run' do
      expect(described_class.load_batch.to_a).to eq([new_aggregation, aggregation_with_old_run, aggregation_with_run])
    end

    it 'respects limit param' do
      expect(described_class.load_batch(2).to_a).to eq([new_aggregation, aggregation_with_old_run])
    end
  end
end
