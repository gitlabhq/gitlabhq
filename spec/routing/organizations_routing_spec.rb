# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Organization routes', feature_category: :organization do
  describe 'organization-prefixed routes' do
    it 'handles routes with /o/:organization_path prefix' do
      expect(get('/o/my-org')).to be_routable
    end

    it 'includes organization_path parameter in routed params' do
      expect(get('/o/my-org')).to route_to('root#index', organization_path: 'my-org')
    end

    it 'ensures organization_path is constrained' do
      expect(get('/o/admin/projects/new')).to route_to_route_not_found
    end
  end

  describe 'excluded routes from organization routing' do
    RSpec.shared_examples 'organization route exclusion' do |route_path|
      describe "route exclusion for #{route_path}" do
        it 'does not route through organization scoped paths' do
          expect(get(route_path)).to route_to_route_not_found
        end
      end
    end

    context 'for api routes' do
      it_behaves_like 'organization route exclusion', '/o/my-org/api/v4/projects'
      it_behaves_like 'organization route exclusion', '/o/my-org/api/graphql'
      it_behaves_like 'organization route exclusion', '/o/my-org/api/glql'
    end
  end

  describe 'included routes from organization routing' do
    RSpec.shared_examples 'organization route inclusion' do |org_path, global_path|
      describe "route inclusion for #{org_path}" do
        it 'routes through organization scoped paths' do
          expect(get(org_path)).to be_routable
        end

        it 'routes to the same destination' do
          organization_route = Rails.application.routes.recognize_path(org_path, method: :get)
          global_route = Rails.application.routes.recognize_path(global_path, method: :get)

          expect(organization_route[:controller]).to eq(global_route[:controller])
          expect(organization_route[:action]).to eq(global_route[:action])
        end
      end
    end

    it_behaves_like 'organization route inclusion', '/o/my-org/projects/my-api-project', '/projects/my-api-project'
    it_behaves_like 'organization route inclusion', '/o/my-org/groups/api-team', '/groups/api-team'

    it 'covers routes that are not organization scoped' do
      non_org_routes = Rails.application.routes.routes.reject do |route|
        route_path = route.path.spec.to_s
        # Skip API routes, organization-scoped routes, catch-all routes, and empty routes
        route_path.include?('/api/') ||
          route_path.start_with?('/o/') ||
          route_path == '/*unmatched_route' ||
          route_path.empty? ||
          # Skip engine-mounted routes and Rack endpoints (routes without a controller)
          !route.defaults[:controller]
      end

      non_org_routes.each do |route|
        route_path = route.path.spec.to_s
        expect(get("/o/my-org#{route_path}")).to be_routable
      end
    end
  end

  describe '/o' do
    specify "to organizations/organizations#index" do
      expect(get("/o")).to route_to('organizations/organizations#index')
    end
  end

  describe 'root' do
    specify "to root#index" do
      expect(get("/o/my-org")).to route_to('root#index', organization_path: 'my-org')
    end
  end

  describe 'projects' do
    specify "to #new" do
      expect(get("/o/my-org/projects/new")).to route_to('projects#new', organization_path: 'my-org')
    end

    specify "to #create" do
      expect(post("/o/my-org/projects")).to route_to('projects#create', organization_path: 'my-org')
    end
  end

  describe 'groups' do
    specify "to #new" do
      expect(get("/o/my-org/groups/new")).to route_to('groups#new', organization_path: 'my-org')
    end

    specify "to #create" do
      expect(post("/o/my-org/groups")).to route_to('groups#create', organization_path: 'my-org')
    end
  end

  describe 'project dashboards' do
    specify "to #index" do
      expect(get("/o/my-org/dashboard/projects")).to route_to("dashboard/projects#index", organization_path: 'my-org')
    end

    %w[
      contributed
      starred
      personal
      member
      inactive
    ].each do |action|
      specify "to #{action}" do
        expect(get("/o/my-org/dashboard/projects/#{action}")).to route_to("dashboard/projects#index",
          organization_path: 'my-org')
      end
    end
  end

  describe 'groups dashboards' do
    specify "to #index" do
      expect(get("/o/my-org/dashboard/groups")).to route_to("dashboard/groups#index", organization_path: 'my-org')
    end

    %w[
      member
      inactive
    ].each do |action|
      specify "to #{action}" do
        expect(get("/o/my-org/dashboard/groups/#{action}")).to route_to("dashboard/groups#index",
          organization_path: 'my-org')
      end
    end
  end
end
