require 'spec_helper'

describe API::API, api: true  do
  include ApiHelpers
  let(:admin) { create(:admin) }
  let(:user) { create(:user) }
  let!(:group1) { create(:group) }
  let!(:group2) { create(:group) }

  describe "GET /namespaces" do
    context "when unauthenticated" do
      it "should return authentication error" do
        get api("/namespaces")
        expect(response.status).to eq(401)
      end
    end

    context "when authenticated as admin" do
      it "admin: should return an array of all namespaces" do
        get api("/namespaces", admin)
        expect(response.status).to eq(200)
        expect(json_response).to be_an Array

        expect(json_response.length).to eq(Namespace.count)
      end

      it "admin: should return an array of matched namespaces" do
        get api("/namespaces?search=#{group1.name}", admin)
        expect(response.status).to eq(200)
        expect(json_response).to be_an Array

        expect(json_response.length).to eq(1)
      end
    end

    context "when authenticated as a regular user" do
      it "user: should return an array of namespaces" do
        get api("/namespaces", user)
        expect(response.status).to eq(200)
        expect(json_response).to be_an Array

        expect(json_response.length).to eq(1)
      end

      it "admin: should return an array of matched namespaces" do
        get api("/namespaces?search=#{user.username}", user)
        expect(response.status).to eq(200)
        expect(json_response).to be_an Array

        expect(json_response.length).to eq(1)
      end
    end
  end
end
