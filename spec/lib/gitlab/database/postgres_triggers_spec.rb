# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::PostgresTrigger, feature_category: :database do
  include Database::DatabaseHelpers

  let(:connection) { ApplicationRecord.connection }
  let(:table_name) { 'foo' }
  let(:trigger) { create(:postgres_trigger, table_name: table_name) }

  before do
    swapout_view_for_table(:postgres_triggers, connection: connection)
  end

  describe 'scopes' do
    describe '.by_table_name' do
      it 'returns triggers for the given table in the current schema' do
        expect(described_class.by_table_name(table_name)).to include(trigger)
      end

      it 'excludes triggers from other tables' do
        create(:postgres_trigger, table_name: 'other_table', trigger_name: 'other_trigger')

        expect(described_class.by_table_name(table_name)).not_to include(
          have_attributes(table_name: 'other_table')
        )
      end

      it 'excludes triggers from other schemas' do
        other_schema_trigger = create(:postgres_trigger, table_name: table_name, schema_name: 'other_schema',
          trigger_name: 'other_trigger')

        expect(described_class.by_table_name(table_name)).not_to include(other_schema_trigger)
      end

      context 'with explicit schema_name' do
        it 'returns triggers for the given schema' do
          other_schema_trigger = create(:postgres_trigger, table_name: table_name, schema_name: 'other_schema',
            trigger_name: 'other_trigger')

          expect(described_class.by_table_name(table_name, 'other_schema')).to include(other_schema_trigger)
        end
      end
    end
  end
end
