require 'spec_helper'

describe API::ProjectMilestones do
  let(:user) { create(:user) }
  let!(:project) { create(:empty_project, namespace: user.namespace ) }
  let!(:closed_milestone) { create(:closed_milestone, project: project, title: 'version1', description: 'closed milestone') }
  let!(:milestone) { create(:milestone, project: project, title: 'version2', description: 'open milestone') }

  before do
    project.team << [user, :developer]
  end

  it_behaves_like 'group and project milestones', "/projects/:id/milestones"  do
    let(:route) { "/projects/#{project.id}/milestones" }
  end

  describe 'PUT /projects/:id/milestones/:milestone_id to test observer on close' do
    it 'creates an activity event when an milestone is closed' do
      expect(Event).to receive(:create)

      put api("/projects/#{project.id}/milestones/#{milestone.id}", user),
          state_event: 'close'
    end
  end
end
