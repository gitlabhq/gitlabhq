# frozen_string_literal: true

require 'spec_helper'

RSpec.describe InitializerConnections do
  describe '.with_disabled_database_connections', :reestablished_active_record_base do
    def block_with_database_call
      described_class.with_disabled_database_connections do
        Project.first
      end
    end

    def block_with_error
      described_class.with_disabled_database_connections do
        raise "oops, an error"
      end
    end

    it 'prevents any database connection within the block' do
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
      # rubocop:disable Database/MultipleDatabases
      original_handler = ActiveRecord::Base.connection_handler

      expect { block_with_database_call }.to raise_error(/Database connection should not be called during initializer/)

      expect(ActiveRecord::Base.connection_handler).to eq(original_handler)
      # rubocop:enabled Database/MultipleDatabases
    end

    it 'restores original connection handler even there is an error' do
      # rubocop:disable Database/MultipleDatabases
      original_handler = ActiveRecord::Base.connection_handler

      expect { block_with_error }.to raise_error(/an error/)

      expect(ActiveRecord::Base.connection_handler).to eq(original_handler)
      # rubocop:enabled Database/MultipleDatabases
    end

    it 'raises if any new connection_pools are established in the block' do
      expect do
        described_class.with_disabled_database_connections do
          ApplicationRecord.connects_to database: { writing: :main, reading: :main }
        end
      end.to raise_error(/Unxpected connection_pools/)
    end
  end
end
