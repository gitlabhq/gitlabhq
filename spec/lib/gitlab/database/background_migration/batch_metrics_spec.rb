# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::BackgroundMigration::BatchMetrics do
  let(:batch_metrics) { described_class.new }

  describe '#time_operation' do
    it 'tracks the duration of the operation using monotonic time' do
      expect(batch_metrics.timings).to be_empty

      expect(Gitlab::Metrics::System).to receive(:monotonic_time)
        .and_return(0.0, 111.0, 200.0, 290.0, 300.0, 410.0)

      batch_metrics.time_operation(:my_label) do
        # some operation
      end

      batch_metrics.time_operation(:my_other_label) do
        # some operation
      end

      batch_metrics.time_operation(:my_label) do
        # some operation
      end

      expect(batch_metrics.timings).to eq(my_label: [111.0, 110.0], my_other_label: [90.0])
    end
  end

  describe '#instrument_operation' do
    it 'tracks duration and affected rows' do
      expect(batch_metrics.timings).to be_empty
      expect(batch_metrics.affected_rows).to be_empty

      expect(Gitlab::Metrics::System).to receive(:monotonic_time)
        .and_return(0.0, 111.0, 200.0, 290.0, 300.0, 410.0, 420.0, 450.0)

      batch_metrics.instrument_operation(:my_label) do
        3
      end

      batch_metrics.instrument_operation(:my_other_label) do
        42
      end

      batch_metrics.instrument_operation(:my_label) do
        2
      end

      batch_metrics.instrument_operation(:my_other_label) do
        :not_an_integer
      end

      expect(batch_metrics.timings).to eq(my_label: [111.0, 110.0], my_other_label: [90.0, 30.0])
      expect(batch_metrics.affected_rows).to eq(my_label: [3, 2], my_other_label: [42])
    end
  end
end
