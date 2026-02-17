# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Explore::GroupsController, "routing", feature_category: :groups_and_projects do
  specify "to #index" do
    expect(get("/explore/groups")).to route_to('explore/groups#index')
  end

  specify "to #active" do
    expect(get("/explore/groups/active")).to route_to('explore/groups#index')
  end

  specify "to #inactive" do
    expect(get("/explore/groups/inactive")).to route_to('explore/groups#index')
  end
end
