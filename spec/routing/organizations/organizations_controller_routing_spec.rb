# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::OrganizationsController, :routing, feature_category: :organization do
  let_it_be(:organization) { build(:organization) }

  specify 'to #show' do
    expect(get("/-/organizations/#{organization.path}"))
      .to route_to('organizations/organizations#show', organization_path: organization.path)
  end

  specify 'to #new' do
    expect(get("/-/organizations/new"))
      .to route_to('organizations/organizations#new')
  end

  specify 'to #index' do
    expect(get("/-/organizations"))
      .to route_to('organizations/organizations#index')
  end

  specify 'to #activity' do
    expect(get("/-/organizations/#{organization.path}/activity"))
      .to route_to('organizations/organizations#activity', organization_path: organization.path)
  end

  specify 'to #groups_and_projects' do
    expect(get("/-/organizations/#{organization.path}/groups_and_projects"))
      .to route_to('organizations/organizations#groups_and_projects', organization_path: organization.path)
  end

  specify 'to #users' do
    expect(get("/-/organizations/#{organization.path}/users"))
      .to route_to('organizations/organizations#users', organization_path: organization.path)
  end

  specify 'to #preview_markdown' do
    expect(post("/-/organizations/preview_markdown"))
      .to route_to('organizations/organizations#preview_markdown')
  end
end
