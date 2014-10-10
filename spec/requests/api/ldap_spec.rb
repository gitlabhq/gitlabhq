require 'spec_helper'

describe API::API do
  include ApiHelpers
  let(:user) { create(:user) }

  before do
    groups = [
      OpenStruct.new(cn: 'developers'),
      OpenStruct.new(cn: 'students')
    ]

    Gitlab::LDAP::Adapter.any_instance.stub(
      groups: groups
    )
  end

  describe "GET /ldap/groups" do
    context "when unauthenticated" do
      it "should return authentication error" do
        get api("/ldap/groups")
        response.status.should == 401
      end
    end

    context "when authenticated as user" do
      it "should return an array of ldap groups" do
        get api("/ldap/groups", user)
        response.status.should == 200
        json_response.should be_an Array
        json_response.length.should == 2
        json_response.first['cn'].should == 'developers'
      end
    end
  end

  describe "GET /ldap/ldapmain/groups" do
    context "when unauthenticated" do
      it "should return authentication error" do
        get api("/ldap/ldapmain/groups")
        response.status.should == 401
      end
    end

    context "when authenticated as user" do
      it "should return an array of ldap groups" do
        get api("/ldap/ldapmain/groups", user)
        response.status.should == 200
        json_response.should be_an Array
        json_response.length.should == 2
        json_response.first['cn'].should == 'developers'
      end
    end
  end
end
