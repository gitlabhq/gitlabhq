require 'spec_helper'

describe Issues::CreateService, services: true do
  let(:project) { create(:empty_project) }
  let(:user) { create(:user) }
  let(:assignee) { create(:user) }

  describe :execute do
    let(:issue) { Issues::CreateService.new(project, user, opts).execute }

    context 'valid params' do
      before do
        project.team << [user, :master]
        project.team << [assignee, :master]
      end

      let(:opts) do
        { title: 'Awesome issue',
          description: 'please fix',
          assignee: assignee }
      end

      it { expect(issue).to be_valid }
      it { expect(issue.title).to eq('Awesome issue') }
      it { expect(issue.assignee).to eq assignee }

      it 'creates a pending todo for new assignee' do
        attributes = {
          project: project,
          author: user,
          user: assignee,
          target_id: issue.id,
          target_type: issue.class.name,
          action: Todo::ASSIGNED,
          state: :pending
        }

        expect(Todo.where(attributes).count).to eq 1
      end

      context 'label that belongs to different project' do
        let(:label) { create(:label) }

        let(:opts) do
          { title: 'Title',
            description: 'Description',
            label_ids: [label.id] }
        end

        it 'does not assign label'do
          expect(issue.labels).to_not include label
        end
      end

      context 'milestone that belongs to different project' do
        let(:milestone) { create(:milestone) }

        let(:opts) do
          { title: 'Title',
            description: 'Description',
            milestone_id: milestone.id }
        end

        it 'does not assign milestone' do
          expect(issue.milestone).to_not eq milestone
        end
      end
    end
  end
end
