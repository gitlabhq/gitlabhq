# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::QueryAnalyzers::Ci::PartitioningIdAnalyzer, query_analyzers: false do
  let(:analyzer) { described_class }

  before do
    allow(Gitlab::Database::QueryAnalyzer.instance).to receive(:all_analyzers).and_return([analyzer])
  end

  context 'when ci_partitioning_analyze_queries_partition_id_check is disabled' do
    before do
      stub_feature_flags(ci_partitioning_analyze_queries_partition_id_check: false)
    end

    it 'does not analyze the query' do
      expect(analyzer).not_to receive(:analyze)

      process_sql(Ci::BuildMetadata, "SELECT 1 FROM ci_builds_metadata")
    end
  end

  context 'when ci_partitioning_analyze_queries_partition_id_check is enabled' do
    context 'when querying a routing table' do
      shared_examples 'a good query' do |sql|
        it 'does not raise error' do
          expect { process_sql(Ci::BuildMetadata, sql) }.not_to raise_error
        end
      end

      shared_examples 'a bad query' do |sql|
        it 'raises PartitionIdMissingError' do
          expect { process_sql(Ci::BuildMetadata, sql) }.to raise_error(described_class::PartitionIdMissingError)
        end
      end

      context 'when partition_id is present' do
        context 'when selecting data' do
          it_behaves_like 'a good query', 'SELECT * FROM p_ci_builds_metadata WHERE partition_id = 100'
        end

        context 'with a join query' do
          sql = <<~SQL
            SELECT ci_builds.id
            FROM p_ci_builds
            JOIN p_ci_builds_metadata ON p_ci_builds_metadata.build_id = ci_builds.id
            WHERE ci_builds.type = 'Ci::Build'
              AND ci_builds.partition_id = 100
              AND (NOT p_ci_builds_metadata.id IN
                    (SELECT p_ci_builds_metadata.id
                      FROM p_ci_builds_metadata
                      WHERE p_ci_builds_metadata.build_id = ci_builds.id
                        AND p_ci_builds_metadata.interruptible = TRUE
                        AND p_ci_builds_metadata.partition_id = 100 ));
          SQL

          it_behaves_like 'a good query', sql
        end

        context 'when removing data' do
          it_behaves_like 'a good query', 'DELETE FROM p_ci_builds_metadata WHERE partition_id = 100'
        end

        context 'when updating data' do
          sql = 'UPDATE p_ci_builds_metadata SET interruptible = false WHERE partition_id = 100'

          it_behaves_like 'a good query', sql
        end

        context 'when inserting a record' do
          it_behaves_like 'a good query', 'INSERT INTO p_ci_builds_metadata (id, partition_id) VALUES(1, 1)'
        end
      end

      context 'when partition_id is missing' do
        context 'when inserting a record' do
          it_behaves_like 'a bad query', 'INSERT INTO p_ci_builds_metadata (id) VALUES(1)'
        end

        context 'when selecting data' do
          it_behaves_like 'a bad query', 'SELECT * FROM p_ci_builds_metadata WHERE id = 1'
        end

        context 'when removing data' do
          it_behaves_like 'a bad query', 'DELETE FROM p_ci_builds_metadata WHERE id = 1'
        end

        context 'when updating data' do
          it_behaves_like 'a bad query', 'UPDATE p_ci_builds_metadata SET interruptible = false WHERE id = 1'
        end

        context 'with a join query' do
          sql = <<~SQL
            SELECT ci_builds.id
            FROM ci_builds
            JOIN p_ci_builds_metadata ON p_ci_builds_metadata.build_id = ci_builds.id
            WHERE ci_builds.type = 'Ci::Build'
              AND ci_builds.partition_id = 100
              AND (NOT p_ci_builds_metadata.id IN
                    (SELECT p_ci_builds_metadata.id
                      FROM p_ci_builds_metadata
                      WHERE p_ci_builds_metadata.build_id = ci_builds.id
                        AND p_ci_builds_metadata.interruptible = TRUE ));
          SQL

          it_behaves_like 'a bad query', sql
        end
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
