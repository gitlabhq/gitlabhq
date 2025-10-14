# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Organization routes', feature_category: :organization do
  it 'ensures organization_path is constrained' do
    expect(get('/o/admin/projects/new')).to route_to_route_not_found
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
