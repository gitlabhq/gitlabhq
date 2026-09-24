# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Migrations::TimeoutHelpers, feature_category: :database do
  let(:model) do
    ActiveRecord::Migration.new.extend(described_class)
  end

  describe '#disable_statement_timeout' do
    it 'disables statement timeouts to current transaction only' do
      expect(model).to receive(:execute).with('SET LOCAL statement_timeout TO 0')

      model.disable_statement_timeout
    end

    it 'disables the transaction timeout for the current transaction only' do
      allow(model).to receive(:execute)
      expect(Gitlab::Database::TransactionTimeout).to receive(:disable).with(model.connection, local: true)

      model.disable_statement_timeout
    end

    # this specs runs without an enclosing transaction (:delete truncation method for db_cleaner)
    context 'with real environment', :delete do
      before do
        model.execute("SET statement_timeout TO '20000'")
      end

      after do
        model.execute('RESET statement_timeout')
      end

      it 'defines statement to 0 only for current transaction' do
        expect(model.execute('SHOW statement_timeout').first['statement_timeout']).to eq('20s')

        model.connection.transaction do
          model.disable_statement_timeout
          expect(model.execute('SHOW statement_timeout').first['statement_timeout']).to eq('0')
        end

        expect(model.execute('SHOW statement_timeout').first['statement_timeout']).to eq('20s')
      end

      context 'when passing a blocks' do
        it 'disables statement timeouts on session level and executes the block' do
          expect(model).to receive(:execute).with('SET statement_timeout TO 0')
          expect(model).to receive(:execute).with('RESET statement_timeout').at_least(:once)

          expect { |block| model.disable_statement_timeout(&block) }.to yield_control
        end

        it 'disables and resets the transaction timeout on session level around the block' do
          allow(model).to receive(:execute)
          allow(model).to receive(:transaction_timeout_disabled?).and_return(false)
          expect(Gitlab::Database::TransactionTimeout).to receive(:disable).with(model.connection).ordered
          expect(Gitlab::Database::TransactionTimeout).to receive(:reset).with(model.connection).ordered

          expect { |block| model.disable_statement_timeout(&block) }.to yield_control
        end

        context 'when the database is older than PostgreSQL 17' do
          before do
            allow(model.connection).to receive(:database_version).and_return(16_00_00)
          end

          it 'lifts only the statement timeout and never reads or sets transaction_timeout' do
            allow(model.connection).to receive(:execute).and_call_original
            allow(model.connection).to receive(:select_value).and_call_original
            expect(model.connection).not_to receive(:execute).with(/transaction_timeout/)
            expect(model.connection).not_to receive(:select_value).with(/transaction_timeout/)

            expect { |block| model.disable_statement_timeout(&block) }.to yield_control
          end
        end

        context 'when an outer scope already disabled the transaction timeout' do
          before do
            skip 'transaction_timeout requires PostgreSQL 17 or later' unless
              Gitlab::Database::TransactionTimeout.supported?(model.connection)
          end

          it 'leaves the outer exemption in place after the block' do
            model.connection.transaction do
              model.connection.execute('SET LOCAL transaction_timeout TO 0')
              expect(Gitlab::Database::TransactionTimeout).not_to receive(:reset)

              model.disable_statement_timeout { model.execute('SELECT 1') }

              expect(model.connection.select_value('SHOW transaction_timeout')).to eq('0')
            end
          end
        end

        # this specs runs without an enclosing transaction (:delete truncation method for db_cleaner)
        context 'with real environment', :delete do
          before do
            model.execute("SET statement_timeout TO '20000'")
          end

          after do
            model.execute('RESET statement_timeout')
          end

          it 'defines statement to 0 for any code run inside the block' do
            expect(model.execute('SHOW statement_timeout').first['statement_timeout']).to eq('20s')

            model.disable_statement_timeout do
              model.connection.transaction do
                expect(model.execute('SHOW statement_timeout').first['statement_timeout']).to eq('0')
              end

              expect(model.execute('SHOW statement_timeout').first['statement_timeout']).to eq('0')
            end
          end
        end
      end
    end

    # This spec runs without an enclosing transaction (:delete truncation method for db_cleaner)
    context 'when the statement_timeout is already disabled', :delete do
      before do
        ActiveRecord::Migration.connection.execute('SET statement_timeout TO 0')
      end

      after do
        # Use ActiveRecord::Migration.connection instead of model.execute
        # so that this call is not counted below
        ActiveRecord::Migration.connection.execute('RESET statement_timeout')
      end

      context 'when the transaction_timeout is already disabled too' do
        before do
          allow(model).to receive(:transaction_timeout_disabled?).and_return(true)
        end

        it 'yields control without disabling the timeouts or resetting' do
          expect(model).not_to receive(:execute).with('SET statement_timeout TO 0')
          expect(model).not_to receive(:execute).with('RESET statement_timeout')
          expect(Gitlab::Database::TransactionTimeout).not_to receive(:disable)
          expect(Gitlab::Database::TransactionTimeout).not_to receive(:reset)

          expect { |block| model.disable_statement_timeout(&block) }.to yield_control
        end
      end

      context 'when the transaction_timeout is still enabled' do
        before do
          skip 'transaction_timeout requires PostgreSQL 17 or later' unless
            Gitlab::Database::TransactionTimeout.supported?(model.connection)

          ActiveRecord::Migration.connection.execute("SET transaction_timeout TO '1h'")
        end

        after do
          ActiveRecord::Migration.connection.execute('RESET transaction_timeout')
        end

        it 'lifts only the transaction timeout around the block' do
          expect(model).not_to receive(:execute).with('SET statement_timeout TO 0')
          expect(model).not_to receive(:execute).with('RESET statement_timeout')
          expect(Gitlab::Database::TransactionTimeout).to receive(:reset).with(model.connection).and_call_original

          model.disable_statement_timeout do
            expect(model.connection.select_value('SHOW transaction_timeout')).to eq('0')
          end
        end
      end
    end
  end
end
