require 'spec_helper'

describe API::API, api: true  do
  include ApiHelpers
  let(:admin) { create(:admin) }
  let!(:group1) { create(:group) }
  let!(:group2) { create(:group) }

  describe "GET /namespaces" do
    context "when unauthenticated" do
      it "should return authentication error" do
        get api("/namespaces")
        response.status.should == 401
      end
    end

    context "when authenticated as  admin" do
      it "admin: should return an array of all namespaces" do
        get api("/namespaces", admin)
        response.status.should == 200
        json_response.should be_an Array

        json_response.length.should == Namespace.count
      end
    end
  end
end
