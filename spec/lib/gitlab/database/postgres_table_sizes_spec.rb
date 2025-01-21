# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::PostgresTableSize, type: :model, feature_category: :database do
  include Database::DatabaseHelpers

  let(:connection) { ApplicationRecord.connection }
  let(:small_table) { create(:postgres_table_size, table_name: 'small', size_in_bytes: 5.gigabytes) }
  let(:medium_table) { create(:postgres_table_size, table_name: 'medium', size_in_bytes: 30.gigabytes) }
  let(:large_table) { create(:postgres_table_size, table_name: 'large', size_in_bytes: 70.gigabytes) }
  let(:over_limit_table) { create(:postgres_table_size, table_name: 'over_limit', size_in_bytes: 120.gigabytes) }

  before do
    swapout_view_for_table(:postgres_table_sizes, connection: connection)
  end

  describe 'constants' do
    it 'defines size thresholds' do
      expect(described_class::SMALL).to eq(10.gigabytes)
      expect(described_class::MEDIUM).to eq(50.gigabytes)
      expect(described_class::LARGE).to eq(100.gigabytes)
    end
  end

  describe 'table configuration' do
    it 'uses correct table name' do
      expect(described_class.table_name).to eq('postgres_table_sizes')
    end

    it 'uses identifier as primary key' do
      expect(described_class.primary_key).to eq('identifier')
    end
  end

  describe 'scopes' do
    describe '.small' do
      it 'returns tables smaller than SMALL threshold' do
        expect(described_class.small).to include(small_table)
        expect(described_class.small).not_to include(medium_table, large_table, over_limit_table)
      end
    end

    describe '.medium' do
      it 'returns tables between SMALL AND MEDIUM thresholds' do
        expect(described_class.medium).to include(medium_table)
        expect(described_class.medium).not_to include(small_table, large_table, over_limit_table)
      end
    end

    describe '.large' do
      it 'returns tables between MEDIUM and LARGE thresholds' do
        expect(described_class.large).to include(large_table)
        expect(described_class.large).not_to include(small_table, medium_table, over_limit_table)
      end
    end

    describe '.over_limit' do
      it 'returns tables greater than LARGE threshold' do
        expect(described_class.over_limit).to include(over_limit_table)
        expect(described_class.over_limit).not_to include(small_table, medium_table, large_table)
      end
    end

    describe '.alerting' do
      it 'returns tables greater than or equal to ALERT threshold' do
        expect(described_class.alerting).to include(medium_table, large_table, over_limit_table)
        expect(described_class.alerting).not_to include(small_table)
      end
    end

    describe '.by_table_name' do
      let(:table_name) { small_table.table_name }

      it 'returns the table' do
        expect(described_class.by_table_name(table_name)).to eq(small_table)
      end
    end
  end

  describe '#size_classification' do
    context 'with table < 10 GB' do
      it 'returns small' do
        expect(small_table.size_classification).to eq('small')
      end
    end

    context 'with table > 10 GB && < 50 GB' do
      it 'returns medium' do
        expect(medium_table.size_classification).to eq('medium')
      end
    end

    context 'with table > 50 GB && < 100 GB' do
      it 'returns large' do
        expect(large_table.size_classification).to eq('large')
      end
    end

    context 'with table > 100 GB' do
      it 'returns over_limit' do
        expect(over_limit_table.size_classification).to eq('over_limit')
      end
    end
  end

  describe '#alert_report_hash' do
    it 'returns a hash of the record' do
      expect(small_table.alert_report_hash).to eq(
        {
          identifier: small_table.identifier,
          schema_name: small_table.schema_name,
          table_name: small_table.table_name,
          total_size: small_table.total_size,
          table_size: small_table.table_size,
          index_size: small_table.index_size,
          size_in_bytes: small_table.size_in_bytes,
          classification: small_table.size_classification
        }
      )
    end
  end
end
