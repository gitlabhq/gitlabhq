require 'spec_helper'

describe Gitlab::QueryLimiting::ActiveSupportSubscriber do
  describe '#sql' do
    it 'increments the number of executed SQL queries' do
      transaction = double(:transaction)

      allow(Gitlab::QueryLimiting::Transaction)
        .to receive(:current)
        .and_return(transaction)

      expect(transaction)
        .to receive(:increment)
        .at_least(:once)

      User.count
    end
  end
end
