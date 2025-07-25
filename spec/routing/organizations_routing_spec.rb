# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Organization routes', feature_category: :organization do
  it 'ensures organization_path is constrained' do
    expect(get('/o/admin/projects/new')).to route_to_route_not_found
  end

  describe 'projects' do
    it 'to #new' do
      expect(get('/o/my-org/projects/new')).to route_to('projects#new', organization_path: 'my-org')
    end

    it 'to #create' do
      expect(post('/o/my-org/projects')).to route_to('projects#create', organization_path: 'my-org')
    end
  end

  describe 'groups' do
    it "to #new" do
      expect(get("/o/my-org/groups/new")).to route_to('groups#new', organization_path: 'my-org')
    end

    it "to #create" do
      expect(post("/o/my-org/groups")).to route_to('groups#create', organization_path: 'my-org')
    end
  end
end
