# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::MigratePagesMetadata, schema: 20181228175414 do
  let(:projects) { table(:projects) }

  subject(:migrate_pages_metadata) { described_class.new }

  describe '#perform' do
    let(:namespaces) { table(:namespaces) }
    let(:builds) { table(:ci_builds) }
    let(:pages_metadata) { table(:project_pages_metadata) }

    it 'marks specified projects with successful pages deployment' do
      namespace = namespaces.create!(name: 'gitlab', path: 'gitlab-org')
      not_migrated_with_pages = projects.create!(namespace_id: namespace.id, name: 'Not Migrated With Pages')
      builds.create!(project_id: not_migrated_with_pages.id, type: 'GenericCommitStatus', status: 'success', stage: 'deploy', name: 'pages:deploy')

      migrated = projects.create!(namespace_id: namespace.id, name: 'Migrated')
      pages_metadata.create!(project_id: migrated.id, deployed: true)

      not_migrated_no_pages = projects.create!(namespace_id: namespace.id, name: 'Not Migrated No Pages')
      project_not_in_relation_scope = projects.create!(namespace_id: namespace.id, name: 'Other')

      ids = [not_migrated_no_pages.id, not_migrated_with_pages.id, migrated.id]

      migrate_pages_metadata.perform(ids.min, ids.max)

      expect(pages_metadata.find_by_project_id(not_migrated_with_pages.id).deployed).to eq(true)
      expect(pages_metadata.find_by_project_id(not_migrated_no_pages.id).deployed).to eq(false)
      expect(pages_metadata.find_by_project_id(migrated.id).deployed).to eq(true)
      expect(pages_metadata.find_by_project_id(project_not_in_relation_scope.id)).to be_nil
    end
  end
end
