# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Patch::PostgresqlAdapterReturningValues, feature_category: :database do
  let(:connection) { ApplicationRecord.connection }

  let(:model) do
    Class.new(ApplicationRecord) do
      self.table_name = '_test_returning_values'
    end
  end

  before do
    allow(Gitlab::Runtime).to receive(:application?).and_return(true)

    connection.execute(<<~SQL)
      CREATE TABLE _test_returning_values (
        id bigserial PRIMARY KEY,
        name text
      )
    SQL
  end

  after do
    connection.execute('DROP TABLE IF EXISTS _test_returning_values')
  end

  def payload_for(sql_fragment)
    payloads = []

    subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |event|
      payloads << event.payload if event.payload[:sql]&.include?(sql_fragment)
    end

    yield

    payloads.first
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber)
  end

  it 'exposes values from INSERT ... RETURNING in the notification payload' do
    sql = "INSERT INTO _test_returning_values (name) VALUES ('a'), ('b') RETURNING id, name"

    payload = payload_for('RETURNING id, name') { connection.execute(sql) }

    expect(payload[:returned_values]).to eq(
      fields: %w[id name],
      values: [[1, 'a'], [2, 'b']]
    )
  end

  it 'exposes the id returned for an ActiveRecord create' do
    payload = payload_for('INSERT INTO "_test_returning_values"') { model.create!(name: 'a') }

    expect(payload[:returned_values]).to eq(fields: %w[id], values: [[1]])
  end

  context 'when not running in an application context' do
    before do
      allow(Gitlab::Runtime).to receive(:application?).and_return(false)
    end

    it 'does not add returned_values and does not consult the feature flag' do
      expect(Gitlab::Database::Capture).not_to receive(:enabled?)

      sql = "INSERT INTO _test_returning_values (name) VALUES ('a') RETURNING id"
      payload = payload_for('RETURNING id') { connection.execute(sql) }

      expect(payload).not_to have_key(:returned_values)
    end
  end

  context 'when the database_capture feature flag is disabled' do
    before do
      stub_feature_flags(database_capture: false)
    end

    it 'does not add returned_values' do
      sql = "INSERT INTO _test_returning_values (name) VALUES ('a') RETURNING id"

      payload = payload_for('RETURNING id') { connection.execute(sql) }

      expect(payload).not_to have_key(:returned_values)
    end
  end

  it 'does not add returned_values for statements without RETURNING' do
    sql = "INSERT INTO _test_returning_values (name) VALUES ('a')"

    payload = payload_for('_test_returning_values (name)') { connection.execute(sql) }

    expect(payload).not_to have_key(:returned_values)
  end

  it 'does not add returned_values for reads' do
    payload = payload_for('FROM _test_returning_values') do
      connection.execute('SELECT * FROM _test_returning_values')
    end

    expect(payload).not_to have_key(:returned_values)
  end

  it 'does not interfere with failing statements' do
    sql = 'INSERT INTO _test_returning_values (missing) VALUES (1) RETURNING id'

    expect do
      # A savepoint keeps the aborted statement from poisoning the
      # transaction wrapping the example, so cleanup can still run.
      connection.transaction(requires_new: true) do
        connection.execute(sql)
      end
    end.to raise_error(ActiveRecord::StatementInvalid)
  end
end
