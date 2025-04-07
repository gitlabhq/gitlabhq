# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dashboard::ProjectsController, "routing", feature_category: :groups_and_projects do
  it "to #contributed" do
    expect(get("/dashboard/projects/contributed")).to route_to('dashboard/projects#index')
  end

  it "to #starred" do
    expect(get("/dashboard/projects/starred")).to route_to('dashboard/projects#index')
  end

  it "to #personal" do
    expect(get("/dashboard/projects/personal")).to route_to('dashboard/projects#index')
  end

  it "to #member" do
    expect(get("/dashboard/projects/member")).to route_to('dashboard/projects#index')
  end

  it "to #inactive" do
    expect(get("/dashboard/projects/inactive")).to route_to('dashboard/projects#index')
  end
end
