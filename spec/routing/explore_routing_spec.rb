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

RSpec.describe "Explore analytics dashboards routing", feature_category: :custom_dashboards_foundation do
  it "falls through to the catch-all in FOSS" do
    skip "the route is intentionally available in EE" if Gitlab.ee?

    expect(get("/explore/analytics_dashboards")).to route_to_route_not_found
  end
end
