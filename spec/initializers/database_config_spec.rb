# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Database config initializer', :reestablished_active_record_base do
  subject do
    load Rails.root.join('config/initializers/database_config.rb')
  end

  it 'retains the correct database name for the connection' do
    previous_db_name = ApplicationRecord.connection.pool.db_config.name

    subject

    expect(ApplicationRecord.connection.pool.db_config.name).to eq(previous_db_name)
  end

  it 'does not overwrite custom pool settings' do
    expect { subject }.not_to change { ActiveRecord::Base.connection_db_config.pool }
  end
end
