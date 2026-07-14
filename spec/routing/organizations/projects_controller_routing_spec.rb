# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::GroupsController, :routing, feature_category: :organization do
  let_it_be_with_reload(:organization) { build(:organization) }
  let_it_be_with_reload(:project) { create(:project, organization: organization) }

  specify 'to projects#edit' do
    expect(get("/o/#{organization.path}/-/projects/#{project.path_with_namespace}/edit"))
      .to route_to(
        'organizations/projects#edit', organization_path: organization.path,
        id: project.to_param,
        namespace_id: project.namespace.to_param
      )
  end
end
