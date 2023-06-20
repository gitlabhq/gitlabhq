# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::OrganizationsController, :routing, feature_category: :cell do
  let_it_be(:organization) { build(:organization) }

  it 'routes to #directory' do
    expect(get("/-/organizations/#{organization.path}/directory"))
      .to route_to('organizations/organizations#directory', organization_path: organization.path)
  end
end
