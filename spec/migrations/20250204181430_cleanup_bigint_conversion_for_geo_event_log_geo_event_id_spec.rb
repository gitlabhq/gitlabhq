# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe CleanupBigintConversionForGeoEventLogGeoEventId, feature_category: :geo_replication do
  let(:geo_event_log) { table(:geo_event_log) }

  it 'correctly migrates up and down' do
    reversible_migration do |migration|
      migration.before -> {
        expect(geo_event_log.column_names).to include('geo_event_id_convert_to_bigint')
      }

      migration.after -> {
        geo_event_log.reset_column_information
        expect(geo_event_log.column_names).not_to include('geo_event_id_convert_to_bigint')
      }
    end
  end
end
