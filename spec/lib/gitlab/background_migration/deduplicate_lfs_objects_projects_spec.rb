# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::DeduplicateLfsObjectsProjects, feature_category: :source_code_management do
  let(:projects_table) { table(:projects) }
  let(:lfs_objects_table) { table(:lfs_objects) }
  let(:lfs_objects_projects_table) { table(:lfs_objects_projects) }
  let(:lfs_object_size) { 20 }

  let(:organization) { table(:organizations).create!(name: 'organization', path: 'organization') }

  let(:namespace1) { table(:namespaces).create!(name: 'ns1', path: 'ns1', organization_id: organization.id) }
  let(:namespace2) { table(:namespaces).create!(name: 'ns2', path: 'ns2', organization_id: organization.id) }
  let(:namespace3) { table(:namespaces).create!(name: 'ns3', path: 'ns3', organization_id: organization.id) }

  # rubocop:disable Layout/LineLength -- easier to read in single line
  let(:project1) { projects_table.create!(namespace_id: namespace1.id, project_namespace_id: namespace1.id, organization_id: organization.id) }
  let(:project2) { projects_table.create!(namespace_id: namespace2.id, project_namespace_id: namespace2.id, organization_id: organization.id) }
  let(:project3) { projects_table.create!(namespace_id: namespace3.id, project_namespace_id: namespace3.id, organization_id: organization.id) }
  # rubocop:enable Layout/LineLength

  let(:lfs_object1) do
    lfs_objects_table.create!(
      oid: 'f2b0a1e7550e9b718dafc9b525a04879a766de62e4fbdfc46593d47f7ab74636',
      size: lfs_object_size
    )
  end

  let(:lfs_object2) do
    lfs_objects_table.create!(
      oid: '004409da2260f89ceaf6d7cd13cbdfdeeeb43b6c1705299e96efbaa659805785',
      size: lfs_object_size
    )
  end

  let(:lfs_object3) do
    lfs_objects_table.create!(
      oid: 'c4c65374aa473c94e81810fbb0adb861292661eeb677a197a19a18e52e8eab9c',
      size: lfs_object_size
    )
  end

  let(:lfs_object4) do
    lfs_objects_table.create!(
      oid: '7736b17f9fff13bb54b10738acc03daa6c0867b22d29a5f9430cd97a47ebb6a4',
      size: lfs_object_size
    )
  end

  let(:lfs_object5) do
    lfs_objects_table.create!(
      oid: '96f74c6fe7a2979eefb9ec74a5dfc6888fb25543cf99b77586b79afea1da6f97',
      size: lfs_object_size
    )
  end

  let(:lfs_object6) do
    lfs_objects_table.create!(
      oid: '47997ea7ecff33be61e3ca1cc287ee72a2125161518f1a169f2893a5a82e9d95',
      size: lfs_object_size
    )
  end

  let!(:duplicated_lfs_objects_project1) do
    lfs_objects_projects_table.create!(project_id: project1.id, lfs_object_id: lfs_object1.id, repository_type: 0)
  end

  let!(:lfs_objects_project2) do
    lfs_objects_projects_table.create!(project_id: project1.id, lfs_object_id: lfs_object1.id, repository_type: 0)
  end

  let!(:duplicated_lfs_objects_project3) do
    lfs_objects_projects_table.create!(project_id: project2.id, lfs_object_id: lfs_object4.id, repository_type: nil)
  end

  let!(:duplicated_lfs_objects_project4) do
    lfs_objects_projects_table.create!(project_id: project2.id, lfs_object_id: lfs_object4.id, repository_type: nil)
  end

  let!(:lfs_objects_project5) do
    lfs_objects_projects_table.create!(project_id: project2.id, lfs_object_id: lfs_object4.id, repository_type: nil)
  end

  let!(:lfs_objects_project6) do
    lfs_objects_projects_table.create!(project_id: project3.id, lfs_object_id: lfs_object6.id, repository_type: 1)
  end

  let(:migration_attrs) do
    {
      start_id: projects_table.minimum(:id),
      end_id: projects_table.maximum(:id),
      batch_table: :lfs_objects_projects,
      batch_column: :project_id,
      sub_batch_size: 3,
      pause_ms: 100,
      connection: ApplicationRecord.connection
    }
  end

  subject(:migration) { described_class.new(**migration_attrs) }

  describe '#perform' do
    context 'with duplicates' do
      it 'deduplicates lfs_objects_projects by lfs_object_id, repository_type and project_id' do
        expect { migration.perform }.to change { lfs_objects_projects_table.count }.from(6).to(3)

        expect(lfs_objects_projects_table.all)
          .to contain_exactly(lfs_objects_project2, lfs_objects_project5, lfs_objects_project6)
      end
    end

    context 'without duplicates' do
      it 'does not delete any records' do
        [
          duplicated_lfs_objects_project1,
          duplicated_lfs_objects_project3,
          duplicated_lfs_objects_project4
        ].each(&:destroy)

        expect { migration.perform }.not_to change { lfs_objects_table.count }
      end
    end
  end
end
