# frozen_string_literal: true

require "spec_helper"

RSpec.describe "notifications routing" do
  it "routes to #show" do
    expect(get("/-/profile/notifications")).to route_to("profiles/notifications#show")
  end

  it "routes to #update" do
    expect(put("/-/profile/notifications")).to route_to("profiles/notifications#update")
  end

  it 'routes to group #update' do
    expect(put("/-/profile/notifications/groups/gitlab-org")).to route_to("profiles/groups#update", id: 'gitlab-org')
    expect(put("/-/profile/notifications/groups/gitlab.org")).to route_to("profiles/groups#update", id: 'gitlab.org')
  end
end
