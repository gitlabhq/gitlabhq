# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe DeleteOrphanedProjectGroupLinks, feature_category: :groups_and_projects do
  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:project_group_links) { table(:project_group_links) }
  let(:connection) { ApplicationRecord.connection }

  let!(:organization) { organizations.create!(path: 'test-org') }
  let!(:group) do
    namespaces.create!(name: 'group', path: 'group', type: 'Group', organization_id: organization.id)
  end

  let!(:shared_with_group) do
    namespaces.create!(name: 'shared', path: 'shared', type: 'Group', organization_id: organization.id)
  end

  let!(:user_namespace) do
    namespaces.create!(name: 'user', path: 'user', type: 'User', organization_id: organization.id)
  end

  let!(:project_namespace) do
    namespaces.create!(name: 'project-ns', path: 'project-ns', type: 'Project',
      organization_id: organization.id)
  end

  let!(:project) do
    projects.create!(name: 'project', namespace_id: group.id, project_namespace_id: group.id,
      organization_id: organization.id)
  end

  let!(:valid_link) { project_group_links.create!(project_id: project.id, group_id: shared_with_group.id) }
  let!(:user_namespace_link) { project_group_links.create!(project_id: project.id, group_id: user_namespace.id) }
  let!(:missing_namespace_link) do
    without_foreign_key do
      project_group_links.create!(project_id: project.id, group_id: non_existing_record_id)
    end
  end

  let!(:project_namespace_link) do
    project_group_links.create!(project_id: project.id, group_id: project_namespace.id)
  end

  describe '#up' do
    it 'deletes the links whose group_id does not reference a group' do
      migrate!

      expect(project_group_links.pluck(:id)).to contain_exactly(valid_link.id)
    end

    context 'when links span multiple batches' do
      before do
        stub_const("#{described_class}::BATCH_SIZE", 1)
      end

      it 'skips batches that contain only valid links' do
        migrate!

        expect(project_group_links.pluck(:id)).to contain_exactly(valid_link.id)
      end
    end
  end

  # fk_28a1244b01 (group_id -> namespaces.id) is enforced on insert even as NOT VALID, so drop it to
  # insert an orphan, then restore it NOT VALID without validating the orphan.
  def without_foreign_key
    connection.execute('ALTER TABLE project_group_links DROP CONSTRAINT IF EXISTS fk_28a1244b01')
    yield
  ensure
    connection.execute(<<~SQL)
      ALTER TABLE project_group_links
        ADD CONSTRAINT fk_28a1244b01 FOREIGN KEY (group_id) REFERENCES namespaces(id) ON DELETE CASCADE NOT VALID
    SQL
  end
end
