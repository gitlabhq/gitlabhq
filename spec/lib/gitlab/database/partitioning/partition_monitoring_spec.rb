# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Partitioning::PartitionMonitoring do
  describe '#report_metrics' do
    subject { described_class.new(models).report_metrics }

    let(:models) { [model] }
    let(:model) { double(partitioning_strategy: partitioning_strategy, table_name: table) }
    let(:partitioning_strategy) { double(missing_partitions: missing_partitions, current_partitions: current_partitions, extra_partitions: extra_partitions) }
    let(:table) { "some_table" }

    let(:missing_partitions) do
      [double]
    end

    let(:current_partitions) do
      [double, double]
    end

    let(:extra_partitions) do
      [double, double, double]
    end

    it 'reports number of present partitions' do
      subject

      expect(Gitlab::Metrics.registry.get(:db_partitions_present).get({ table: table })).to eq(current_partitions.size)
    end

    it 'reports number of missing partitions' do
      subject

      expect(Gitlab::Metrics.registry.get(:db_partitions_missing).get({ table: table })).to eq(missing_partitions.size)
    end

    it 'reports number of extra partitions' do
      subject

      expect(Gitlab::Metrics.registry.get(:db_partitions_extra).get({ table: table })).to eq(extra_partitions.size)
    end
  end
end
