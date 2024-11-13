# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Partitioning::Time::BaseStrategy, feature_category: :database do
  let(:model) { class_double(ApplicationRecord, table_name: table_name) }
  let(:partitioning_key) { :created_at }
  let(:table_name) { :_test_partitioned_test }
  let(:base_strategy) { described_class.new(model, partitioning_key) }

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
