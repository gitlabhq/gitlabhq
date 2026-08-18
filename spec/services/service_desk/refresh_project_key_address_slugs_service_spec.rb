# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ServiceDesk::RefreshProjectKeyAddressSlugsService, feature_category: :service_desk do
  let_it_be(:group) { create(:group) }
  let_it_be(:subgroup) { create(:group, parent: group) }
  let_it_be_with_reload(:project) { create(:project, group: subgroup) }

  subject(:execute) { described_class.new(route_path).execute }

  context 'when a project under the path has a service desk setting with a project_key' do
    let(:route_path) { group.full_path }

    let!(:setting) { create(:service_desk_setting, project: project, project_key: 'mykey') }

    it 'recomputes project_key_address_slug from the current full path' do
      setting.update_column(:project_key_address_slug, 'stale-value')

      execute

      expect(setting.reload.project_key_address_slug).to eq("#{project.full_path_slug}-mykey")
    end
  end

  context 'when a project under the path has no project_key' do
    let(:route_path) { group.full_path }

    let!(:setting) { create(:service_desk_setting, project: project, project_key: nil) }

    it 'does not change the setting' do
      expect { execute }.not_to change { setting.reload.project_key_address_slug }
    end
  end

  context 'when the route_path is blank' do
    let(:route_path) { '' }

    it 'does nothing' do
      expect(ServiceDeskSetting).not_to receive(:for_projects_inside_route_path)

      execute
    end
  end

  context 'when the new slug collides with another project service desk address' do
    # group1/test-one and group1/test/one both slugify to "group1-test-one".
    # conflicting_project starts at a distinct slug so its setting saves cleanly,
    # then its route is moved to group1/test/one (as RenameDescendants#upsert_all
    # would) so the recomputed slug now collides.
    let_it_be(:test_subgroup) { create(:group, parent: group, name: 'test') }
    let_it_be_with_reload(:conflicting_project) { create(:project, path: 'unique', group: test_subgroup) }

    let(:route_path) { group.full_path }

    before do
      other_project = create(:project, path: 'test-one', group: group)
      create(:service_desk_setting, project: other_project, project_key: 'key')
      create(:service_desk_setting, project: conflicting_project, project_key: 'key')

      conflicting_project.route.update_column(:path, "#{test_subgroup.full_path}/one")
    end

    it 'raises AddressSlugConflictError with the offending project full path' do
      expect { execute }.to raise_error(
        described_class::AddressSlugConflictError,
        conflicting_project.reload.full_path
      )
    end
  end

  context 'when the save fails for an unrelated validation' do
    let(:route_path) { group.full_path }

    let!(:setting) { create(:service_desk_setting, project: project, project_key: 'mykey') }

    it 're-raises the original error instead of an AddressSlugConflictError' do
      invalid_error = ActiveRecord::RecordInvalid.new(setting)
      setting.errors.add(:issue_template_key, 'is empty or does not exist')

      allow_next_found_instance_of(ServiceDeskSetting) do |instance|
        allow(instance).to receive(:refresh_project_key_address_slug!).and_raise(invalid_error)
      end

      expect { execute }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end
