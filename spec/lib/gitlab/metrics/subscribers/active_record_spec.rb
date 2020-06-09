# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Metrics::Subscribers::ActiveRecord do
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
      shared_examples 'read only query' do
        it 'increments only db count value' do
          allow(subscriber).to receive(:current_transaction)
                                  .at_least(:once)
                                  .and_return(transaction)

          expect(transaction).to receive(:increment)
                                   .with(:db_count, 1)

          expect(transaction).not_to receive(:increment)
                                       .with(:db_cached_count, 1)

          expect(transaction).not_to receive(:increment)
                                       .with(:db_write_count, 1)

          subscriber.sql(event)
        end
      end

      shared_examples 'write query' do
        it 'increments db_write_count and db_count value' do
          expect(subscriber).to receive(:current_transaction)
                                  .at_least(:once)
                                  .and_return(transaction)

          expect(transaction).to receive(:increment)
                                   .with(:db_count, 1)

          expect(transaction).not_to receive(:increment)
                                       .with(:db_cached_count, 1)

          expect(transaction).to receive(:increment)
                                       .with(:db_write_count, 1)

          subscriber.sql(event)
        end
      end

      shared_examples 'cached query' do
        it 'increments db_cached_count and db_count value' do
          expect(subscriber).to receive(:current_transaction)
                                  .at_least(:once)
                                  .and_return(transaction)

          expect(transaction).to receive(:increment)
                                   .with(:db_count, 1)

          expect(transaction).to receive(:increment)
                                       .with(:db_cached_count, 1)

          expect(transaction).not_to receive(:increment)
                                   .with(:db_write_count, 1)

          subscriber.sql(event)
        end
      end

      it 'observes sql_duration metric' do
        expect(subscriber).to receive(:current_transaction)
                                .at_least(:once)
                                .and_return(transaction)
        expect(described_class.send(:gitlab_sql_duration_seconds)).to receive(:observe).with({}, 0.002)
        subscriber.sql(event)
      end

      it_behaves_like 'read only query'

      context 'with select for update sql event' do
        let(:payload) { { sql: 'SELECT * FROM users WHERE id = 10 FOR UPDATE' } }

        it_behaves_like 'write query'
      end

      context 'with common table expression' do
        context 'with insert' do
          let(:payload) { { sql: 'WITH archived_rows AS (SELECT * FROM users WHERE archived = true) INSERT INTO products_log SELECT * FROM archived_rows' } }

          it_behaves_like 'write query'
        end

        context 'with only select' do
          let(:payload) { { sql: 'WITH active_milestones AS (SELECT COUNT(*), state FROM milestones GROUP BY state) SELECT * FROM active_milestones' } }

          it_behaves_like 'read only query'
        end
      end

      context 'with delete sql event' do
        let(:payload) { { sql: 'DELETE FROM users where id = 10' } }

        it_behaves_like 'write query'
      end

      context 'with insert sql event' do
        let(:payload) { { sql: 'INSERT INTO project_ci_cd_settings (project_id) SELECT id FROM projects' } }

        it_behaves_like 'write query'
      end

      context 'with update sql event' do
        let(:payload) { { sql: 'UPDATE users SET admin = true WHERE id = 10' } }

        it_behaves_like 'write query'
      end

      context 'with cached payload ' do
        let(:payload) do
          {
            sql: 'SELECT * FROM users WHERE id = 10',
            cached: true
          }
        end

        it_behaves_like 'cached query'
      end

      context 'with cached payload name' do
        let(:payload) do
          {
           sql: 'SELECT * FROM users WHERE id = 10',
           name: 'CACHE'
          }
        end

        it_behaves_like 'cached query'
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
          expect(subscriber).to receive(:current_transaction)
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
end
