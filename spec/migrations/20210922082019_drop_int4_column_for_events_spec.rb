# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe DropInt4ColumnForEvents, feature_category: :user_profile do
  let(:events) { table(:events) }

  it 'correctly migrates up and down' do
    reversible_migration do |migration|
      migration.before -> {
        expect(events.column_names).to include('id_convert_to_bigint')
      }

      migration.after -> {
        events.reset_column_information
        expect(events.column_names).not_to include('id_convert_to_bigint')
      }
    end
  end
end
