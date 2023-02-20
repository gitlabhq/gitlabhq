# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe CopyClickhouseConnectionStringToEncryptedVar, feature_category: :product_analytics do
  let!(:migration) { described_class.new }
  let(:setting) { table(:application_settings).create!(clickhouse_connection_string: 'https://example.com/test') }

  it 'copies the clickhouse_connection_string to the encrypted column' do
    expect(setting.clickhouse_connection_string).to eq('https://example.com/test')

    migrate!

    setting.reload
    expect(setting.clickhouse_connection_string).to eq('https://example.com/test')
    expect(setting.encrypted_product_analytics_clickhouse_connection_string).not_to be_nil
  end
end
