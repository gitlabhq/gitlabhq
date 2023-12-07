# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe DetectAndFixDuplicateOrganizationsPath, feature_category: :cell do
  let!(:default_organization) { table(:organizations).create!(name: 'Default', path: 'Default') }

  let(:duplicate_path_name) { 'some_path' }
  let!(:organization) { table(:organizations).create!(name: '_name_', path: duplicate_path_name) }
  let!(:organization_duplicate) { table(:organizations).create!(name: '_name_', path: duplicate_path_name.upcase) }
  let!(:organization_multiple_duplicate) do
    table(:organizations).create!(name: '_name_', path: duplicate_path_name.upcase_first)
  end

  describe '#up' do
    it 'removes the duplication', :aggregate_failures do
      expect(organization.path).to eq(duplicate_path_name)
      expect(organization_duplicate.path).to eq(duplicate_path_name.upcase)
      expect(organization_multiple_duplicate.path).to eq(duplicate_path_name.upcase_first)
      expect(default_organization.path).to eq('Default')

      migrate!

      expect(organization.reload.path).to eq(duplicate_path_name)
      expect(organization_duplicate.reload.path).to eq("#{duplicate_path_name.upcase}1")
      expect(organization_multiple_duplicate.reload.path).to eq("#{duplicate_path_name.upcase_first}2")
      expect(default_organization.reload.path).to eq('Default')
    end
  end
end
