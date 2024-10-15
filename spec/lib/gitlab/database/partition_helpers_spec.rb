# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::PartitionHelpers, feature_category: :database do
  let(:model) { ActiveRecord::Migration.new.extend(described_class) }

  before do
    allow(model).to receive(:puts)
  end

  describe "#partition?" do
    subject(:is_partitioned) { model.partition?(table_name) }

    let(:table_name) { 'ci_builds_metadata' }

    context "when a partition table exist" do
      context 'when the view postgres_partitions exists' do
        it 'calls the view', :aggregate_failures do
          expect(Gitlab::Database::PostgresPartition).to receive(:partition_exists?).with(table_name).and_call_original
          expect(is_partitioned).to be_truthy
        end
      end

      context 'when the view postgres_partitions does not exist' do
        before do
          allow(model).to receive(:view_exists?).and_return(false)
        end

        it 'does not call the view', :aggregate_failures do
          expect(Gitlab::Database::PostgresPartition)
            .to receive(:legacy_partition_exists?).with(table_name).and_call_original

          expect(is_partitioned).to be_truthy
        end
      end
    end

    context "when a partition table does not exist" do
      let(:table_name) { 'partition_does_not_exist' }

      it { is_expected.to be_falsey }
    end
  end

  describe "#table_partitioned?" do
    subject { model.table_partitioned?(table_name) }

    let(:table_name) { 'p_ci_builds_metadata' }

    it { is_expected.to be_truthy }

    context 'with a non-partitioned table' do
      let(:table_name) { 'users' }

      it { is_expected.to be_falsey }
    end
  end
end
