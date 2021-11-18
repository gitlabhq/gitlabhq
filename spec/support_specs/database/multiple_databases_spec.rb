# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Database::MultipleDatabases' do
  describe '.with_reestablished_active_record_base' do
    context 'when doing establish_connection' do
      context 'on ActiveRecord::Base' do
        it 'raises exception' do
          expect { ActiveRecord::Base.establish_connection(:main) }.to raise_error /Cannot re-establish/
        end

        context 'when using with_reestablished_active_record_base' do
          it 'does not raise exception' do
            with_reestablished_active_record_base do
              expect { ActiveRecord::Base.establish_connection(:main) }.not_to raise_error
            end
          end
        end
      end

      context 'on Ci::ApplicationRecord' do
        before do
          skip_if_multiple_databases_not_setup
        end

        it 'raises exception' do
          expect { Ci::ApplicationRecord.establish_connection(:ci) }.to raise_error /Cannot re-establish/
        end

        context 'when using with_reestablished_active_record_base' do
          it 'does not raise exception' do
            with_reestablished_active_record_base do
              expect { Ci::ApplicationRecord.establish_connection(:main) }.not_to raise_error
            end
          end
        end
      end
    end

    context 'when trying to access connection' do
      context 'when reconnect is true' do
        it 'does not raise exception' do
          with_reestablished_active_record_base(reconnect: true) do
            expect { ActiveRecord::Base.connection.execute("SELECT 1") }.not_to raise_error # rubocop:disable Database/MultipleDatabases
          end
        end
      end

      context 'when reconnect is false' do
        it 'does raise exception' do
          with_reestablished_active_record_base(reconnect: false) do
            expect { ActiveRecord::Base.connection.execute("SELECT 1") }.to raise_error(ActiveRecord::ConnectionNotEstablished) # rubocop:disable Database/MultipleDatabases
          end
        end
      end
    end
  end
end
