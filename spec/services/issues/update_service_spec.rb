require 'spec_helper'

describe Issues::UpdateService, services: true do
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let(:user3) { create(:user) }
  let(:issue) { create(:issue, title: 'Old title', assignee_id: user3.id) }
  let(:label) { create(:label) }
  let(:project) { issue.project }

  before do
    project.team << [user, :master]
    project.team << [user2, :developer]
    project.team << [user3, :developer]
  end

  describe 'execute' do
    def find_note(starting_with)
      @issue.notes.find do |note|
        note && note.note.start_with?(starting_with)
      end
    end

    def update_issue(opts)
      @issue = Issues::UpdateService.new(project, user, opts).execute(issue)
      @issue.reload
    end

    context "valid params" do
      before do
        opts = {
          title: 'New title',
          description: 'Also please fix',
          assignee_id: user2.id,
          state_event: 'close',
          label_ids: [label.id]
        }

        perform_enqueued_jobs do
          @issue = Issues::UpdateService.new(project, user, opts).execute(issue)
        end

        @issue.reload
      end

      it { expect(@issue).to be_valid }
      it { expect(@issue.title).to eq('New title') }
      it { expect(@issue.assignee).to eq(user2) }
      it { expect(@issue).to be_closed }
      it { expect(@issue.labels.count).to eq(1) }
      it { expect(@issue.labels.first.title).to eq('Bug') }

      it 'should send email to user2 about assign of new issue and email to user3 about issue unassignment' do
        deliveries = ActionMailer::Base.deliveries
        email = deliveries.last
        recipients = deliveries.last(2).map(&:to).flatten
        expect(recipients).to include(user2.email, user3.email)
        expect(email.subject).to include(issue.title)
      end

      it 'should create system note about issue reassign' do
        note = find_note('Reassigned to')

        expect(note).not_to be_nil
        expect(note.note).to include "Reassigned to \@#{user2.username}"
      end

      it 'should create system note about issue label edit' do
        note = find_note('Added ~')

        expect(note).not_to be_nil
        expect(note.note).to include "Added ~#{label.id} label"
      end

      it 'creates system note about title change' do
        note = find_note('Title changed')

        expect(note).not_to be_nil
        expect(note.note).to eq 'Title changed from **Old title** to **New title**'
      end
    end

    context 'todos' do
      let!(:todo) { create(:todo, :assigned, user: user, project: project, target: issue, author: user2) }

      context 'when the title change' do
        before do
          update_issue({ title: 'New title' })
        end

        it 'marks pending todos as done' do
          expect(todo.reload.done?).to eq true
        end
      end

      context 'when the description change' do
        before do
          update_issue({ description: 'Also please fix' })
        end

        it 'marks todos as done' do
          expect(todo.reload.done?).to eq true
        end
      end

      context 'when is reassigned' do
        before do
          update_issue({ assignee: user2 })
        end

        it 'marks previous assignee todos as done' do
          expect(todo.reload.done?).to eq true
        end

        it 'creates a todo for new assignee' do
          attributes = {
            project: project,
            author: user,
            user: user2,
            target_id: issue.id,
            target_type: issue.class.name,
            action: Todo::ASSIGNED,
            state: :pending
          }

          expect(Todo.where(attributes).count).to eq 1
        end
      end

      context 'when the milestone change' do
        before do
          update_issue({ milestone: create(:milestone) })
        end

        it 'marks todos as done' do
          expect(todo.reload.done?).to eq true
        end
      end

      context 'when the labels change' do
        before do
          update_issue({ label_ids: [label.id] })
        end

        it 'marks todos as done' do
          expect(todo.reload.done?).to eq true
        end
      end
    end

    context 'when Issue has tasks' do
      before { update_issue({ description: "- [ ] Task 1\n- [ ] Task 2" }) }

      it { expect(@issue.tasks?).to eq(true) }

      context 'when tasks are marked as completed' do
        before { update_issue({ description: "- [x] Task 1\n- [X] Task 2" }) }

        it 'creates system note about task status change' do
          note1 = find_note('Marked the task **Task 1** as completed')
          note2 = find_note('Marked the task **Task 2** as completed')

          expect(note1).not_to be_nil
          expect(note2).not_to be_nil
        end
      end

      context 'when tasks are marked as incomplete' do
        before do
          update_issue({ description: "- [x] Task 1\n- [X] Task 2" })
          update_issue({ description: "- [ ] Task 1\n- [ ] Task 2" })
        end

        it 'creates system note about task status change' do
          note1 = find_note('Marked the task **Task 1** as incomplete')
          note2 = find_note('Marked the task **Task 2** as incomplete')

          expect(note1).not_to be_nil
          expect(note2).not_to be_nil
        end
      end

      context 'when tasks position has been modified' do
        before do
          update_issue({ description: "- [x] Task 1\n- [X] Task 2" })
          update_issue({ description: "- [x] Task 1\n- [ ] Task 3\n- [ ] Task 2" })
        end

        it 'does not create a system note' do
          note = find_note('Marked the task **Task 2** as incomplete')

          expect(note).to be_nil
        end
      end

      context 'when a Task list with a completed item is totally replaced' do
        before do
          update_issue({ description: "- [ ] Task 1\n- [X] Task 2" })
          update_issue({ description: "- [ ] One\n- [ ] Two\n- [ ] Three" })
        end

        it 'does not create a system note referencing the position the old item' do
          note = find_note('Marked the task **Two** as incomplete')

          expect(note).to be_nil
        end

        it 'should not generate a new note at all' do
          expect do
            update_issue({ description: "- [ ] One\n- [ ] Two\n- [ ] Three" })
          end.not_to change { Note.count }
        end
      end
    end
  end
end
