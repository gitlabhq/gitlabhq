# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::QueryAnalyzer, query_analyzers: false do
  using RSpec::Parameterized::TableSyntax

  let(:analyzer) { double(:query_analyzer) }
  let(:user_analyzer) { double(:user_query_analyzer) }
  let(:disabled_analyzer) { double(:disabled_query_analyzer) }

  before do
    allow(analyzer).to receive(:enabled?).and_return(true)
    allow(analyzer).to receive(:suppressed?).and_return(false)
    allow(analyzer).to receive(:begin!)
    allow(analyzer).to receive(:end!)
    allow(disabled_analyzer).to receive(:enabled?).and_return(false)
  end

  context 'the hook is enabled by default in specs' do
    before do
      allow(described_class.instance).to receive(:all_analyzers).and_return([analyzer, disabled_analyzer])
    end

    it 'does process queries and gets normalized SQL' do
      expect(analyzer).to receive(:enabled?).and_return(true)
      expect(analyzer).to receive(:analyze) do |parsed|
        expect(parsed.sql).to include("SELECT $1 FROM projects")
        expect(parsed.raw).to include("SELECT 1 FROM projects")
        expect(parsed.pg.tables).to eq(%w[projects])
      end

      described_class.instance.within do
        Project.connection.execute("SELECT 1 FROM projects")
      end
    end

    it 'does prevent recursive execution' do
      expect(analyzer).to receive(:enabled?).and_return(true)
      expect(analyzer).to receive(:analyze) do
        Project.connection.execute("SELECT 1 FROM projects")
      end

      described_class.instance.within do
        Project.connection.execute("SELECT 1 FROM projects")
      end
    end
  end

  describe '#within' do
    before do
      allow(described_class.instance).to receive(:all_analyzers).and_return([analyzer, disabled_analyzer])
    end

    context 'when it is already initialized' do
      around do |example|
        described_class.instance.within do
          example.run
        end
      end

      it 'does initialize analyzer only once' do
        expect(analyzer).to receive(:enabled?).once
        expect(analyzer).to receive(:begin!).once
        expect(analyzer).to receive(:end!).once

        expect { |b| described_class.instance.within(&b) }.to yield_control
      end

      it 'does initialize user analyzer when enabled' do
        expect(user_analyzer).to receive(:enabled?).and_return(true)
        expect(user_analyzer).to receive(:begin!)
        expect(user_analyzer).to receive(:end!)

        expect { |b| described_class.instance.within([user_analyzer], &b) }.to yield_control
      end

      it 'does initialize user analyzer only once' do
        expect(user_analyzer).to receive(:enabled?).and_return(false, true)
        expect(user_analyzer).to receive(:begin!).once
        expect(user_analyzer).to receive(:end!).once

        expect { |b| described_class.instance.within([user_analyzer, user_analyzer, user_analyzer], &b) }.to yield_control
      end

      it 'does not initializer user analyzer when disabled' do
        expect(user_analyzer).to receive(:enabled?).and_return(false)
        expect(user_analyzer).not_to receive(:begin!)
        expect(user_analyzer).not_to receive(:end!)

        expect { |b| described_class.instance.within([user_analyzer], &b) }.to yield_control
      end
    end

    context 'when initializer is enabled' do
      before do
        expect(analyzer).to receive(:enabled?).and_return(true)
      end

      it 'calls begin! and end!' do
        expect(analyzer).to receive(:begin!)
        expect(analyzer).to receive(:end!)

        expect { |b| described_class.instance.within(&b) }.to yield_control
      end

      it 'when begin! raises the end! is not called' do
        expect(analyzer).to receive(:begin!).and_raise('exception')
        expect(analyzer).not_to receive(:end!)
        expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception)

        expect { |b| described_class.instance.within(&b) }.to yield_control
      end
    end

    context 'when user analyzers are used' do
      it 'calls begin! and end!' do
        expect(analyzer).not_to receive(:begin!)
        allow(user_analyzer).to receive(:enabled?).and_return(true)
        allow(user_analyzer).to receive(:suppressed?).and_return(false)
        expect(user_analyzer).to receive(:begin!)
        expect(user_analyzer).to receive(:end!)

        expect { |b| described_class.instance.within([user_analyzer], &b) }.to yield_control
      end
    end
  end

  describe '#process_sql' do
    before do
      allow(described_class.instance).to receive(:all_analyzers).and_return([analyzer, disabled_analyzer])
    end

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
      expect(Gitlab::ErrorTracking).to receive(:track_exception).once
      expect(analyzer).to receive(:enabled?).and_return(true)
      expect(analyzer).to receive(:analyze) do |parsed|
        expect(parsed.sql).to be_nil
        expect(parsed.pg).to be_nil
      end

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

    it 'does call analyze only on enabled initializers' do
      expect(analyzer).to receive(:analyze)
      expect(disabled_analyzer).not_to receive(:analyze)

      expect { process_sql("SELECT 1 FROM projects") }.not_to raise_error
    end

    it 'does not call analyze on suppressed analyzers' do
      expect(analyzer).to receive(:suppressed?).and_return(true)
      expect(analyzer).to receive(:requires_tracking?).and_return(false)
      expect(analyzer).not_to receive(:analyze)

      expect { process_sql("SELECT 1 FROM projects") }.not_to raise_error
    end

    it 'does call analyze on suppressed analyzers if some queries require tracking' do
      expect(analyzer).to receive(:suppressed?).and_return(true)
      expect(analyzer).to receive(:requires_tracking?).and_return(true)
      expect(analyzer).to receive(:analyze)

      expect { process_sql("SELECT 1 FROM projects") }.not_to raise_error
    end

    context 'with different event names' do
      where(:event, :parsed_event) do
        'Project Load'                     | 'load'
        'Namespaces::UserNamespace Create' | 'create'
        'Project Update'                   | 'update'
        'Project Destroy'                  | 'destroy'
        'Project Pluck'                    | 'pluck'
        'Project Insert'                   | 'insert'
        'Project Delete All'               | 'delete_all'
        'Project Exists?'                  | 'exists?'
        nil                                | ''
        'TRANSACTION'                      | 'transaction'
        'SCHEMA'                           | 'schema'
      end

      with_them do
        it 'parses event name correctly' do
          expect(analyzer).to receive(:enabled?).and_return(true)
          expect(analyzer).to receive(:analyze) do |parsed|
            expect(parsed.event_name).to eq(parsed_event)
          end

          process_sql("SELECT 1 FROM projects", event)
        end
      end
    end

    def process_sql(sql, event_name = 'load')
      described_class.instance.within do
        ApplicationRecord.load_balancer.read_write do |connection|
          described_class.instance.send(:process_sql, sql, connection, event_name)
        end
      end
    end
  end

  describe described_class::Parsed do
    let(:raw) { 'SELECT 1 FROM projects' }
    let(:connection) { double(:connection) }
    let(:event_name) { 'Project Load' }
    let(:parsed) { described_class.new(raw, connection, event_name) }

    it 'does not parse query twice' do
      expect(PgQuery).to receive(:parse).once.and_call_original
      expect(parsed.pg).not_to be_nil
      expect(parsed.pg.query).to eq(raw)
    end

    it 'does not normalize query twice' do
      expect(PgQuery).to receive(:normalize).once.and_call_original
      expect(parsed.sql).not_to be_nil
      expect(parsed.sql).to eq('SELECT $1 FROM projects')
    end

    context 'when SQL is invalid' do
      let(:raw) { 'SELEC 1 FROM projects' }

      it 'does not attempt to parse query twice' do
        expect(PgQuery).to receive(:parse).once.and_call_original
        expect([parsed.pg, parsed.pg]).to match_array([nil, nil])
      end

      it 'does not attempt to normalize query twice' do
        expect(PgQuery).to receive(:normalize).once.and_call_original
        expect([parsed.sql, parsed.sql]).to match_array([nil, nil])
      end

      it 'does not attempt to parse if normalize already failed' do
        expect(PgQuery).to receive(:normalize).once.and_call_original
        expect(PgQuery).not_to receive(:parse)
        expect(parsed.sql).to be_nil
        expect(parsed.pg).to be_nil
        expect(parsed.error).to be_an_instance_of(PgQuery::ParseError)
      end
    end
  end
end
