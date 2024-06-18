# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::GroupsController, :routing, feature_category: :cell do
  let_it_be(:organization) { build(:organization) }
  let_it_be(:group) { build(:group, organization: organization) }

  it 'routes to groups#new' do
    expect(get("/-/organizations/#{organization.path}/groups/new"))
      .to route_to('organizations/groups#new', organization_path: organization.path)
  end

  it 'routes to groups#edit' do
    expect(get("/-/organizations/#{organization.path}/groups/#{group.full_path}/edit"))
      .to route_to(
        'organizations/groups#edit',
        organization_path: organization.path,
        id: group.to_param
      )
  end
end
