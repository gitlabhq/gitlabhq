# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe ClickHouse::ReplicatedTableEnginePatcher, feature_category: :database do
  describe '.patch_replicated' do
    it 'properly replaces the table engine' do
      sql = <<~SQL
      CREATE TABLE project_namespace_traversal_paths
      (
          `id` Int64 DEFAULT 0,
          `traversal_path` String DEFAULT '0/',
          `version` DateTime64(6, 'UTC') DEFAULT now(),
          `deleted` Bool DEFAULT false
      )
      ENGINE = ReplacingMergeTree(version, deleted)
      PRIMARY KEY id
      ORDER BY id
      SETTINGS index_granularity = 512;
      SQL

      result = described_class.patch_replicated(sql)

      expectation = <<~SQL
      CREATE TABLE project_namespace_traversal_paths
      (
          `id` Int64 DEFAULT 0,
          `traversal_path` String DEFAULT '0/',
          `version` DateTime64(6, 'UTC') DEFAULT now(),
          `deleted` Bool DEFAULT false
      )
      ENGINE = ReplicatedReplacingMergeTree(version, deleted)
      PRIMARY KEY id
      ORDER BY id
      SETTINGS index_granularity = 512;
      SQL

      expect(result).to eq(expectation)
    end

    describe 'engine combinations' do
      using RSpec::Parameterized::TableSyntax

      where(:non_replicated_version, :replicated_version) do
        'ENGINE = ReplacingMergeTree(version, deleted)' | 'ENGINE = ReplicatedReplacingMergeTree(version, deleted)'
        'ENGINE = AggregatingMergeTree(version, deleted)' | 'ENGINE = ReplicatedAggregatingMergeTree(version, deleted)'
        'ENGINE = SummingMergeTree(version, deleted)' | 'ENGINE = ReplicatedSummingMergeTree(version, deleted)'
        'ENGINE = MergeTree' | 'ENGINE = ReplicatedMergeTree'
        'ENGINE=MergeTree' | 'ENGINE=ReplicatedMergeTree'
        'engine= MergeTree' | 'engine= ReplicatedMergeTree'
        '' | ''
        'engine=Memory' | 'engine=Memory'
      end

      with_them do
        it { expect(described_class.patch_replicated(non_replicated_version)).to eq(replicated_version) }
      end
    end
  end

  describe '.unpatch_replicated' do
    using RSpec::Parameterized::TableSyntax

    where(:replicated_version, :non_replicated_version) do
      "ENGINE = ReplicatedReplacingMergeTree('/{shard}', '{repl}', ver, d)" | 'ENGINE = ReplacingMergeTree(ver, d)'
      "ENGINE = ReplicatedAggregatingMergeTree('/{shard}', '{repl}', ver, d)" | 'ENGINE = AggregatingMergeTree(ver, d)'
      "ENGINE = ReplicatedMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')" | 'ENGINE = MergeTree'
      "ENGINE    =   ReplicatedMergeTree('/clickhouse/tables/{uuid}/{shard}', '{replica}')" | 'ENGINE = MergeTree'
      '' | ''
    end

    with_them do
      it { expect(described_class.unpatch_replicated(replicated_version)).to eq(non_replicated_version) }
    end
  end
end
