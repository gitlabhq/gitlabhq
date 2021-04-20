# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::Subscribers::ActiveRecord do
  using RSpec::Parameterized::TableSyntax

  let(:env) { {} }
  let(:subscriber) { described_class.new }
  let(:connection) { double(:connection) }

  describe '#transaction' do
    let(:web_transaction) { double('Gitlab::Metrics::WebTransaction') }
    let(:background_transaction) { double('Gitlab::Metrics::WebTransaction') }

    let(:event) do
      double(
        :event,
        name: 'transaction.active_record',
        duration: 230,
        payload:  { connection: connection }
      )
    end

    before do
      allow(background_transaction).to receive(:observe)
      allow(web_transaction).to receive(:observe)
    end

    context 'when both web and background transaction are available' do
      before do
        allow(::Gitlab::Metrics::WebTransaction).to receive(:current)
          .and_return(web_transaction)
        allow(::Gitlab::Metrics::BackgroundTransaction).to receive(:current)
          .and_return(background_transaction)
      end

      it 'captures the metrics for web only' do
        expect(web_transaction).to receive(:observe).with(:gitlab_database_transaction_seconds, 0.23)

        expect(background_transaction).not_to receive(:observe)
        expect(background_transaction).not_to receive(:increment)

        subscriber.transaction(event)
      end
    end

    context 'when web transaction is available' do
      let(:web_transaction) { double('Gitlab::Metrics::WebTransaction') }

      before do
        allow(::Gitlab::Metrics::WebTransaction).to receive(:current)
          .and_return(web_transaction)
        allow(::Gitlab::Metrics::BackgroundTransaction).to receive(:current)
          .and_return(nil)
      end

      it 'captures the metrics for web only' do
        expect(web_transaction).to receive(:observe).with(:gitlab_database_transaction_seconds, 0.23)

        expect(background_transaction).not_to receive(:observe)
        expect(background_transaction).not_to receive(:increment)

        subscriber.transaction(event)
      end
    end

    context 'when background transaction is available' do
      let(:background_transaction) { double('Gitlab::Metrics::BackgroundTransaction') }

      before do
        allow(::Gitlab::Metrics::WebTransaction).to receive(:current)
          .and_return(nil)
        allow(::Gitlab::Metrics::BackgroundTransaction).to receive(:current)
          .and_return(background_transaction)
      end

      it 'captures the metrics for web only' do
        expect(background_transaction).to receive(:observe).with(:gitlab_database_transaction_seconds, 0.23)

        expect(web_transaction).not_to receive(:observe)
        expect(web_transaction).not_to receive(:increment)

        subscriber.transaction(event)
      end
    end
  end

  describe '#sql' do
    let(:payload) { { sql: 'SELECT * FROM users WHERE id = 10', connection: connection } }

    let(:event) do
      double(
        :event,
        name: 'sql.active_record',
        duration: 2,
        payload:  payload
      )
    end

    # Emulate Marginalia pre-pending comments
    def sql(query, comments: true)
      if comments && !%w[BEGIN COMMIT].include?(query)
        "/*application:web,controller:badges,action:pipeline,correlation_id:01EYN39K9VMJC56Z7808N7RSRH*/ #{query}"
      else
        query
      end
    end

    shared_examples 'track generic sql events' do
      where(:name, :sql_query, :record_query, :record_write_query, :record_cached_query) do
        'SQL' | 'SELECT * FROM users WHERE id = 10' | true | false | false
        'SQL' | 'WITH active_milestones AS (SELECT COUNT(*), state FROM milestones GROUP BY state) SELECT * FROM active_milestones' | true | false | false
        'SQL' | 'SELECT * FROM users WHERE id = 10 FOR UPDATE' | true | true | false
        'SQL' | 'WITH archived_rows AS (SELECT * FROM users WHERE archived = true) INSERT INTO products_log SELECT * FROM archived_rows' | true | true | false
        'SQL' | 'DELETE FROM users where id = 10' | true | true | false
        'SQL' | 'INSERT INTO project_ci_cd_settings (project_id) SELECT id FROM projects' | true | true | false
        'SQL' | 'UPDATE users SET admin = true WHERE id = 10' | true | true | false
        'CACHE' | 'SELECT * FROM users WHERE id = 10' | true | false | true
        'SCHEMA' | "SELECT attr.attname FROM pg_attribute attr INNER JOIN pg_constraint cons ON attr.attrelid = cons.conrelid AND attr.attnum = any(cons.conkey) WHERE cons.contype = 'p' AND cons.conrelid = '\"projects\"'::regclass" | false | false | false
        nil | 'BEGIN' | false | false | false
        nil | 'COMMIT' | false | false | false
      end

      with_them do
        let(:payload) { { name: name, sql: sql(sql_query, comments: comments), connection: connection } }
        let(:record_wal_query) { false }

        it 'marks the current thread as using the database' do
          # since it would already have been toggled by other specs
          Thread.current[:uses_db_connection] = nil

          expect { subscriber.sql(event) }.to change { Thread.current[:uses_db_connection] }.from(nil).to(true)
        end

        it_behaves_like 'record ActiveRecord metrics'
        it_behaves_like 'store ActiveRecord info in RequestStore'
      end
    end

    context 'without Marginalia comments' do
      let(:comments) { false }

      it_behaves_like 'track generic sql events'
    end

    context 'with Marginalia comments' do
      let(:comments) { true }

      it_behaves_like 'track generic sql events'
    end
  end
end
