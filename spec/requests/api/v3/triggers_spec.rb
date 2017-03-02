require 'spec_helper'

describe API::V3::Triggers do
  include ApiHelpers

  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let!(:trigger_token) { 'secure_token' }
  let!(:project) { create(:project, :repository, creator: user) }
  let!(:master) { create(:project_member, :master, user: user, project: project) }
  let!(:developer) { create(:project_member, :developer, user: user2, project: project) }
  let!(:trigger) { create(:ci_trigger, project: project, token: trigger_token) }

  describe 'DELETE /projects/:id/triggers/:token' do
    context 'authenticated user with valid permissions' do
      it 'deletes trigger' do
        expect do
          delete v3_api("/projects/#{project.id}/triggers/#{trigger.token}", user)

          expect(response).to have_http_status(200)
        end.to change{project.triggers.count}.by(-1)
      end

      it 'responds with 404 Not Found if requesting non-existing trigger' do
        delete v3_api("/projects/#{project.id}/triggers/abcdef012345", user)

        expect(response).to have_http_status(404)
      end
    end

    context 'authenticated user with invalid permissions' do
      it 'does not delete trigger' do
        delete v3_api("/projects/#{project.id}/triggers/#{trigger.token}", user2)

        expect(response).to have_http_status(403)
      end
    end

    context 'unauthenticated user' do
      it 'does not delete trigger' do
        delete v3_api("/projects/#{project.id}/triggers/#{trigger.token}")

        expect(response).to have_http_status(401)
      end
    end
  end
end
