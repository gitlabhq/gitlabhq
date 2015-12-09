require 'spec_helper'

describe Gitlab::Metrics::Subscribers::ActiveRecord do
  let(:transaction) { Gitlab::Metrics::Transaction.new }

  let(:subscriber) { described_class.new }

  let(:event) do
    double(:event, duration: 0.2,
                   payload:  { sql: 'SELECT * FROM users WHERE id = 10' })
  end

  before do
    allow(subscriber).to receive(:current_transaction).and_return(transaction)

    allow(Gitlab::Metrics).to receive(:last_relative_application_frame).
      and_return(['app/models/foo.rb', 4])
  end

  describe '#sql' do
    it 'tracks the execution of a SQL query' do
      values = { duration: 0.2, file: 'app/models/foo.rb', line: 4 }
      sql    = 'SELECT * FROM users WHERE id = ?'

      expect(transaction).to receive(:add_metric).
        with(described_class::SERIES, values, sql: sql)

      subscriber.sql(event)
    end
  end
end
