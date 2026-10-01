# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::LockAcquisition::BlockerCensus, feature_category: :database do
  let(:connection) { ActiveRecord::Base.retrieve_connection }

  describe '.capture' do
    context 'with a session holding a conflicting lock', :delete do
      let(:blocker_pid) { blocker_connection.select_value('SELECT pg_backend_pid()') }
      let(:blocker_connection) { ActiveRecord::Base.connection_pool.checkout }

      around do |example|
        blocker_connection.begin_db_transaction
        blocker_connection.execute("LOCK TABLE #{Project.table_name} IN EXCLUSIVE MODE")

        example.run
      ensure
        blocker_connection.rollback_db_transaction
        ActiveRecord::Base.connection_pool.checkin(blocker_connection)
      end

      it 'reports the blocker for the target table', :aggregate_failures do
        payload = described_class.capture(connection, tables: [Project.table_name])

        expect(payload[:privilege_restricted_count]).to be_a(Integer)

        blocker = payload[:blockers].find { |row| row['pid'] == blocker_pid }
        expect(blocker).to be_present
        expect(blocker['lock_modes']).to include('ExclusiveLock')
        expect(blocker['xact_age_s']).to be_a(Float)
        expect(blocker['wraparound_vacuum']).to be(false)
        expect(blocker).to have_key('application')
        expect(blocker).to have_key('endpoint_id')
      end

      it 'extracts only the bounded Marginalia fields from a leading comment' do
        blocker_connection.execute(
          "/*application:test,correlation_id:abc-123,endpoint_id:Foo::Bar*/ SELECT 1"
        )

        payload = described_class.capture(connection, tables: [Project.table_name])
        blocker = payload[:blockers].find { |row| row['pid'] == blocker_pid }

        expect(blocker['application']).to eq('test')
        expect(blocker['endpoint_id']).to eq('Foo::Bar')
      end

      it 'counts only hidden sessions that hold a lock on the target tables' do
        # The test role sees every session, so a marker query stands in for
        # the text pg_stat_activity shows in place of a hidden session's query.
        marker = "SELECT 'blocker census hidden marker'"
        config = ActiveRecord::Base.connection_db_config.configuration_hash
        params = { host: config[:host], port: config[:port], dbname: config[:database],
                   user: config[:username], password: config[:password] }.compact
        unrelated = PG.connect(params)
        unrelated.exec(marker)
        visible_holder = PG.connect(params)
        visible_holder.exec('BEGIN')
        visible_holder.exec("SELECT 1 FROM #{Project.table_name} LIMIT 1") # holds AccessShareLock
        blocker_connection.raw_connection.exec(marker)
        stub_const("#{described_class}::HIDDEN_QUERY", marker)

        payload = described_class.capture(connection, tables: [Project.table_name])

        expect(payload[:privilege_restricted_count]).to eq(1)
      ensure
        unrelated&.close
        visible_holder&.close
      end

      it 'does not report the capturing session itself' do
        own_pid = connection.select_value('SELECT pg_backend_pid()')

        payload = described_class.capture(connection, tables: [Project.table_name])

        expect(payload[:blockers].map { |row| row['pid'] }).not_to include(own_pid)
      end

      it 'sees blockers that connected after the transaction first read pg_stat_activity' do
        config = ActiveRecord::Base.connection_db_config.configuration_hash
        connection.begin_db_transaction
        connection.select_value('SELECT count(*) FROM pg_stat_activity') # freezes the snapshot

        late = PG.connect(
          { host: config[:host], port: config[:port], dbname: config[:database],
            user: config[:username], password: config[:password] }.compact
        )
        late.exec('BEGIN')
        late.exec("SELECT 1 FROM #{Project.table_name} LIMIT 1") # holds AccessShareLock
        late_pid = late.backend_pid

        payload = described_class.capture(connection, tables: [Project.table_name])

        expect(payload[:blockers].map { |row| row['pid'] }).to include(late_pid)
      ensure
        late&.close
        connection.rollback_db_transaction
      end
    end

    context 'when the census query fails' do
      it 'returns an error payload instead of raising' do
        allow(connection).to receive(:select_all).and_raise(ActiveRecord::StatementInvalid, 'boom')

        payload = described_class.capture(connection, tables: ['projects'])

        expect(payload).to have_key(:census_error)
        expect(payload[:census_error]).to include('boom')
      end
    end
  end
end
