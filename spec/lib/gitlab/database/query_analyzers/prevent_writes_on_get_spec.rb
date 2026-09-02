# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::QueryAnalyzers::PreventWritesOnGet, query_analyzers: false, feature_category: :database do
  let(:analyzer) { described_class }
  let(:request_method) { 'GET' }

  before do
    allow(Gitlab::Middleware::QueryAnalyzer).to receive(:http_request_method).and_return(request_method)
    allow(analyzer).to receive_messages(backtrace: [], suppressed?: false)
    allow(::Feature::FlipperFeature).to receive(:table_exists?).and_return(true)
  end

  after do
    Thread.current[:query_analyzer_enabled_analyzers] = []
  end

  context 'when a GET request executes a write query' do
    where(:sql) do
      [
        "INSERT INTO projects (name) VALUES ('gitlab')",
        "UPDATE projects SET name = 'gitlab' WHERE id = 1",
        "DELETE FROM projects WHERE id = 1",
        "SELECT * FROM projects WHERE id = 1 FOR UPDATE"
      ]
    end

    with_them do
      it 'logs the violation' do
        expect(described_class::Logger).to receive(:warn).with(a_hash_including(
          message: 'write_on_get_detected',
          request_method: 'GET',
          tables: ['projects']
        ))

        process_sql(sql)
      end
    end

    context 'when the request is a HEAD' do
      let(:request_method) { 'HEAD' }

      it 'logs the violation' do
        expect(described_class::Logger).to receive(:warn).with(a_hash_including(message: 'write_on_get_detected'))

        process_sql("DELETE FROM projects WHERE id = 1")
      end
    end

    context 'when the write is wrapped in allow_write_on_get' do
      before do
        allow(analyzer).to receive(:suppressed?).and_call_original
      end

      it 'does not log' do
        expect(described_class::Logger).not_to receive(:warn)

        described_class.allow_write_on_get(url: 'https://example.com/issue') do
          process_sql("DELETE FROM projects WHERE id = 1")
        end
      end
    end

    context 'when the endpoint is in the allowed list' do
      before do
        allow(::Gitlab::ApplicationContext).to receive(:current_context_attribute)
          .with(:caller_id).and_return('Projects::MergeRequestsController#show')
      end

      it 'does not log' do
        expect(described_class::Logger).not_to receive(:warn)

        process_sql("UPDATE merge_requests SET merge_status = 'cannot_be_merged' WHERE id = 1")
      end
    end

    context 'when only ignored tables are written' do
      where(:sql) do
        [
          "INSERT INTO schema_migrations (version) VALUES ('1')",
          "DELETE FROM plans WHERE id = 1"
        ]
      end

      with_them do
        it 'does not log' do
          expect(described_class::Logger).not_to receive(:warn)

          process_sql(sql)
        end
      end
    end

    context 'when the query is cached' do
      it 'does not log' do
        expect(described_class::Logger).not_to receive(:warn)

        process_sql("DELETE FROM projects WHERE id = 1", cached: true)
      end
    end

    context 'when the detect_writes_on_get flag is disabled' do
      before do
        stub_feature_flags(detect_writes_on_get: false)
      end

      it 'does not log' do
        expect(described_class::Logger).not_to receive(:warn)

        process_sql("DELETE FROM projects WHERE id = 1")
      end
    end
  end

  context 'when a GET request executes a read query' do
    where(:sql) do
      [
        "SELECT * FROM projects WHERE id = 1",
        "SELECT * FROM projects WHERE name = 'please update me'"
      ]
    end

    with_them do
      it 'does not log' do
        expect(described_class::Logger).not_to receive(:warn)

        process_sql(sql)
      end
    end
  end

  context 'when a POST request executes a write query' do
    let(:request_method) { 'POST' }

    it 'does not log' do
      expect(described_class::Logger).not_to receive(:warn)

      process_sql("DELETE FROM projects WHERE id = 1")
    end
  end

  context 'when there is no HTTP request' do
    let(:request_method) { nil }

    it 'does not log' do
      expect(described_class::Logger).not_to receive(:warn)

      process_sql("DELETE FROM projects WHERE id = 1")
    end
  end

  private

  def process_sql(sql, cached: false)
    Gitlab::Database::QueryAnalyzer.instance.within([analyzer]) do
      Gitlab::Database::QueryAnalyzer.instance
        .send(:process_sql, sql, ActiveRecord::Base.connection, 'load', cached)
    end
  end
end
