require 'spec_helper'

describe Gitlab::API do
  include ApiHelpers

  let(:user) { create(:user) }
  let(:key) { create(:key, user: user) }
  let(:project) { create(:project) }

  describe "GET /internal/check", no_db: true do
    it do
      get api("/internal/check")

      response.status.should == 200
      json_response['api_version'].should == Gitlab::API.version
    end
  end

  describe "GET /internal/discover" do
    it do
      get(api("/internal/discover"), key_id: key.id)

      response.status.should == 200

      json_response['email'].should == user.email
    end
  end

  describe "GET /internal/allowed" do
    context "access granted" do
      before do
        project.team << [user, :developer]
      end

      context "git pull" do
        it do
          get(
            api("/internal/allowed"),
            ref: 'master',
            key_id: key.id,
            project: project.path_with_namespace,
            action: 'git-upload-pack'
          )

          response.status.should == 200
          response.body.should == 'true'
        end
      end

      context "git push" do
        it do
          get(
            api("/internal/allowed"),
            ref: 'master',
            key_id: key.id,
            project: project.path_with_namespace,
            action: 'git-receive-pack'
          )

          response.status.should == 200
          response.body.should == 'true'
        end
      end
    end

    context "access denied" do
      before do
        project.team << [user, :guest]
      end

      context "git pull" do
        it do
          get(
            api("/internal/allowed"),
            ref: 'master',
            key_id: key.id,
            project: project.path_with_namespace,
            action: 'git-upload-pack'
          )

          response.status.should == 200
          response.body.should == 'false'
        end
      end

      context "git push" do
        it do
          get(
            api("/internal/allowed"),
            ref: 'master',
            key_id: key.id,
            project: project.path_with_namespace,
            action: 'git-receive-pack'
          )

          response.status.should == 200
          response.body.should == 'false'
        end
      end
    end

  end
end
