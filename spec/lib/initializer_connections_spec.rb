# frozen_string_literal: true

require 'spec_helper'

RSpec.describe InitializerConnections do
  describe '.raise_if_new_database_connection', :reestablished_active_record_base do
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
end
