require 'spec_helper'

describe API::V3::ProjectPushRule, 'ProjectPushRule', api: true  do
  include ApiHelpers
  let(:user) { create(:user) }
  let(:user3) { create(:user) }
  let!(:project) { create(:project, :repository, creator_id: user.id, namespace: user.namespace) }

  before do
    project.add_master(user)
    project.add_developer(user3)
  end

  describe "DELETE /projects/:id/push_rule" do
    before do
      create(:push_rule, project: project)
    end

    context "authorized user" do
      it "deletes push rule from project" do
        delete v3_api("/projects/#{project.id}/push_rule", user)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_an Hash
      end
    end

    context "unauthorized user" do
      it "returns a 403 error" do
        delete v3_api("/projects/#{project.id}/push_rule", user3)

        expect(response).to have_gitlab_http_status(403)
      end
    end
  end

  describe "DELETE /projects/:id/push_rule" do
    context "for non existing push rule" do
      it "deletes push rule from project" do
        delete v3_api("/projects/#{project.id}/push_rule", user)

        expect(response).to have_gitlab_http_status(404)
        expect(json_response).to be_an Hash
        expect(json_response['message']).to eq('404 Push Rule Not Found')
      end

      it "returns a 403 error if not authorized" do
        delete v3_api("/projects/#{project.id}/push_rule", user3)

        expect(response).to have_gitlab_http_status(403)
      end
    end
  end
end
