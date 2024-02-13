# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::QueryAnalyzers::Ci::PartitioningRoutingAnalyzer, query_analyzers: false do
  let(:analyzer) { described_class }

  before do
    allow(Gitlab::Database::QueryAnalyzer.instance).to receive(:all_analyzers).and_return([analyzer])
  end

  context 'when ci_partitioning_analyze_queries is disabled' do
    before do
      stub_feature_flags(ci_partitioning_analyze_queries: false)
    end

    it 'does not analyze the query' do
      expect(analyzer).not_to receive(:analyze)

      process_sql(Ci::BuildMetadata, "SELECT 1 FROM ci_builds_metadata")
    end
  end

  context 'when ci_partitioning_analyze_queries is enabled' do
    context 'when analyzing targeted tables' do
      described_class::ENABLED_TABLES.each do |enabled_table|
        context 'when querying a non routing table' do
          it 'tracks exception' do
            expect(::Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception)
            process_sql(Ci::ApplicationRecord, "SELECT 1 FROM #{enabled_table}")
          end

          it 'raises RoutingTableNotUsedError' do
            expect { process_sql(Ci::ApplicationRecord, "SELECT 1 FROM #{enabled_table}") }
              .to raise_error(described_class::RoutingTableNotUsedError)
          end
        end
      end

      context 'when updating a record' do
        it 'raises RoutingTableNotUsedError' do
          expect { process_sql(Ci::BuildMetadata, "UPDATE ci_builds_metadata SET id = 1") }
            .to raise_error(described_class::RoutingTableNotUsedError)
        end
      end

      context 'when inserting a record' do
        it 'raises RoutingTableNotUsedError' do
          expect { process_sql(Ci::BuildMetadata, "INSERT INTO ci_builds_metadata (id) VALUES(1)") }
            .to raise_error(described_class::RoutingTableNotUsedError)
        end
      end
    end

    context 'when analyzing non targeted table' do
      it 'does not raise error' do
        expect { process_sql(Ci::BuildMetadata, "SELECT 1 FROM projects") }.not_to raise_error
      end
    end
  end

  private

  def process_sql(model, sql)
    Gitlab::Database::QueryAnalyzer.instance.within do
      # Skip load balancer and retrieve connection assigned to model
      Gitlab::Database::QueryAnalyzer.instance.send(:process_sql, sql, model.retrieve_connection, 'load')
    end
  end
end
