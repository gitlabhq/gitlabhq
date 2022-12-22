# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::QueryAnalyzer, query_analyzers: false do
  let(:analyzer) { double(:query_analyzer) }
  let(:user_analyzer) { double(:user_query_analyzer) }
  let(:disabled_analyzer) { double(:disabled_query_analyzer) }

  before do
    allow(described_class.instance).to receive(:all_analyzers).and_return([analyzer, disabled_analyzer])
    allow(analyzer).to receive(:enabled?).and_return(true)
    allow(analyzer).to receive(:suppressed?).and_return(false)
    allow(analyzer).to receive(:begin!)
    allow(analyzer).to receive(:end!)
    allow(disabled_analyzer).to receive(:enabled?).and_return(false)
  end

  context 'the hook is enabled by default in specs' do
    it 'does process queries and gets normalized SQL' do
      expect(analyzer).to receive(:enabled?).and_return(true)
      expect(analyzer).to receive(:analyze) do |parsed|
        expect(parsed.sql).to include("SELECT $1 FROM projects")
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

    def process_sql(sql)
      described_class.instance.within do
        ApplicationRecord.load_balancer.read_write do |connection|
          described_class.instance.send(:process_sql, sql, connection)
        end
      end
    end
  end
end
