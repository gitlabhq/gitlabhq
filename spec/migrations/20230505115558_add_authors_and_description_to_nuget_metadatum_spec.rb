# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe AddAuthorsAndDescriptionToNugetMetadatum, feature_category: :package_registry do
  let(:metadatum) { table(:packages_nuget_metadata) }

  it 'correctly migrates up and down' do
    reversible_migration do |migration|
      migration.before -> {
        expect(metadatum.column_names).not_to include('authors')
        expect(metadatum.column_names).not_to include('description')
      }

      migration.after -> {
        metadatum.reset_column_information

        expect(metadatum.column_names).to include('authors')
        expect(metadatum.column_names).to include('description')
      }
    end
  end
end
