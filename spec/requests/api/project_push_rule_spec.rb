require 'spec_helper'

describe API::ProjectPushRule, 'ProjectPushRule', api: true  do
  include ApiHelpers
  let(:user) { create(:user) }
  let(:user3) { create(:user) }
  let!(:project) { create(:project, creator_id: user.id, namespace: user.namespace) }

  before do
    project.team << [user, :master]
    project.team << [user3, :developer]
  end

  describe "GET /projects/:id/push_rule" do
    before do
      create(:push_rule, project: project)
    end

    context "authorized user" do
      it "returns project push rule" do
        get api("/projects/#{project.id}/push_rule", user)

        expect(response).to have_http_status(200)
        expect(json_response).to be_an Hash
        expect(json_response['project_id']).to eq(project.id)
      end
    end

    context "unauthorized user" do
      it "does not have access to project push rule" do
        get api("/projects/#{project.id}/push_rule", user3)

        expect(response).to have_http_status(403)
      end
    end
  end

  describe "POST /projects/:id/push_rule" do
    context "authorized user" do
      it "adds push rule to project" do
        post api("/projects/#{project.id}/push_rule", user),
          deny_delete_tag: true,  member_check: true, prevent_secrets: true,
          commit_message_regex: 'JIRA\-\d+',
          branch_name_regex: '(feature|hotfix)\/*',
          author_email_regex: '[a-zA-Z0-9]+@gitlab.com',
          file_name_regex: '[a-zA-Z0-9]+.key',
          max_file_size: 5

        expect(response).to have_http_status(201)
        expect(json_response['project_id']).to eq(project.id)
        expect(json_response['deny_delete_tag']).to eq(true)
        expect(json_response['member_check']).to eq(true)
        expect(json_response['prevent_secrets']).to eq(true)
        expect(json_response['commit_message_regex']).to eq('JIRA\-\d+')
        expect(json_response['branch_name_regex']).to eq('(feature|hotfix)\/*')
        expect(json_response['author_email_regex']).to eq('[a-zA-Z0-9]+@gitlab.com')
        expect(json_response['file_name_regex']).to eq('[a-zA-Z0-9]+.key')
        expect(json_response['max_file_size']).to eq(5)
      end
    end

    it 'adds push rule to project with no file size' do
      post api("/projects/#{project.id}/push_rule", user),
        commit_message_regex: 'JIRA\-\d+'

      expect(response).to have_http_status(201)
      expect(json_response['project_id']).to eq(project.id)
      expect(json_response['commit_message_regex']).to eq('JIRA\-\d+')
      expect(json_response['max_file_size']).to eq(0)
    end

    it 'returns 400 if no parameter is given' do
      post api("/projects/#{project.id}/push_rule", user)

      expect(response).to have_http_status(400)
    end

    context "unauthorized user" do
      it "does not add push rule to project" do
        post api("/projects/#{project.id}/push_rule", user3), deny_delete_tag: true

        expect(response).to have_http_status(403)
      end
    end
  end

  describe "POST /projects/:id/push_rule" do
    before do
      create(:push_rule, project: project)
    end

    context "with existing push rule" do
      it "does not add push rule to project" do
        post api("/projects/#{project.id}/push_rule", user), deny_delete_tag: true

        expect(response).to have_http_status(422)
      end
    end
  end

  describe "PUT /projects/:id/push_rule" do
    before do
      create(:push_rule, project: project)
    end

    it "updates an existing project push rule" do
      put api("/projects/#{project.id}/push_rule", user),
        deny_delete_tag: false, commit_message_regex: 'Fixes \d+\..*'

      expect(response).to have_http_status(200)
      expect(json_response['deny_delete_tag']).to eq(false)
      expect(json_response['commit_message_regex']).to eq('Fixes \d+\..*')
    end

    it 'returns 400 if no parameter is given' do
      put api("/projects/#{project.id}/push_rule", user)

      expect(response).to have_http_status(400)
    end
  end

  describe "PUT /projects/:id/push_rule" do
    it "gets error on non existing project push rule" do
      put api("/projects/#{project.id}/push_rule", user),
        deny_delete_tag: false, commit_message_regex: 'Fixes \d+\..*'

      expect(response).to have_http_status(404)
    end

    it "does not update push rule for unauthorized user" do
      post api("/projects/#{project.id}/push_rule", user3), deny_delete_tag: true

      expect(response).to have_http_status(403)
    end
  end

  describe "DELETE /projects/:id/push_rule" do
    before do
      create(:push_rule, project: project)
    end

    context "authorized user" do
      it "deletes push rule from project" do
        delete api("/projects/#{project.id}/push_rule", user)

        expect(response).to have_http_status(204)
      end
    end

    context "unauthorized user" do
      it "returns a 403 error" do
        delete api("/projects/#{project.id}/push_rule", user3)

        expect(response).to have_http_status(403)
      end
    end
  end

  describe "DELETE /projects/:id/push_rule" do
    context "for non existing push rule" do
      it "deletes push rule from project" do
        delete api("/projects/#{project.id}/push_rule", user)

        expect(response).to have_http_status(404)
        expect(json_response).to be_an Hash
        expect(json_response['message']).to eq('404 Push Rule Not Found')
      end

      it "returns a 403 error if not authorized" do
        delete api("/projects/#{project.id}/push_rule", user3)

        expect(response).to have_http_status(403)
      end
    end
  end
end
