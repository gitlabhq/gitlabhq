# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Partitioning::Time::BaseStrategy, feature_category: :database do
  let(:model) { class_double(ApplicationRecord, table_name: table_name) }
  let(:partitioning_key) { :created_at }
  let(:table_name) { :_test_partitioned_test }
  let(:base_strategy) { described_class.new(model, partitioning_key, retain_for: :ever) }

  describe '#initialize' do
    subject(:strategy) { described_class.new(model, partitioning_key, retain_for: retain_for) }

    context 'when retain_for is a duration' do
      let(:retain_for) { 3.months }

      it 'stores the retention duration' do
        expect(strategy.retain_for).to eq(3.months)
      end
    end

    context 'when retain_for is :ever' do
      let(:retain_for) { :ever }

      it 'normalizes :ever to no retention limit' do
        expect(strategy.retain_for).to be_nil
      end
    end

    context 'when retain_for is nil' do
      let(:retain_for) { nil }

      it 'raises an ArgumentError' do
        expect { strategy }.to raise_error(ArgumentError, /retain_for must be an ActiveSupport::Duration.*got: nil/m)
      end
    end

    context 'when retain_for is an unsupported value' do
      let(:retain_for) { 5 }

      it 'raises an ArgumentError' do
        expect { strategy }.to raise_error(ArgumentError, /retain_for must be an ActiveSupport::Duration.*got: 5/m)
      end
    end
  end

  describe '#retain_detached_partitions_for' do
    subject(:strategy) do
      described_class.new(model, partitioning_key, retain_for: :ever,
        retain_detached_partitions_for: retain_detached_partitions_for)
    end

    context 'when not given' do
      let(:retain_detached_partitions_for) { nil }

      it 'defaults to nil so the partition manager falls back to its global default' do
        expect(strategy.retain_detached_partitions_for).to be_nil
      end
    end

    context 'when given a duration' do
      let(:retain_detached_partitions_for) { 2.days }

      it 'stores the duration' do
        expect(strategy.retain_detached_partitions_for).to eq(2.days)
      end
    end

    context 'when given an unsupported value' do
      let(:retain_detached_partitions_for) { 5 }

      it 'raises an ArgumentError' do
        expect { strategy }.to raise_error(
          ArgumentError, /retain_detached_partitions_for must be an ActiveSupport::Duration.*got: 5/m
        )
      end
    end
  end

  describe '#current_partitions' do
    subject(:current_partitions) { base_strategy.current_partitions }

    it 'raises an error' do
      expect { current_partitions }.to raise_error(NotImplementedError)
    end
  end

  describe '#missing_partitions' do
    subject(:missing_partitions) { base_strategy.missing_partitions }

    it 'raises an error' do
      expect { missing_partitions }.to raise_error(NotImplementedError)
    end
  end

  describe '#extra_partitions' do
    subject(:extra_partitions) { base_strategy.extra_partitions }

    it 'raises an error' do
      expect { extra_partitions }.to raise_error(NotImplementedError)
    end
  end

  describe '#desired_partitions' do
    subject(:desired_partitions) { base_strategy.desired_partitions }

    it 'raises an error' do
      expect { desired_partitions }.to raise_error(NotImplementedError)
    end
  end

  describe '#relevant_range' do
    subject(:relevant_range) { base_strategy.relevant_range }

    it 'raises an error' do
      expect { relevant_range }.to raise_error(NotImplementedError)
    end
  end

  describe '#oldest_active_date' do
    subject(:oldest_active_date) { base_strategy.oldest_active_date }

    it 'raises an error' do
      expect { oldest_active_date }.to raise_error(NotImplementedError)
    end
  end

  describe '#partition_name' do
    let(:from) { Date.current }

    subject(:partition_name) { base_strategy.partition_name(from) }

    it 'raises an error' do
      expect { partition_name }.to raise_error(NotImplementedError)
    end
  end

  describe '#after_adding_partitions' do
    subject(:after_adding_partitions) { base_strategy.after_adding_partitions }

    it 'does nothing' do
      expect { after_adding_partitions }.not_to raise_error
    end
  end

  describe '#validate_and_fix' do
    subject(:validate_and_fix) { base_strategy.validate_and_fix }

    it 'does nothing' do
      expect { validate_and_fix }.not_to raise_error
    end
  end
end
