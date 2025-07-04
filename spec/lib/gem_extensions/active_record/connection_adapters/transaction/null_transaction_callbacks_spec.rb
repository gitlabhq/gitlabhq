# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GemExtensions::ActiveRecord::ConnectionAdapters::Transaction::NullTransactionCallbacks, feature_category: :shared do
  describe '.after_commit' do
    let(:collection) { [] }
    let(:current_transaction) { ActiveRecord::ConnectionAdapters::NullTransaction.new }

    subject(:unit_of_work) do
      current_transaction.after_commit do
        collection << :after_commit
      end

      collection << :not_after_commit
    end

    it 'executes the given block immediately as there is no real transaction' do
      unit_of_work

      expect(collection).to eq([:after_commit, :not_after_commit])
    end
  end
end
