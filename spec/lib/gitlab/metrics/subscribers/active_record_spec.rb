# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::Subscribers::ActiveRecord do
  let(:env) { {} }
  let(:transaction) { Gitlab::Metrics::WebTransaction.new(env) }
  let(:subscriber)  { described_class.new }
  let(:payload) { { sql: 'SELECT * FROM users WHERE id = 10' } }

  let(:event) do
    double(
      :event,
      name: 'sql.active_record',
      duration: 2,
      payload:  payload
    )
  end

  describe '#sql' do
    describe 'without a current transaction' do
      it 'simply returns' do
        expect_any_instance_of(Gitlab::Metrics::Transaction)
          .not_to receive(:increment)

        subscriber.sql(event)
      end
    end

    describe 'with a current transaction' do
      shared_examples 'track executed query' do
        before do
          allow(subscriber).to receive(:current_transaction)
                                 .at_least(:once)
                                 .and_return(transaction)
        end

        it 'increments only db count value' do
          described_class::DB_COUNTERS.each do |counter|
            prometheus_counter = "gitlab_transaction_#{counter}_total".to_sym
            if expected_counters[counter] > 0
              expect(transaction).to receive(:increment).with(prometheus_counter, 1)
            else
              expect(transaction).not_to receive(:increment).with(prometheus_counter, 1)
            end
          end

          subscriber.sql(event)
        end

        context 'when RequestStore is enabled' do
          it 'caches db count value', :request_store, :aggregate_failures do
            subscriber.sql(event)

            described_class::DB_COUNTERS.each do |counter|
              expect(Gitlab::SafeRequestStore[counter].to_i).to eq expected_counters[counter]
            end
          end

          it 'prevents db counters from leaking to the next transaction' do
            2.times do
              Gitlab::WithRequestStore.with_request_store do
                subscriber.sql(event)

                described_class::DB_COUNTERS.each do |counter|
                  expect(Gitlab::SafeRequestStore[counter].to_i).to eq expected_counters[counter]
                end
              end
            end
          end
        end
      end

      it 'observes sql_duration metric' do
        expect(subscriber).to receive(:current_transaction)
                                .at_least(:once)
                                .and_return(transaction)
        expect(transaction).to receive(:observe).with(:gitlab_sql_duration_seconds, 0.002)

        subscriber.sql(event)
      end

      it 'marks the current thread as using the database' do
        # since it would already have been toggled by other specs
        Thread.current[:uses_db_connection] = nil

        expect { subscriber.sql(event) }.to change { Thread.current[:uses_db_connection] }.from(nil).to(true)
      end

      context 'with read query' do
        let(:expected_counters) do
          {
            db_count: 1,
            db_write_count: 0,
            db_cached_count: 0
          }
        end

        it_behaves_like 'track executed query'

        context 'with only select' do
          let(:payload) { { sql: 'WITH active_milestones AS (SELECT COUNT(*), state FROM milestones GROUP BY state) SELECT * FROM active_milestones' } }

          it_behaves_like 'track executed query'
        end
      end

      context 'write query' do
        let(:expected_counters) do
          {
            db_count: 1,
            db_write_count: 1,
            db_cached_count: 0
          }
        end

        context 'with select for update sql event' do
          let(:payload) { { sql: 'SELECT * FROM users WHERE id = 10 FOR UPDATE' } }

          it_behaves_like 'track executed query'
        end

        context 'with common table expression' do
          context 'with insert' do
            let(:payload) { { sql: 'WITH archived_rows AS (SELECT * FROM users WHERE archived = true) INSERT INTO products_log SELECT * FROM archived_rows' } }

            it_behaves_like 'track executed query'
          end
        end

        context 'with delete sql event' do
          let(:payload) { { sql: 'DELETE FROM users where id = 10' } }

          it_behaves_like 'track executed query'
        end

        context 'with insert sql event' do
          let(:payload) { { sql: 'INSERT INTO project_ci_cd_settings (project_id) SELECT id FROM projects' } }

          it_behaves_like 'track executed query'
        end

        context 'with update sql event' do
          let(:payload) { { sql: 'UPDATE users SET admin = true WHERE id = 10' } }

          it_behaves_like 'track executed query'
        end
      end

      context 'with cached query' do
        let(:expected_counters) do
          {
            db_count: 1,
            db_write_count: 0,
            db_cached_count: 1
          }
        end

        context 'with cached payload ' do
          let(:payload) do
            {
              sql: 'SELECT * FROM users WHERE id = 10',
              cached: true
            }
          end

          it_behaves_like 'track executed query'
        end

        context 'with cached payload name' do
          let(:payload) do
            {
             sql: 'SELECT * FROM users WHERE id = 10',
             name: 'CACHE'
            }
          end

          it_behaves_like 'track executed query'
        end
      end

      context 'events are internal to Rails or irrelevant' do
        let(:schema_event) do
          double(
            :event,
            name: 'sql.active_record',
            payload: {
              sql: "SELECT attr.attname FROM pg_attribute attr INNER JOIN pg_constraint cons ON attr.attrelid = cons.conrelid AND attr.attnum = any(cons.conkey) WHERE cons.contype = 'p' AND cons.conrelid = '\"projects\"'::regclass",
              name: 'SCHEMA',
              connection_id: 135,
              statement_name: nil,
              binds: []
            },
            duration: 0.7
          )
        end

        let(:begin_event) do
          double(
            :event,
            name: 'sql.active_record',
            payload: {
              sql: "BEGIN",
              name: nil,
              connection_id: 231,
              statement_name: nil,
              binds: []
            },
            duration: 1.1
          )
        end

        let(:commit_event) do
          double(
            :event,
            name: 'sql.active_record',
            payload: {
              sql: "COMMIT",
              name: nil,
              connection_id: 212,
              statement_name: nil,
              binds: []
            },
            duration: 1.6
          )
        end

        it 'skips schema/begin/commit sql commands' do
          allow(subscriber).to receive(:current_transaction)
                                  .at_least(:once)
                                  .and_return(transaction)

          expect(transaction).not_to receive(:increment)

          subscriber.sql(schema_event)
          subscriber.sql(begin_event)
          subscriber.sql(commit_event)
        end
      end
    end
  end

  describe 'self.db_counter_payload' do
    before do
      allow(subscriber).to receive(:current_transaction)
                             .at_least(:once)
                             .and_return(transaction)
    end

    context 'when RequestStore is enabled', :request_store do
      context 'when query is executed' do
        let(:expected_payload) do
          {
            db_count: 1,
            db_cached_count: 0,
            db_write_count: 0
          }
        end

        it 'returns correct payload' do
          subscriber.sql(event)

          expect(described_class.db_counter_payload).to eq(expected_payload)
        end
      end

      context 'when query is not executed' do
        let(:expected_payload) do
          {
            db_count: 0,
            db_cached_count: 0,
            db_write_count: 0
          }
        end

        it 'returns correct payload' do
          expect(described_class.db_counter_payload).to eq(expected_payload)
        end
      end
    end

    context 'when RequestStore is disabled' do
      let(:expected_payload) { {} }

      it 'returns empty payload' do
        subscriber.sql(event)

        expect(described_class.db_counter_payload).to eq(expected_payload)
      end
    end
  end
end
