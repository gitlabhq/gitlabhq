# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::QueryAnalyzer do
  let(:analyzer) { double(:query_analyzer) }

  before do
    stub_const('Gitlab::Database::QueryAnalyzer::ANALYZERS', [analyzer])
  end

  context 'the hook is enabled by default in specs' do
    it 'does process queries and gets normalized SQL' do
      expect(analyzer).to receive(:enabled?).and_return(true)
      expect(analyzer).to receive(:analyze) do |parsed|
        expect(parsed.sql).to include("SELECT $1 FROM projects")
        expect(parsed.pg.tables).to eq(%w[projects])
      end

      Project.connection.execute("SELECT 1 FROM projects")
    end
  end

  describe '#process_sql' do
    it 'does not analyze query if not enabled' do
      expect(analyzer).to receive(:enabled?).and_return(false)
      expect(analyzer).not_to receive(:analyze)

      process_sql("SELECT 1 FROM projects")
    end

    it 'does analyze query if enabled' do
      expect(analyzer).to receive(:enabled?).and_return(true)
      expect(analyzer).to receive(:analyze) do |parsed|
        expect(parsed.sql).to eq("SELECT $1 FROM projects")
        expect(parsed.pg.tables).to eq(%w[projects])
      end

      process_sql("SELECT 1 FROM projects")
    end

    it 'does track exception if query cannot be parsed' do
      expect(analyzer).to receive(:enabled?).and_return(true)
      expect(analyzer).not_to receive(:analyze)
      expect(Gitlab::ErrorTracking).to receive(:track_exception)

      expect { process_sql("invalid query") }.not_to raise_error
    end

    it 'does track exception if analyzer raises exception on enabled?' do
      expect(analyzer).to receive(:enabled?).and_raise('exception')
      expect(analyzer).not_to receive(:analyze)
      expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception)

      expect { process_sql("SELECT 1 FROM projects") }.not_to raise_error
    end

    it 'does track exception if analyzer raises exception on analyze' do
      expect(analyzer).to receive(:enabled?).and_return(true)
      expect(analyzer).to receive(:analyze).and_raise('exception')
      expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception)

      expect { process_sql("SELECT 1 FROM projects") }.not_to raise_error
    end

    def process_sql(sql)
      ApplicationRecord.load_balancer.read_write do |connection|
        described_class.instance.send(:process_sql, sql, connection)
      end
    end
  end
end
