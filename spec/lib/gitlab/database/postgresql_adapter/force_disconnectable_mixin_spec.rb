# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::PostgresqlAdapter::ForceDisconnectableMixin, :delete, :reestablished_active_record_base do
  describe 'checking in a connection to the pool' do
    let(:model) do
      Class.new(ActiveRecord::Base) do
        self.abstract_class = true

        def self.name
          'ForceDisconnectTestModel'
        end
      end
    end

    let(:config) { ActiveRecord::Base.configurations.find_db_config(Rails.env).configuration_hash.merge(pool: 1) }
    let(:pool) do
      model.establish_connection(ActiveRecord::DatabaseConfigurations::HashConfig.new(Rails.env, 'main', config))
    end

    it 'calls the force disconnect callback on checkin' do
      connection = pool.connection

      expect(pool.active_connection?).to be_truthy
      expect(connection).to receive(:force_disconnect_if_old!).and_call_original

      model.clear_active_connections!
    end
  end

  describe 'disconnecting from the database' do
    let(:connection) { ActiveRecord::Base.connection_pool.connection }
    let(:timer) { connection.force_disconnect_timer }

    context 'when the timer is expired' do
      before do
        allow(timer).to receive(:expired?).and_return(true)
      end

      it 'disconnects from the database' do
        expect(connection).to receive(:disconnect!).and_call_original
        expect(timer).to receive(:reset!).and_call_original

        connection.force_disconnect_if_old!
      end

      context 'when the connection has an open transaction' do
        it 'does not disconnect from the database' do
          connection.begin_transaction

          expect(connection).not_to receive(:disconnect!)
          expect(timer).not_to receive(:reset!)

          connection.force_disconnect_if_old!

          connection.rollback_transaction
        end
      end
    end

    context 'when the timer is not expired' do
      it 'does not disconnect from the database' do
        allow(timer).to receive(:expired?).and_return(false)

        expect(connection).not_to receive(:disconnect!)
        expect(timer).not_to receive(:reset!)

        connection.force_disconnect_if_old!
      end
    end
  end
end
