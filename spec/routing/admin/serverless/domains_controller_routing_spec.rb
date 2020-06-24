# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::Serverless::DomainsController do
  it 'routes to #index' do
    expect(get: '/admin/serverless/domains').to route_to('admin/serverless/domains#index')
  end

  it 'routes to #create' do
    expect(post: '/admin/serverless/domains/').to route_to('admin/serverless/domains#create')
  end

  it 'routes to #update' do
    expect(put: '/admin/serverless/domains/1').to route_to(controller: 'admin/serverless/domains', action: 'update', id: '1')
    expect(patch: '/admin/serverless/domains/1').to route_to(controller: 'admin/serverless/domains', action: 'update', id: '1')
  end

  it 'routes #verify' do
    expect(post: '/admin/serverless/domains/1/verify').to route_to(controller: 'admin/serverless/domains', action: 'verify', id: '1')
  end
end
