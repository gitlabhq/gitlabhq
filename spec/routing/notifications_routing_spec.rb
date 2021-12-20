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
    expect(put("/-/profile/groups/gitlab-org/notifications")).to route_to("profiles/groups#update", id: 'gitlab-org')
    expect(put("/-/profile/groups/gitlab.org/notifications/")).to route_to("profiles/groups#update", id: 'gitlab.org')
    expect(put("/-/profile/groups/gitlab.org/gitlab/notifications")).to route_to("profiles/groups#update", id: 'gitlab.org/gitlab')
  end
end
