# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::PostgresTableSize, type: :model, feature_category: :database do
  include Database::DatabaseHelpers

  let(:connection) { ApplicationRecord.connection }

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
    let!(:small_table) { create(:postgres_table_size, size_in_bytes: 5.gigabytes) }
    let!(:medium_table) { create(:postgres_table_size, size_in_bytes: 30.gigabytes) }
    let!(:large_table) { create(:postgres_table_size, size_in_bytes: 70.gigabytes) }
    let!(:over_limit_table) { create(:postgres_table_size, size_in_bytes: 120.gigabytes) }

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
  end
end
