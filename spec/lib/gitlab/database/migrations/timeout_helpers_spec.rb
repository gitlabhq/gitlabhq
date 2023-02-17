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

      it 'yields control without disabling the timeout or resetting' do
        expect(model).not_to receive(:execute).with('SET statement_timeout TO 0')
        expect(model).not_to receive(:execute).with('RESET statement_timeout')

        expect { |block| model.disable_statement_timeout(&block) }.to yield_control
      end
    end
  end
end
