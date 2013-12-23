require 'spec_helper'

describe API::API do
  include ApiHelpers

  let(:user) { create(:user) }

  describe "POST /session" do
    context "when valid password" do
      it "should return private token" do
        post api("/session"), email: user.email, password: '12345678'
        response.status.should == 201

        json_response['email'].should == user.email
        json_response['private_token'].should == user.private_token
        json_response['is_admin'].should == user.is_admin?
        json_response['can_create_project'].should == user.can_create_project?
        json_response['can_create_group'].should == user.can_create_group?
      end
    end

    context "when invalid password" do
      it "should return authentication error" do
        post api("/session"), email: user.email, password: '123'
        response.status.should == 401

        json_response['email'].should be_nil
        json_response['private_token'].should be_nil
      end
    end

    context "when empty password" do
      it "should return authentication error" do
        post api("/session"), email: user.email
        response.status.should == 401

        json_response['email'].should be_nil
        json_response['private_token'].should be_nil
      end
    end

    context "when empty name" do
      it "should return authentication error" do
        post api("/session"), password: user.password
        response.status.should == 401

        json_response['email'].should be_nil
        json_response['private_token'].should be_nil
      end
    end
  end
end
