# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe DropTemporaryColumnsAndTriggersForTaggings, feature_category: :continuous_integration do
  let(:taggings_table) { table(:taggings) }

  it 'correctly migrates up and down' do
    reversible_migration do |migration|
      migration.before -> {
        expect(taggings_table.column_names).to include('id_convert_to_bigint')
        expect(taggings_table.column_names).to include('taggable_id_convert_to_bigint')
      }

      migration.after -> {
        taggings_table.reset_column_information
        expect(taggings_table.column_names).not_to include('id_convert_to_bigint')
        expect(taggings_table.column_names).not_to include('taggable_id_convert_to_bigint')
      }
    end
  end
end
