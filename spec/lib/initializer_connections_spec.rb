# frozen_string_literal: true

require 'spec_helper'

RSpec.describe InitializerConnections do
  describe '.raise_if_new_database_connection', :reestablished_active_record_base, :delete do
    before do
      ActiveRecord::Base.connection_handler.clear_active_connections!
      ActiveRecord::Base.connection_handler.flush_idle_connections!
    end

    def block_with_database_call
      described_class.raise_if_new_database_connection do
        Project.first
      end
    end

    def block_with_error
      described_class.raise_if_new_database_connection do
        raise "oops, an error"
      end
    end

    it 'prevents any database connection within the block' do
      expect { block_with_database_call }.to raise_error(/Database connection should not be called during initializer/)
    end

    it 'prevents any database connection re-use within the block' do
      Project.connection # establish a connection first, it will be used inside the block

      expect { block_with_database_call }.to raise_error(/Database connection should not be called during initializer/)
    end

    it 'does not prevent database connection if SKIP_RAISE_ON_INITIALIZE_CONNECTIONS is set' do
      stub_env('SKIP_RAISE_ON_INITIALIZE_CONNECTIONS', '1')

      expect { block_with_database_call }.not_to raise_error
    end

    it 'prevents any database connection if SKIP_RAISE_ON_INITIALIZE_CONNECTIONS is false' do
      stub_env('SKIP_RAISE_ON_INITIALIZE_CONNECTIONS', 'false')

      expect { block_with_database_call }.to raise_error(/Database connection should not be called during initializer/)
    end

    it 'restores original connection handler' do
      original_handler = ActiveRecord::Base.connection_handler

      expect { block_with_database_call }.to raise_error(/Database connection should not be called during initializer/)

      expect(ActiveRecord::Base.connection_handler).to eq(original_handler)
    end

    it 'restores original connection handler even there is an error' do
      original_handler = ActiveRecord::Base.connection_handler

      expect { block_with_error }.to raise_error(/an error/)

      expect(ActiveRecord::Base.connection_handler).to eq(original_handler)
    end

    it 'does not raise if connection_pool is retrieved in the block' do
      # connection_pool, connection_db_config doesn't connect to database, so it's OK
      expect do
        described_class.raise_if_new_database_connection do
          ApplicationRecord.connection_pool
        end
      end.not_to raise_error

      expect do
        described_class.raise_if_new_database_connection do
          Ci::ApplicationRecord.connection_pool
        end
      end.not_to raise_error
    end
  end

  describe '.debug_database_queries' do
    let(:block_result) { 'block_executed' }

    before do
      allow(Rails.logger).to receive(:debug)
    end

    shared_examples "debugging queries" do
      it 'subscribes to active record notifications if skip is set to off' do
        expect(ActiveSupport::Notifications).to receive(:subscribed)
          .with(anything, "sql.active_record")
          .and_call_original

        described_class.debug_database_queries { block_result }
      end
    end

    shared_examples "not debugging queries" do
      it 'yields the block' do
        expect(described_class.debug_database_queries { block_result }).to eq(block_result)
      end
    end

    context 'in production mode' do
      before do
        allow(Rails.env).to receive(:production?).and_return(true)
      end

      it_behaves_like 'not debugging queries'

      context 'with SKIP_DEBUG_INITIALIZE_CONNECTIONS=off' do
        before do
          stub_env('SKIP_DEBUG_INITIALIZE_CONNECTIONS', 'off')
        end

        it_behaves_like 'debugging queries'
      end
    end

    context 'in non production mode' do
      before do
        allow(Rails.env).to receive(:production?).and_return(false)
      end

      it_behaves_like 'debugging queries'

      context 'with SKIP_DEBUG_INITIALIZE_CONNECTIONS=on' do
        before do
          stub_env('SKIP_DEBUG_INITIALIZE_CONNECTIONS', 'on')
        end

        it_behaves_like 'not debugging queries'
      end
    end
  end
end
