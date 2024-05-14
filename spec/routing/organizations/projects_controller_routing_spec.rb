# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::GroupsController, :routing, feature_category: :cell do
  let_it_be(:organization) { build(:organization) }
  let_it_be(:project) { create(:project, organization: organization) }

  it 'routes to projects#edit' do
    expect(get("/-/organizations/#{organization.path}/projects/#{project.path_with_namespace}/edit"))
      .to route_to(
        'organizations/projects#edit', organization_path: organization.path,
        id: project.to_param,
        namespace_id: project.namespace.to_param
      )
  end
end
