require 'spec_helper'

describe API::API do
  include ApiHelpers
  let(:user) { create(:user) }

  before do
    groups = [
      OpenStruct.new(cn: 'developers'),
      OpenStruct.new(cn: 'students')
    ]

    allow_any_instance_of(Gitlab::LDAP::Adapter).to receive_messages(groups: groups)
  end

  describe "GET /ldap/groups" do
    context "when unauthenticated" do
      it "should return authentication error" do
        get api("/ldap/groups")
        expect(response.status).to eq 401
      end
    end

    context "when authenticated as user" do
      it "should return an array of ldap groups" do
        get api("/ldap/groups", user)
        expect(response.status).to eq 200
        expect(json_response).to be_an Array
        expect(json_response.length).to eq 2
        expect(json_response.first['cn']).to eq 'developers'
      end
    end
  end

  describe "GET /ldap/ldapmain/groups" do
    context "when unauthenticated" do
      it "should return authentication error" do
        get api("/ldap/ldapmain/groups")
        expect(response.status).to eq 401
      end
    end

    context "when authenticated as user" do
      it "should return an array of ldap groups" do
        get api("/ldap/ldapmain/groups", user)
        expect(response.status).to eq 200
        expect(json_response).to be_an Array
        expect(json_response.length).to eq 2
        expect(json_response.first['cn']).to eq 'developers'
      end
    end
  end
end
