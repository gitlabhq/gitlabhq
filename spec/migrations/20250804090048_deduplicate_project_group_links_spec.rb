# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe DeduplicateProjectGroupLinks, feature_category: :groups_and_projects do
  let(:organizations) { table(:organizations) }
  let(:projects) { table(:projects) }
  let(:namespaces) { table(:namespaces) }
  let(:project_group_links) { table(:project_group_links) }

  let(:organization) { organizations.create!(name: 'test-org', path: 'test-org') }

  let!(:project_parent) { create_group('project-parent') }
  let!(:group_1) { create_group('test-group-1') }
  let!(:group_2) { create_group('test-group-2') }
  let!(:group_3) { create_group('test-group-3') }

  let!(:project_1) { create_project('test-project-1') }
  let!(:project_2) { create_project('test-project-2') }
  let!(:project_3) { create_project('test-project-3') }

  describe '#up' do
    context 'when there are duplicate project_group_links' do
      let!(:link_1_1) do
        project_group_links.create!(
          project_id: project_1.id,
          group_id: group_1.id,
          group_access: 10
        )
      end

      let!(:link_1_1_duplicate) do
        project_group_links.create!(
          project_id: project_1.id,
          group_id: group_1.id,
          group_access: 20
        )
      end

      let!(:link_1_1_duplicate_2) do
        project_group_links.create!(
          project_id: project_1.id,
          group_id: group_1.id,
          group_access: 30
        )
      end

      it 'removes duplicates keeping only the one with highest id' do
        schema_migrate_up!

        expect(project_group_links.where(project_id: project_1.id, group_id: group_1.id).count).to eq(1)
        expect(project_group_links.where(project_id: project_1.id, group_id: group_1.id).first.id)
          .to eq(link_1_1_duplicate_2.id)
      end
    end

    context 'when there are multiple sets of duplicates' do
      let!(:link_1_1) do
        project_group_links.create!(
          project_id: project_1.id,
          group_id: group_1.id,
          group_access: 10
        )
      end

      let!(:link_1_1_duplicate) do
        project_group_links.create!(
          project_id: project_1.id,
          group_id: group_1.id,
          group_access: 20
        )
      end

      let!(:link_2_2) do
        project_group_links.create!(
          project_id: project_2.id,
          group_id: group_2.id,
          group_access: 10
        )
      end

      let!(:link_2_2_duplicate) do
        project_group_links.create!(
          project_id: project_2.id,
          group_id: group_2.id,
          group_access: 20
        )
      end

      it 'removes all sets of duplicates' do
        schema_migrate_up!

        expect(project_group_links.where(project_id: project_1.id, group_id: group_1.id).count).to eq(1)
        expect(project_group_links.where(project_id: project_1.id, group_id: group_1.id).first.id)
          .to eq(link_1_1_duplicate.id)

        expect(project_group_links.where(project_id: project_2.id, group_id: group_2.id).count).to eq(1)
        expect(project_group_links.where(project_id: project_2.id, group_id: group_2.id).first.id)
          .to eq(link_2_2_duplicate.id)
      end
    end

    context 'when there are no duplicates' do
      let!(:link_1_1) do
        project_group_links.create!(
          project_id: project_1.id,
          group_id: group_1.id,
          group_access: 10
        )
      end

      let!(:link_1_2) do
        project_group_links.create!(
          project_id: project_1.id,
          group_id: group_2.id,
          group_access: 20
        )
      end

      let!(:link_2_1) do
        project_group_links.create!(
          project_id: project_2.id,
          group_id: group_1.id,
          group_access: 30
        )
      end

      it 'preserves all unique links' do
        expect(project_group_links.count).to eq(3)

        schema_migrate_up!

        expect(project_group_links.count).to eq(3)
        expect(project_group_links.pluck(:id)).to contain_exactly(link_1_1.id, link_1_2.id, link_2_1.id)
      end
    end

    context 'when there is a mix of duplicates and unique links' do
      let!(:link_1_1) do
        project_group_links.create!(
          project_id: project_1.id,
          group_id: group_1.id,
          group_access: 10
        )
      end

      let!(:link_1_1_duplicate) do
        project_group_links.create!(
          project_id: project_1.id,
          group_id: group_1.id,
          group_access: 20
        )
      end

      let!(:link_1_2) do
        project_group_links.create!(
          project_id: project_1.id,
          group_id: group_2.id,
          group_access: 30
        )
      end

      let!(:link_2_3) do
        project_group_links.create!(
          project_id: project_2.id,
          group_id: group_3.id,
          group_access: 40
        )
      end

      it 'removes only the duplicates' do
        schema_migrate_up!

        expect(project_group_links.count).to eq(3)
        expect(project_group_links.where(project_id: project_1.id, group_id: group_1.id).count).to eq(1)
        expect(project_group_links.where(project_id: project_1.id, group_id: group_1.id).first.id)
          .to eq(link_1_1_duplicate.id)
        expect(project_group_links.pluck(:id)).to contain_exactly(link_1_1_duplicate.id, link_1_2.id, link_2_3.id)
      end
    end
  end

  private

  def create_group(path)
    namespaces.create!(
      name: path,
      path: path,
      type: 'Group',
      organization_id: organization.id
    )
  end

  def create_project_namespace(path)
    namespaces.create!(
      name: path,
      path: path,
      type: 'Project',
      organization_id: organization.id
    )
  end

  def create_project(path)
    project_namespace = create_project_namespace(path)
    projects.create!(
      name: path,
      path: path,
      namespace_id: project_parent.id,
      project_namespace_id: project_namespace.id,
      organization_id: organization.id
    )
  end
end
