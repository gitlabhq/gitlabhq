# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillProjectNamespaceDetails, :migration do
  let!(:namespace_details) { table(:namespace_details) }
  let!(:namespaces) { table(:namespaces) }
  let!(:projects) { table(:projects) }

  subject(:perform_migration) do
    described_class.new(
      start_id: projects.minimum(:id),
      end_id: projects.maximum(:id),
      batch_table: :projects,
      batch_column: :id,
      sub_batch_size: 2,
      pause_ms: 0,
      connection: ActiveRecord::Base.connection
    ).perform
  end

  describe '#perform' do
    it 'creates details for all project namespaces in range' do
      namespaces.create!(
        id: 5, name: 'test1', path: 'test1', description: "Some description1",
        description_html: "Some description html1", cached_markdown_version: 4
      )
      project_namespace1 = namespaces.create!(id: 6, name: 'test2', path: 'test2', type: 'Project')
      namespaces.create!(
        id: 7, name: 'test3', path: 'test3', description: "Some description3",
        description_html: "Some description html3", cached_markdown_version: 4
      )
      project_namespace2 = namespaces.create!(id: 8, name: 'test4', path: 'test4', type: 'Project')

      project1 = projects.create!(
        namespace_id: project_namespace1.id, name: 'gitlab1', path: 'gitlab1',
        project_namespace_id: project_namespace1.id, description: "Some description2",
        description_html: "Some description html2", cached_markdown_version: 4
      )
      project2 = projects.create!(
        namespace_id: project_namespace2.id, name: 'gitlab2', path: 'gitlab2',
        project_namespace_id: project_namespace2.id,
        description: "Some description3",
        description_html: "Some description html4", cached_markdown_version: 4
      )

      namespace_details.delete_all

      expect(namespace_details.pluck(:namespace_id)).to eql []

      expect { perform_migration }
        .to change { namespace_details.pluck(:namespace_id) }.from([]).to contain_exactly(
          project_namespace1.id,
          project_namespace2.id
        )

      expect(namespace_details.find_by_namespace_id(project_namespace1.id))
        .to have_attributes(migrated_attributes(project1))
      expect(namespace_details.find_by_namespace_id(project_namespace2.id))
        .to have_attributes(migrated_attributes(project2))
    end
  end

  def migrated_attributes(project)
    {
      description: project.description,
      description_html: project.description_html,
      cached_markdown_version: project.cached_markdown_version
    }
  end
end
