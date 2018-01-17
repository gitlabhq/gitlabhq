require 'spec_helper'

describe API::ProjectMilestones do
  let(:user) { create(:user) }
  let!(:project) { create(:project, namespace: user.namespace ) }
  let!(:closed_milestone) { create(:closed_milestone, project: project, title: 'version1', description: 'closed milestone') }
  let!(:milestone) { create(:milestone, project: project, title: 'version2', description: 'open milestone') }

  before do
    project.add_developer(user)
  end

  it_behaves_like 'group and project milestones', "/projects/:id/milestones"  do
    let(:route) { "/projects/#{project.id}/milestones" }
  end

  describe 'DELETE /projects/:id/milestones/:milestone_id' do
    let(:guest) { create(:user) }
    let(:reporter) { create(:user) }

    before do
      project.add_reporter(reporter)
    end

    it 'returns 404 response when the project does not exists' do
      delete api("/projects/999/milestones/#{milestone.id}", user)

      expect(response).to have_gitlab_http_status(404)
    end

    it 'returns 404 response when the milestone does not exists' do
      delete api("/projects/#{project.id}/milestones/999", user)

      expect(response).to have_gitlab_http_status(404)
    end

    it "returns 404 from guest user deleting a milestone" do
      delete api("/projects/#{project.id}/milestones/#{milestone.id}", guest)

      expect(response).to have_gitlab_http_status(404)
    end

    it "rejects a member with reporter access from deleting a milestone" do
      delete api("/projects/#{project.id}/milestones/#{milestone.id}", reporter)

      expect(response).to have_gitlab_http_status(403)
    end

    it 'deletes the milestone when the user has developer access to the project' do
      delete api("/projects/#{project.id}/milestones/#{milestone.id}", user)

      expect(project.milestones.find_by_id(milestone.id)).to be_nil
      expect(response).to have_gitlab_http_status(204)
    end
  end

  describe 'PUT /projects/:id/milestones/:milestone_id to test observer on close' do
    it 'creates an activity event when an milestone is closed' do
      expect(Event).to receive(:create!)

      put api("/projects/#{project.id}/milestones/#{milestone.id}", user),
          state_event: 'close'
    end
  end
end
