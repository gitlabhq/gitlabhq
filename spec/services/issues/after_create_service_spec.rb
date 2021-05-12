# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issues::AfterCreateService do
  include AfterNextHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:assignee) { create(:user) }
  let_it_be(:milestone) { create(:milestone, project: project) }
  let_it_be(:issue) { create(:issue, project: project, author: current_user, milestone: milestone, assignee_ids: [assignee.id]) }

  subject(:after_create_service) { described_class.new(project: project, current_user: current_user) }

  describe '#execute' do
    it 'creates a pending todo for new assignee' do
      attributes = {
        project: project,
        author: current_user,
        user: assignee,
        target_id: issue.id,
        target_type: issue.class.name,
        action: Todo::ASSIGNED,
        state: :pending
      }

      expect { after_create_service.execute(issue) }.to change { Todo.where(attributes).count }.by(1)
    end

    it 'deletes milestone issues count cache' do
      expect_next(Milestones::IssuesCountService, milestone)
        .to receive(:delete_cache).and_call_original

      after_create_service.execute(issue)
    end

    context 'with a regular issue' do
      it_behaves_like 'does not track incident management event', :incident_management_incident_created do
        subject { after_create_service.execute(issue) }
      end
    end

    context 'with an incident issue' do
      let(:issue) { create(:issue, :incident, project: project, author: current_user) }

      it_behaves_like 'an incident management tracked event', :incident_management_incident_created do
        subject { after_create_service.execute(issue) }
      end
    end
  end
end
