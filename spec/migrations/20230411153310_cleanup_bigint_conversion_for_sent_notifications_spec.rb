# frozen_string_literal: true

require 'spec_helper'
require_migration!('cleanup_bigint_conversion_for_sent_notifications')

RSpec.describe CleanupBigintConversionForSentNotifications, feature_category: :database do
  let(:sent_notifications) { table(:sent_notifications) }

  it 'correctly migrates up and down' do
    reversible_migration do |migration|
      migration.before -> {
        expect(sent_notifications.column_names).to include('id_convert_to_bigint')
      }

      migration.after -> {
        sent_notifications.reset_column_information
        expect(sent_notifications.column_names).not_to include('id_convert_to_bigint')
      }
    end
  end
end
