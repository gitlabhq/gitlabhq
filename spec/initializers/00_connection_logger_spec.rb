# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ActiveRecord::ConnectionAdapters::PostgreSQLAdapter do # rubocop:disable RSpec/FilePath
  before do
    allow(PG).to receive(:connect)
  end

  let(:conn_params) { PG::Connection.conndefaults_hash }

  context 'when warn_on_new_connection is enabled' do
    before do
      described_class.warn_on_new_connection = true
    end

    it 'warns on new connection' do
      expect(ActiveSupport::Deprecation)
        .to receive(:warn).with(/Database connection should not be called during initializers/, anything)

      expect(PG).to receive(:connect).with(conn_params)

      described_class.new_client(conn_params)
    end
  end

  context 'when warn_on_new_connection is disabled' do
    before do
      described_class.warn_on_new_connection = false
    end

    it 'does not warn on new connection' do
      expect(ActiveSupport::Deprecation).not_to receive(:warn)
      expect(PG).to receive(:connect).with(conn_params)

      described_class.new_client(conn_params)
    end
  end
end
