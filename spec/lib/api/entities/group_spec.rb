# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::Group, feature_category: :groups_and_projects do
  let_it_be(:group) do
    base_group = create(:group) do |g|
      create(:project_statistics, namespace_id: g.id)
      create(:namespace_root_storage_statistics, namespace_id: g.id)
    end
    Group.with_statistics.find(base_group.id)
  end

  subject(:json) { described_class.new(group, options).as_json }

  context 'with statistics' do
    let(:options) { { with_custom_attributes: true, statistics: true } }

    it 'returns expected data' do
      expect(json.keys).to(
        include(
          :organization_id, :path, :description, :visibility, :share_with_group_lock,
          :require_two_factor_authentication, :two_factor_grace_period, :project_creation_level, :auto_devops_enabled,
          :subgroup_creation_level, :emails_disabled, :emails_enabled, :lfs_enabled, :default_branch_protection,
          :default_branch_protection_defaults, :avatar_url, :request_access_enabled, :full_name, :full_path,
          :created_at, :parent_id, :organization_id, :shared_runners_setting, :custom_attributes, :statistics,
          :default_branch, :root_storage_statistics
        )
      )
    end

    context 'on a sub-group' do
      let(:subgroup) do
        subgroup = create(:group, parent: group, path: "#{group.path}-subgroup") do |g|
          create(:project_statistics, namespace_id: g.id)
        end
        Group.with_statistics.find(subgroup.id)
      end

      subject(:json) { described_class.new(subgroup, options).as_json }

      it 'does not expose root storage statistics' do
        expect(json.keys).not_to(include(:root_storage_statistics))
      end
    end

    context 'on a group without root storage statistics' do
      let(:group_without_root_storage_statistics) do
        base_group = create(:group) do |g|
          create(:project_statistics, namespace_id: g.id)
        end
        Group.with_statistics.find(base_group.id)
      end

      subject(:json) { described_class.new(group_without_root_storage_statistics, options).as_json }

      it 'returns nil for root storage statistics' do
        expect(json[:root_storage_statistics]).to be_nil
      end
    end
  end

  context 'without statistics' do
    let(:options) { { with_custom_attributes: true, statistics: false } }

    it 'does not expose statistics' do
      expect(json.keys).not_to(include(:statistics, :root_storage_statistics))
    end
  end
end
