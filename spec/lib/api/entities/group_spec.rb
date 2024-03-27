# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::Group, feature_category: :groups_and_projects do
  let_it_be(:group) do
    base_group = create(:group) { |g| create(:project_statistics, namespace_id: g.id) }
    Group.with_statistics.find(base_group.id)
  end

  subject(:json) { described_class.new(group, { with_custom_attributes: true, statistics: true }).as_json }

  it 'returns expected data' do
    expect(json.keys).to(
      include(
        :organization_id, :path, :description, :visibility, :share_with_group_lock, :require_two_factor_authentication,
        :two_factor_grace_period, :project_creation_level, :auto_devops_enabled,
        :subgroup_creation_level, :emails_disabled, :emails_enabled, :lfs_enabled, :default_branch_protection,
        :default_branch_protection_defaults, :avatar_url, :request_access_enabled, :full_name, :full_path, :created_at,
        :parent_id, :organization_id, :shared_runners_setting, :custom_attributes, :statistics, :default_branch
      )
    )
  end
end
