# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe DeleteProjectImportDataWithoutProjectId, feature_category: :importers do
  let!(:namespace) { table(:namespaces).create!(name: 'namespace', path: 'namespace') }
  let!(:project_import_data_table) { table(:project_import_data) }
  let!(:project) { table(:projects).create!(namespace_id: namespace.id, project_namespace_id: namespace.id) }

  let!(:project_import_data_without_project) { project_import_data_table.create!(project_id: nil) }
  let!(:project_import_data_with_project) { project_import_data_table.create!(project_id: project.id) }

  describe '#up' do
    it 'deletes project_import_data without a project_id' do
      migrate!

      expect(project_import_data_table.where(project_id: nil)).to be_empty
      expect(project_import_data_table.where(project_id: project.id)).not_to be_empty
    end
  end
end
