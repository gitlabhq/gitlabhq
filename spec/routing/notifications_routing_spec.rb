require "spec_helper"

describe "notifications routing" do
  it "routes to #show" do
    expect(get("/profile/notifications")).to route_to("profiles/notifications#show")
  end

  it "routes to #update" do
    expect(put("/profile/notifications")).to route_to("profiles/notifications#update")
  end
end
