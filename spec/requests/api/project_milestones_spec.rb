# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::ProjectMilestones do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, namespace: user.namespace ) }
  let_it_be(:closed_milestone) { create(:closed_milestone, project: project, title: 'version1', description: 'closed milestone') }
  let_it_be(:milestone) { create(:milestone, project: project, title: 'version2', description: 'open milestone') }
  let_it_be(:route) { "/projects/#{project.id}/milestones" }

  before do
    project.add_developer(user)
  end

  it_behaves_like 'group and project milestones', "/projects/:id/milestones"

  describe 'GET /projects/:id/milestones' do
    context 'when include_parent_milestones is true' do
      let_it_be(:ancestor_group) { create(:group, :private) }
      let_it_be(:group) { create(:group, :private, parent: ancestor_group) }
      let_it_be(:ancestor_group_milestone) { create(:milestone, group: ancestor_group) }
      let_it_be(:group_milestone) { create(:milestone, group: group) }

      let(:params) { { include_parent_milestones: true } }

      shared_examples 'listing all milestones' do
        it 'returns correct list of milestones' do
          get api(route, user), params: params

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response.size).to eq(milestones.size)
          expect(json_response.map { |entry| entry["id"] }).to eq(milestones.map(&:id))
        end
      end

      context 'when project parent is a namespace' do
        it_behaves_like 'listing all milestones' do
          let(:milestones) { [milestone, closed_milestone] }
        end
      end

      context 'when project parent is a group' do
        let(:milestones) { [group_milestone, ancestor_group_milestone, milestone, closed_milestone] }

        before_all do
          project.update!(namespace: group)
        end

        it_behaves_like 'listing all milestones'

        context 'when iids param is present' do
          let(:params) { { include_parent_milestones: true, iids: [group_milestone.iid] } }

          it_behaves_like 'listing all milestones'
        end

        context 'when user is not a member of the private project' do
          let(:external_user) { create(:user) }

          it 'returns a 404 error' do
            get api(route, external_user), params: params

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end
      end
    end
  end

  describe 'DELETE /projects/:id/milestones/:milestone_id' do
    let(:guest) { create(:user) }
    let(:reporter) { create(:user) }

    before do
      project.add_reporter(reporter)
    end

    it 'returns 404 response when the project does not exist' do
      delete api("/projects/0/milestones/#{milestone.id}", user)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'returns 404 response when the milestone does not exist' do
      delete api("/projects/#{project.id}/milestones/0", user)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it "returns 404 from guest user deleting a milestone" do
      delete api("/projects/#{project.id}/milestones/#{milestone.id}", guest)

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  describe 'PUT /projects/:id/milestones/:milestone_id to test observer on close' do
    it 'creates an activity event when a milestone is closed' do
      path = "/projects/#{project.id}/milestones/#{milestone.id}"

      expect do
        put api(path, user), params: { state_event: 'close' }
      end.to change(Event, :count).by(1)
    end
  end

  describe 'POST /projects/:id/milestones/:milestone_id/promote' do
    let(:group) { create(:group) }

    before do
      project.update!(namespace: group)
    end

    context 'when user does not have permission to promote milestone' do
      before do
        group.add_guest(user)
      end

      it 'returns 403' do
        post api("/projects/#{project.id}/milestones/#{milestone.id}/promote", user)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when user has permission' do
      before do
        group.add_developer(user)
      end

      it 'returns 200' do
        post api("/projects/#{project.id}/milestones/#{milestone.id}/promote", user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(group.milestones.first.title).to eq(milestone.title)
      end

      it 'returns 200 for closed milestone' do
        post api("/projects/#{project.id}/milestones/#{closed_milestone.id}/promote", user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(group.milestones.first.title).to eq(closed_milestone.title)
      end
    end

    context 'when no such resource' do
      before do
        group.add_developer(user)
      end

      it 'returns 404 response when the project does not exist' do
        post api("/projects/0/milestones/#{milestone.id}/promote", user)

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'returns 404 response when the milestone does not exist' do
        post api("/projects/#{project.id}/milestones/0/promote", user)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when project does not belong to group' do
      before do
        project.update!(namespace: user.namespace)
      end

      it 'returns 403' do
        post api("/projects/#{project.id}/milestones/#{milestone.id}/promote", user)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end
end
