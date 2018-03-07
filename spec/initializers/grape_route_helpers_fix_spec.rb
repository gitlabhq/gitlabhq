require 'spec_helper'
require_relative '../../config/initializers/grape_route_helpers_fix'

describe 'route shadowing' do
  include GrapeRouteHelpers::NamedRouteMatcher

  it 'does not occur' do
    path = api_v4_projects_merge_requests_path(id: 1)
    expect(path).to eq('/api/v4/projects/1/merge_requests')

    path = api_v4_projects_merge_requests_path(id: 1, merge_request_iid: 3)
    expect(path).to eq('/api/v4/projects/1/merge_requests/3')
  end
end
