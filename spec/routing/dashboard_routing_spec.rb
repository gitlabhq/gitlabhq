# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dashboard::GroupsController, "routing", feature_category: :groups_and_projects do
  specify "to #index" do
    expect(get("/dashboard/groups")).to route_to('dashboard/groups#index')
  end

  specify "to #member" do
    expect(get("/dashboard/groups/member")).to route_to('dashboard/groups#index')
  end

  specify "to #inactive" do
    expect(get("/dashboard/groups/inactive")).to route_to('dashboard/groups#index')
  end
end

RSpec.describe Dashboard::ProjectsController, "routing", feature_category: :groups_and_projects do
  specify "to #contributed" do
    expect(get("/dashboard/projects/contributed")).to route_to('dashboard/projects#index')
  end

  specify "to #starred" do
    expect(get("/dashboard/projects/starred")).to route_to('dashboard/projects#index')
  end

  specify "to #personal" do
    expect(get("/dashboard/projects/personal")).to route_to('dashboard/projects#index')
  end

  specify "to #member" do
    expect(get("/dashboard/projects/member")).to route_to('dashboard/projects#index')
  end

  specify "to #inactive" do
    expect(get("/dashboard/projects/inactive")).to route_to('dashboard/projects#index')
  end
end
