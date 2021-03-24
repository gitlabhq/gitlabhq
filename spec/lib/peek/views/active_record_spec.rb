# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Peek::Views::ActiveRecord, :request_store do
  subject { Peek.views.find { |v| v.instance_of?(Peek::Views::ActiveRecord) } }

  let(:connection_1) { double(:connection) }
  let(:connection_2) { double(:connection) }
  let(:connection_3) { double(:connection) }

  let(:event_1) do
    {
      name: 'SQL',
      sql: 'SELECT * FROM users WHERE id = 10',
      cached: false,
      connection: connection_1
    }
  end

  let(:event_2) do
    {
      name: 'SQL',
      sql: 'SELECT * FROM users WHERE id = 10',
      cached: true,
      connection: connection_2
    }
  end

  let(:event_3) do
    {
      name: 'SQL',
      sql: 'UPDATE users SET admin = true WHERE id = 10',
      cached: false,
      connection: connection_3
    }
  end

  before do
    allow(Gitlab::PerformanceBar).to receive(:enabled_for_request?).and_return(true)
    allow(connection_1).to receive(:transaction_open?).and_return(false)
    allow(connection_2).to receive(:transaction_open?).and_return(false)
    allow(connection_3).to receive(:transaction_open?).and_return(true)
  end

  it 'subscribes and store data into peek views' do
    Timecop.freeze(2021, 2, 23, 10, 0) do
      ActiveSupport::Notifications.publish('sql.active_record', Time.current, Time.current + 1.second, '1', event_1)
      ActiveSupport::Notifications.publish('sql.active_record', Time.current, Time.current + 2.seconds, '2', event_2)
      ActiveSupport::Notifications.publish('sql.active_record', Time.current, Time.current + 3.seconds, '3', event_3)
    end

    expect(subject.results).to match(
      calls: 3,
      summary: {
        "Cached" => 1,
        "In a transaction" => 1
      },
      duration: '6000.00ms',
      warnings: ["active-record duration: 6000.0 over 3000"],
      details: contain_exactly(
        a_hash_including(
          start: be_a(Time),
          cached: '',
          transaction: '',
          duration: 1000.0,
          sql: 'SELECT * FROM users WHERE id = 10'
        ),
        a_hash_including(
          start: be_a(Time),
          cached: 'Cached',
          transaction: '',
          duration: 2000.0,
          sql: 'SELECT * FROM users WHERE id = 10'
        ),
        a_hash_including(
          start: be_a(Time),
          cached: '',
          transaction: 'In a transaction',
          duration: 3000.0,
          sql: 'UPDATE users SET admin = true WHERE id = 10'
        )
      )
    )
  end
end
