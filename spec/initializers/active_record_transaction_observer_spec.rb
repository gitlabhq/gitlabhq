# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'ActiveRecord Transaction Observer', feature_category: :cloud_connector do
  def load_initializer
    load Rails.root.join('config/initializers/active_record_transaction_observer.rb')
  end

  context 'when DBMS is available' do
    before do
      allow_next_instance_of(ActiveRecord::Base.connection) do |connection| # rubocop:disable Database/MultipleDatabases
        allow(connection).to receive(:active?).and_return(true)
      end
    end

    it 'calls Gitlab::Database::Transaction::Observer' do
      allow(Feature::FlipperFeature).to receive(:table_exists?).and_return(true)

      expect(Gitlab::Database::Transaction::Observer).to receive(:register!)

      load_initializer
    end

    context 'when flipper table does not exist' do
      before do
        allow(Feature::FlipperFeature).to receive(:table_exists?).and_raise(ActiveRecord::NoDatabaseError)
      end

      it 'does not calls Gitlab::Database::Transaction::Observer' do
        expect(Gitlab::Database::Transaction::Observer).not_to receive(:register!)

        load_initializer
      end
    end
  end

  context 'when DBMS is not available' do
    before do
      allow(ActiveRecord::Base).to receive(:connection).and_raise(PG::ConnectionBad)
    end

    it 'does not calls Gitlab::Database::Transaction::Observer' do
      expect(Gitlab::Database::Transaction::Observer).not_to receive(:register!)

      load_initializer
    end
  end
end
