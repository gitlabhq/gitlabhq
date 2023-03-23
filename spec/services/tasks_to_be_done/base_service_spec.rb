# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TasksToBeDone::BaseService, feature_category: :team_planning do
  let_it_be(:project) { create(:project) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:assignee_one) { create(:user) }
  let_it_be(:assignee_two) { create(:user) }
  let_it_be(:assignee_ids) { [assignee_one.id] }
  let_it_be(:label) { create(:label, title: 'tasks to be done:ci', project: project) }

  before do
    project.add_maintainer(current_user)
    project.add_developer(assignee_one)
    project.add_developer(assignee_two)
  end

  subject(:service) do
    TasksToBeDone::CreateCiTaskService.new(
      container: project,
      current_user: current_user,
      assignee_ids: assignee_ids
    )
  end

  context 'no existing task issue', :aggregate_failures do
    it 'creates an issue' do
      params = {
        assignee_ids: assignee_ids,
        title: 'Set up CI/CD',
        description: anything,
        add_labels: label.title
      }

      expect(Issues::CreateService)
        .to receive(:new)
        .with(container: project, current_user: current_user, params: params, spam_params: nil)
        .and_call_original

      expect { service.execute }.to change(Issue, :count).by(1)

      expect(project.issues.last).to have_attributes(
        author: current_user,
        title: params[:title],
        assignees: [assignee_one],
        labels: [label]
      )
    end
  end

  context 'an open issue with the same label already exists', :aggregate_failures do
    let_it_be(:assignee_ids) { [assignee_two.id] }

    it 'assigns the user to the existing issue' do
      issue = create(:labeled_issue, project: project, labels: [label], assignees: [assignee_one])
      params = { add_assignee_ids: assignee_ids }

      expect(Issues::UpdateService)
        .to receive(:new)
        .with(container: project, current_user: current_user, params: params)
        .and_call_original

      expect { service.execute }.not_to change(Issue, :count)

      expect(issue.reload.assignees).to match_array([assignee_one, assignee_two])
    end
  end
end
