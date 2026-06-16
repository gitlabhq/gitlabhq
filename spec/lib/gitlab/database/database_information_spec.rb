# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::DatabaseInformation, feature_category: :database do
  describe '.execute' do
    subject(:result) { described_class.execute }

    it 'returns a snapshot for the main database by default', :aggregate_failures do
      expect(result[:databases]).to have_key('main')

      payload = result[:databases]['main']
      expect(payload[:current_user]).to be_a(String).and(be_present)
      expect(payload[:search_path]).to be_a(String).and(be_present)
      expect(payload[:schemas]).to be_an(Array).and(be_present)
    end

    it 'excludes system schemas and includes public' do
      schema_names = result[:databases]['main'][:schemas].map { |s| s[:name] }

      expect(schema_names).to include('public')
      expect(schema_names).not_to include('pg_catalog', 'pg_toast', 'information_schema')
    end

    it 'normalizes the current flag to a boolean and flags exactly one schema as current', :aggregate_failures do
      schemas = result[:databases]['main'][:schemas]
      current_schema_name = ApplicationRecord.connection.select_value('SELECT current_schema()')

      schemas.each { |s| expect(s[:current]).to be_in([true, false]) }

      current = schemas.select { |s| s[:current] }
      expect(current.size).to eq(1)
      expect(current.first[:name]).to eq(current_schema_name)
    end

    it 'includes the schema owner for each schema' do
      result[:databases]['main'][:schemas].each do |schema|
        expect(schema[:owner]).to be_a(String).and(be_present)
      end
    end

    context 'when a database name does not map to a known model' do
      subject(:result) { described_class.execute(database_names: %w[bogus]) }

      it 'returns an error payload for that database' do
        expect(result[:databases]['bogus']).to eq(error: 'Unknown database: bogus')
      end
    end

    context 'when the connection raises an error' do
      let(:failing_model) { class_double(ApplicationRecord) }
      let(:error) { StandardError.new('PG::ConnectionBad: could not connect to host db.internal:5432') }

      before do
        allow(Gitlab::Database).to receive(:database_base_models)
          .and_return({ 'main' => failing_model })
        allow(failing_model).to receive(:connection).and_raise(error)
      end

      it 'returns a sanitized error payload and tracks the exception', :aggregate_failures do
        expect(Gitlab::ErrorTracking).to receive(:track_exception).with(error, database_name: 'main')

        expect(result[:databases]['main']).to eq(error: 'Failed to gather information for database: main')
      end
    end
  end
end
