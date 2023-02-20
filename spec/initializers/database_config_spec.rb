# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Database config initializer', :reestablished_active_record_base do
  subject do
    load Rails.root.join('config/initializers/database_config.rb')
  end

  shared_examples 'does not change connection attributes' do
    it 'retains the correct database name for connection' do
      previous_db_name = database_base_model.connection.pool.db_config.name

      subject

      expect(database_base_model.connection.pool.db_config.name).to eq(previous_db_name)
    end

    it 'does not overwrite custom pool settings' do
      expect { subject }.not_to change { database_base_model.connection_db_config.pool }
    end
  end

  context 'when main database connection' do
    let(:database_base_model) { Gitlab::Database.database_base_models[:main] }

    it_behaves_like 'does not change connection attributes'
  end

  context 'when ci database connection' do
    before do
      skip_if_multiple_databases_not_setup(:ci)
    end

    let(:database_base_model) { Gitlab::Database.database_base_models[:ci] }

    it_behaves_like 'does not change connection attributes'
  end
end
