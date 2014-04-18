require "spec_helper"

describe Profiles::NotificationsController do
  describe "routing" do
    it "routes to #show" do
      get("/profile/notifications").should route_to("profiles/notifications#show")
    end

    it "routes to #update" do
      put("/profile/notifications").should route_to("profiles/notifications#update")
    end
  end
end
