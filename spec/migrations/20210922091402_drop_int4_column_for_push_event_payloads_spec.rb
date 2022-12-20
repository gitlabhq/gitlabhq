# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe DropInt4ColumnForPushEventPayloads, feature_category: :users do
  let(:push_event_payloads) { table(:push_event_payloads) }

  it 'correctly migrates up and down' do
    reversible_migration do |migration|
      migration.before -> {
        expect(push_event_payloads.column_names).to include('event_id_convert_to_bigint')
      }

      migration.after -> {
        push_event_payloads.reset_column_information
        expect(push_event_payloads.column_names).not_to include('event_id_convert_to_bigint')
      }
    end
  end
end
