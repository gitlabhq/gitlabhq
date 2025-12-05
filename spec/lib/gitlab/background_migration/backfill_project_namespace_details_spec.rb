# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillProjectNamespaceDetails, feature_category: :groups_and_projects do
  let!(:organizations) { table(:organizations) }
  let!(:namespace_details) { table(:namespace_details) }
  let!(:namespaces) { table(:namespaces) }
  let!(:projects) { table(:projects) }

  let!(:organization) { organizations.create!(name: 'Org 1', path: 'org-1') }

  let!(:namespace1) do
    namespaces.create!(
      id: 5,
      organization_id: organization.id,
      name: 'test1',
      path: 'test1',
      description: "Some description1",
      description_html: "Some description html1",
      cached_markdown_version: 4
    )
  end

  let!(:project_namespace1) do
    namespaces.create!(
      id: 6,
      organization_id: organization.id,
      name: 'test2',
      path: 'test2',
      type: 'Project'
    )
  end

  let!(:project1) do
    projects.create!(
      namespace_id: project_namespace1.id,
      organization_id: organization.id,
      name: 'gitlab1',
      path: 'gitlab1',
      project_namespace_id: project_namespace1.id,
      description: "Some description2",
      description_html: "Some description html2",
      cached_markdown_version: 4
    )
  end

  let!(:project_namespace2) do
    namespaces.create!(
      id: 8,
      organization_id: organization.id,
      name: 'test4',
      path: 'test4',
      type: 'Project'
    )
  end

  let!(:project2) do
    projects.create!(
      namespace_id: project_namespace2.id,
      organization_id: organization.id,
      name: 'gitlab2',
      path: 'gitlab2',
      project_namespace_id: project_namespace2.id,
      description: "Some description3",
      description_html: "Some description html4",
      cached_markdown_version: 4
    )
  end

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
    context 'when project has no namespace details' do
      before do
        namespace_details.delete_all
      end

      it 'creates details for all project namespaces in range' do
        expect { perform_migration }
          .to change { namespace_details.pluck(:namespace_id) }.from([]).to contain_exactly(
            project_namespace1.id,
            project_namespace2.id
          )

        expect(find_details(project_namespace1)).to have_attributes(migrated_attributes(project1))
        expect(find_details(project_namespace2)).to have_attributes(migrated_attributes(project2))
      end
    end

    context 'when project has existing namespace details' do
      before do
        find_details(project_namespace1).update!(description: '', description_html: '', cached_markdown_version: 0)
      end

      it 'updates existing namespace details with project data' do
        expect { perform_migration }
          .to not_change { namespace_details.count }

        expect(find_details(project_namespace1)).to have_attributes(migrated_attributes(project1))
      end
    end
  end

  def migrated_attributes(project)
    {
      description: project.description,
      description_html: project.description_html,
      cached_markdown_version: project.cached_markdown_version
    }
  end

  def find_details(namespace)
    namespace_details.find_by(namespace_id: namespace.id)
  end
end
