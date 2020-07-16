# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::ProjectMilestones do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, namespace: user.namespace ) }
  let_it_be(:closed_milestone) { create(:closed_milestone, project: project, title: 'version1', description: 'closed milestone') }
  let_it_be(:milestone) { create(:milestone, project: project, title: 'version2', description: 'open milestone') }

  before do
    project.add_developer(user)
  end

  it_behaves_like 'group and project milestones', "/projects/:id/milestones" do
    let(:route) { "/projects/#{project.id}/milestones" }
  end

  describe 'GET /projects/:id/milestones' do
    context 'when include_parent_milestones is true' do
      let_it_be(:group) { create(:group, :public) }
      let_it_be(:child_group) { create(:group, :public, parent: group) }
      let_it_be(:child_project) { create(:project, group: child_group) }
      let_it_be(:project_milestone) { create(:milestone, project: child_project) }
      let_it_be(:group_milestone) { create(:milestone, group: group) }
      let_it_be(:child_group_milestone) { create(:milestone, group: child_group) }

      before do
        child_project.add_developer(user)
      end

      it 'includes parent groups milestones' do
        milestones = [child_group_milestone, group_milestone, project_milestone]

        get api("/projects/#{child_project.id}/milestones", user),
            params: { include_parent_milestones: true }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.size).to eq(3)
        expect(json_response.map { |entry| entry["id"] }).to eq(milestones.map(&:id))
      end

      context 'when user has no access to an ancestor group' do
        before do
          [child_group, group].each do |group|
            group.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
          end
        end

        it 'does not show ancestor group milestones' do
          milestones = [child_group_milestone, project_milestone]

          get api("/projects/#{child_project.id}/milestones", user),
              params: { include_parent_milestones: true }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response.size).to eq(2)
          expect(json_response.map { |entry| entry["id"] }).to eq(milestones.map(&:id))
        end
      end

      context 'when filtering by iids' do
        it 'does not filter by iids' do
          milestones = [child_group_milestone, group_milestone, project_milestone]

          get api("/projects/#{child_project.id}/milestones", user),
              params: { include_parent_milestones: true, iids: [group_milestone.iid] }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response.size).to eq(3)

          expect(json_response.map { |entry| entry["id"] }).to eq(milestones.map(&:id))
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
      expect(Event).to receive(:create!)

      put api("/projects/#{project.id}/milestones/#{milestone.id}", user),
          params: { state_event: 'close' }
    end
  end

  describe 'POST /projects/:id/milestones/:milestone_id/promote' do
    let(:group) { create(:group) }

    before do
      project.update(namespace: group)
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
        project.update(namespace: user.namespace)
      end

      it 'returns 403' do
        post api("/projects/#{project.id}/milestones/#{milestone.id}/promote", user)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end
end
