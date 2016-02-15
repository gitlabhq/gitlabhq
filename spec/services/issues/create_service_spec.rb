require 'spec_helper'

describe Issues::CreateService, services: true do
  let(:project) { create(:empty_project) }
  let(:user) { create(:user) }
  let(:assignee) { create(:user) }

  describe :execute do
    context 'valid params' do
      before do
        project.team << [user, :master]
        project.team << [assignee, :master]

        opts = {
          title: 'Awesome issue',
          description: 'please fix',
          assignee: assignee
        }

        @issue = Issues::CreateService.new(project, user, opts).execute
      end

      it { expect(@issue).to be_valid }
      it { expect(@issue.title).to eq('Awesome issue') }
      it { expect(@issue.assignee).to eq assignee }

      it 'creates a pending task for new assignee' do
        attributes = {
          project: project,
          author: user,
          user: assignee,
          target: @issue,
          action: Task::ASSIGNED,
          state: :pending
        }

        expect(Task.where(attributes).count).to eq 1
      end
    end
  end
end
