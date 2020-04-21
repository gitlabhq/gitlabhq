# frozen_string_literal: true

require 'spec_helper'

describe API::ProjectMilestones do
  let(:user) { create(:user) }
  let!(:project) { create(:project, namespace: user.namespace ) }
  let!(:closed_milestone) { create(:closed_milestone, project: project, title: 'version1', description: 'closed milestone') }
  let!(:milestone) { create(:milestone, project: project, title: 'version2', description: 'open milestone') }

  before do
    project.add_developer(user)
  end

  it_behaves_like 'group and project milestones', "/projects/:id/milestones" do
    let(:route) { "/projects/#{project.id}/milestones" }
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
