# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UsageDataNonSqlMetrics do
  let(:default_count) { Gitlab::UsageDataNonSqlMetrics::SQL_METRIC_DEFAULT }

  describe '.count' do
    it 'returns default value for count' do
      expect(described_class.count(User)).to eq(default_count)
    end
  end

  describe '.distinct_count' do
    it 'returns default value for distinct count' do
      expect(described_class.distinct_count(User)).to eq(default_count)
    end
  end

  describe '.estimate_batch_distinct_count' do
    it 'returns default value for estimate_batch_distinct_count' do
      expect(described_class.estimate_batch_distinct_count(User)).to eq(default_count)
    end
  end

  describe '.sum' do
    it 'returns default value for sum' do
      expect(described_class.sum(JiraImportState.finished, :imported_issues_count)).to eq(default_count)
    end
  end

  describe '.histogram' do
    it 'returns default value for histogram' do
      expect(described_class.histogram(JiraImportState.finished, :imported_issues_count, buckets: [], bucket_size: 0)).to eq(default_count)
    end
  end

  describe 'min/max methods' do
    using RSpec::Parameterized::TableSyntax

    where(:model, :result) do
      User       | nil
      Issue      | nil
      Deployment | nil
      Project    | nil
    end

    with_them do
      it 'returns nil' do
        expect(described_class.minimum_id(model)).to eq(result)
        expect(described_class.maximum_id(model)).to eq(result)
      end
    end
  end
end
