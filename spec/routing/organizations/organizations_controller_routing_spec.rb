# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::OrganizationsController, :routing, feature_category: :cell do
  let_it_be(:organization) { build(:organization) }

  it 'routes to #show' do
    expect(get("/-/organizations/#{organization.path}"))
      .to route_to('organizations/organizations#show', organization_path: organization.path)
  end

  it 'routes to #new' do
    expect(get("/-/organizations/new"))
      .to route_to('organizations/organizations#new')
  end

  it 'routes to #index' do
    expect(get("/-/organizations"))
      .to route_to('organizations/organizations#index')
  end

  it 'routes to #activity' do
    expect(get("/-/organizations/#{organization.path}/activity"))
      .to route_to('organizations/organizations#activity', organization_path: organization.path)
  end

  it 'routes to #groups_and_projects' do
    expect(get("/-/organizations/#{organization.path}/groups_and_projects"))
      .to route_to('organizations/organizations#groups_and_projects', organization_path: organization.path)
  end

  it 'routes to #users' do
    expect(get("/-/organizations/#{organization.path}/users"))
      .to route_to('organizations/organizations#users', organization_path: organization.path)
  end

  it 'routes to #preview_markdown' do
    expect(post("/-/organizations/preview_markdown"))
      .to route_to('organizations/organizations#preview_markdown')
  end
end
