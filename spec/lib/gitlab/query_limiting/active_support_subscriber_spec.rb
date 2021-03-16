# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::QueryLimiting::ActiveSupportSubscriber do
  let(:transaction) { instance_double(Gitlab::QueryLimiting::Transaction, executed_sql: true, increment: true) }

  before do
    allow(Gitlab::QueryLimiting::Transaction)
      .to receive(:current)
      .and_return(transaction)
  end

  describe '#sql' do
    it 'increments the number of executed SQL queries' do
      User.count

      expect(transaction)
        .to have_received(:increment)
        .once

      expect(transaction)
        .to have_received(:executed_sql)
        .once
        .with(String)
    end

    context 'when the query is actually a rails cache hit' do
      it 'does not increment the number of executed SQL queries' do
        ActiveRecord::Base.connection.cache do
          User.count
          User.count
        end

        expect(transaction)
          .to have_received(:increment)
          .once

        expect(transaction)
          .to have_received(:executed_sql)
          .once
          .with(String)
      end
    end
  end
end
