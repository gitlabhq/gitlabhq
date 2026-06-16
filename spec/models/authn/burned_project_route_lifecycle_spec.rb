# frozen_string_literal: true

require 'spec_helper'

# Asserts that `burned_project_routes` is populated whenever a project path is
# vacated through one of the supported lifecycle flows. This is the security
# guarantee that backs Gitlab::Ci::JwtV2's burn check.
RSpec.describe 'Burned project route lifecycle', :sidekiq_inline,
  feature_category: :continuous_integration do
  let_it_be(:organization) { create(:organization) }
  let_it_be(:owner) { create(:user) }
  let_it_be(:parent_group, refind: true) do
    create(:group, organization: organization, owners: owner, path: 'parent-before')
  end

  describe 'when a project is destroyed' do
    let!(:project) { create(:project, namespace: parent_group, organization: organization) }

    it 'writes a tombstone for the project full path' do
      expected_path = project.full_path
      expected_project_id = project.id
      expected_organization_id = project.organization_id

      expect { project.destroy! }.to change {
        Authn::BurnedProjectRoute.for_path(expected_path).count
      }.from(0).to(1)

      row = Authn::BurnedProjectRoute.for_path(expected_path).order(:id).first
      expect(row).to have_attributes(
        project_id: expected_project_id,
        organization_id: expected_organization_id
      )
    end
  end

  describe 'when a project is renamed' do
    let!(:project) do
      create(:project, namespace: parent_group, organization: organization, path: 'before')
    end

    it 'writes a tombstone for the previous full path and not for the new full path' do
      old_full_path = project.full_path

      expect { project.update!(path: 'after') }.to change {
        Authn::BurnedProjectRoute.for_path(old_full_path).count
      }.from(0).to(1)

      row = Authn::BurnedProjectRoute.for_path(old_full_path).order(:id).first
      expect(row).to have_attributes(
        project_id: project.id,
        organization_id: project.organization_id
      )

      expect(Authn::BurnedProjectRoute.for_path(project.full_path)).to be_empty
    end
  end

  describe 'when a parent group is renamed' do
    let_it_be(:descendant_project) do
      create(:project, namespace: parent_group, organization: organization, path: 'widgets')
    end

    it 'writes a tombstone for the descendant project previous full path' do
      old_full_path = descendant_project.full_path

      expect { parent_group.update!(path: 'parent-after') }.to change {
        Authn::BurnedProjectRoute.for_path(old_full_path).count
      }.from(0).to(1)

      row = Authn::BurnedProjectRoute.for_path(old_full_path).order(:id).first
      expect(row).to have_attributes(
        project_id: descendant_project.id,
        organization_id: descendant_project.organization_id
      )

      expect(Authn::BurnedProjectRoute.for_path("#{parent_group.reload.full_path}/widgets")).to be_empty
    end

    it 'does not write a tombstone for the parent group path (group routes are not burned)' do
      old_group_full_path = parent_group.full_path

      expect { parent_group.update!(path: 'parent-after') }
        .not_to change { Authn::BurnedProjectRoute.for_path(old_group_full_path).count }
    end
  end

  describe 'when a parent group is destroyed and cascades into project deletion' do
    let_it_be(:project_a) { create(:project, namespace: parent_group, organization: organization) }
    let_it_be(:project_b) { create(:project, namespace: parent_group, organization: organization) }

    it 'writes a tombstone for each descendant project full path' do
      paths = [project_a.full_path, project_b.full_path]

      expect do
        Groups::DestroyService.new(parent_group, owner).execute
      end.to change {
        Authn::BurnedProjectRoute.where(organization_id: organization.id, path: paths).count
      }.from(0).to(2)

      paths.zip([project_a.id, project_b.id]).each do |path, project_id|
        row = Authn::BurnedProjectRoute.for_path(path).order(:id).first
        expect(row).to have_attributes(
          project_id: project_id,
          organization_id: organization.id
        )
      end
    end
  end

  describe 'when a project is transferred to a different parent namespace' do
    let_it_be(:destination_group, refind: true) do
      create(:group, organization: organization, owners: owner, path: 'destination-group')
    end

    let!(:project) do
      create(:project, namespace: parent_group, organization: organization, path: 'widgets')
    end

    before do
      allow(project).to receive(:has_container_registry_tags?).and_return(false)
      allow_next_instance_of(Gitlab::UploadsTransfer) do |service|
        allow(service).to receive(:move_project).and_return(true)
      end
    end

    it 'writes a tombstone for the previous full path and not for the new full path' do
      old_full_path = project.full_path

      expect { Projects::TransferService.new(project, owner).execute(destination_group) }
        .to change { Authn::BurnedProjectRoute.for_path(old_full_path).count }
        .from(0).to(1)

      row = Authn::BurnedProjectRoute.for_path(old_full_path).order(:id).first
      expect(row).to have_attributes(
        project_id: project.id,
        organization_id: organization.id
      )

      expect(Authn::BurnedProjectRoute.for_path(project.reload.full_path)).to be_empty
    end
  end

  describe 'when a project at an already-burned path is renamed' do
    let_it_be(:original_project_id) do
      project = create(:project, namespace: parent_group, organization: organization, path: 'target')
      id = project.id
      project.destroy!
      id
    end

    let_it_be(:burned_full_path) { "#{parent_group.path}/target" }

    let!(:project) do
      create(:project, namespace: parent_group, organization: organization, path: 'target')
    end

    it 'keeps the existing burn record unchanged across rename round-trips' do
      burn = Authn::BurnedProjectRoute.for_path(burned_full_path).order(:id).first
      original_burned_at = burn.burned_at

      expect(burn.project_id).to eq(original_project_id)
      expect(
        Authn::BurnedProjectRoute.blocked_for?(
          organization_id: organization.id,
          path: burned_full_path,
          except_project_id: project.id
        )
      ).to be(true)

      project.update!(path: 'target-tmp')

      burn.reload
      expect(burn.project_id).to eq(original_project_id)
      expect(burn.burned_at).to eq(original_burned_at)

      project.update!(path: 'target')

      expect(
        Authn::BurnedProjectRoute.blocked_for?(
          organization_id: organization.id,
          path: burned_full_path,
          except_project_id: project.id
        )
      ).to be(true)
    end
  end
end
