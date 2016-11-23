# coding: utf-8
require 'spec_helper'

describe Issues::UpdateService, services: true do
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let(:user3) { create(:user) }
  let(:project) { create(:empty_project) }
  let(:label) { create(:label, project: project) }
  let(:label2) { create(:label) }

  let(:issue) do
    create(:issue, title: 'Old title',
                   assignee_id: user3.id,
                   project: project)
  end

  before do
    project.team << [user, :master]
    project.team << [user2, :developer]
    project.team << [user3, :developer]
  end

  describe 'execute' do
    def find_note(starting_with)
      issue.notes.find do |note|
        note && note.note.start_with?(starting_with)
      end
    end

    def update_issue(opts)
      described_class.new(project, user, opts).execute(issue)
    end

    context 'valid params' do
      let(:opts) do
        {
          title: 'New title',
          description: 'Also please fix',
          assignee_id: user2.id,
          state_event: 'close',
          label_ids: [label.id],
          due_date: Date.tomorrow
        }
      end

      it 'updates the issue with the given params' do
        update_issue(opts)

        expect(issue).to be_valid
        expect(issue.title).to eq 'New title'
        expect(issue.description).to eq 'Also please fix'
        expect(issue.assignee).to eq user2
        expect(issue).to be_closed
        expect(issue.labels).to match_array [label]
        expect(issue.due_date).to eq Date.tomorrow
      end

      context 'when current user cannot admin issues in the project' do
        let(:guest) { create(:user) }
        before do
          project.team << [guest, :guest]
        end

        it 'filters out params that cannot be set without the :admin_issue permission' do
          described_class.new(project, guest, opts).execute(issue)

          expect(issue).to be_valid
          expect(issue.title).to eq 'New title'
          expect(issue.description).to eq 'Also please fix'
          expect(issue.assignee).to eq user3
          expect(issue.labels).to be_empty
          expect(issue.milestone).to be_nil
          expect(issue.due_date).to be_nil
        end
      end

      context 'with background jobs processed' do
        before do
          perform_enqueued_jobs do
            update_issue(opts)
          end
        end

        it 'sends email to user2 about assign of new issue and email to user3 about issue unassignment' do
          deliveries = ActionMailer::Base.deliveries
          email = deliveries.last
          recipients = deliveries.last(2).map(&:to).flatten
          expect(recipients).to include(user2.email, user3.email)
          expect(email.subject).to include(issue.title)
        end

        it 'creates system note about issue reassign' do
          note = find_note('assigned to')

          expect(note).not_to be_nil
          expect(note.note).to include "assigned to #{user2.to_reference}"
        end

        it 'creates system note about issue label edit' do
          note = find_note('added ~')

          expect(note).not_to be_nil
          expect(note.note).to include "added #{label.to_reference} label"
        end

        it 'creates system note about title change' do
          note = find_note('changed title')

          expect(note).not_to be_nil
          expect(note.note).to eq 'changed title from **{-Old-} title** to **{+New+} title**'
        end
      end
    end

    context 'when issue turns confidential' do
      let(:opts) do
        {
          title: 'New title',
          description: 'Also please fix',
          assignee_id: user2.id,
          state_event: 'close',
          label_ids: [label.id],
          confidential: true
        }
      end

      it 'creates system note about confidentiality change' do
        update_issue(confidential: true)

        note = find_note('made the issue confidential')

        expect(note).not_to be_nil
        expect(note.note).to eq 'made the issue confidential'
      end

      it 'executes confidential issue hooks' do
        expect(project).to receive(:execute_hooks).with(an_instance_of(Hash), :confidential_issue_hooks)
        expect(project).to receive(:execute_services).with(an_instance_of(Hash), :confidential_issue_hooks)

        update_issue(confidential: true)
      end
    end

    context 'todos' do
      let!(:todo) { create(:todo, :assigned, user: user, project: project, target: issue, author: user2) }

      context 'when the title change' do
        before do
          update_issue(title: 'New title')
        end

        it 'marks pending todos as done' do
          expect(todo.reload.done?).to eq true
        end
      end

      context 'when the description change' do
        before do
          update_issue(description: 'Also please fix')
        end

        it 'marks todos as done' do
          expect(todo.reload.done?).to eq true
        end
      end

      context 'when is reassigned' do
        before do
          update_issue(assignee: user2)
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
          update_issue(milestone: create(:milestone))
        end

        it 'marks todos as done' do
          expect(todo.reload.done?).to eq true
        end
      end

      context 'when the labels change' do
        before do
          update_issue(label_ids: [label.id])
        end

        it 'marks todos as done' do
          expect(todo.reload.done?).to eq true
        end
      end
    end

    context 'when the issue is relabeled' do
      let!(:non_subscriber) { create(:user) }

      let!(:subscriber) do
        create(:user).tap do |u|
          label.toggle_subscription(u, project)
          project.team << [u, :developer]
        end
      end

      it 'sends notifications for subscribers of newly added labels' do
        opts = { label_ids: [label.id] }

        perform_enqueued_jobs do
          @issue = described_class.new(project, user, opts).execute(issue)
        end

        should_email(subscriber)
        should_not_email(non_subscriber)
      end

      context 'when issue has the `label` label' do
        before { issue.labels << label }

        it 'does not send notifications for existing labels' do
          opts = { label_ids: [label.id, label2.id] }

          perform_enqueued_jobs do
            @issue = described_class.new(project, user, opts).execute(issue)
          end

          should_not_email(subscriber)
          should_not_email(non_subscriber)
        end

        it 'does not send notifications for removed labels' do
          opts = { label_ids: [label2.id] }

          perform_enqueued_jobs do
            @issue = described_class.new(project, user, opts).execute(issue)
          end

          should_not_email(subscriber)
          should_not_email(non_subscriber)
        end
      end
    end

    context 'when issue has tasks' do
      before do
        update_issue(description: "- [ ] Task 1\n- [ ] Task 2")
      end

      it { expect(issue.tasks?).to eq(true) }

      context 'when tasks are marked as completed' do
        before { update_issue(description: "- [x] Task 1\n- [X] Task 2") }

        it 'creates system note about task status change' do
          note1 = find_note('marked the task **Task 1** as completed')
          note2 = find_note('marked the task **Task 2** as completed')

          expect(note1).not_to be_nil
          expect(note2).not_to be_nil
        end
      end

      context 'when tasks are marked as incomplete' do
        before do
          update_issue(description: "- [x] Task 1\n- [X] Task 2")
          update_issue(description: "- [ ] Task 1\n- [ ] Task 2")
        end

        it 'creates system note about task status change' do
          note1 = find_note('marked the task **Task 1** as incomplete')
          note2 = find_note('marked the task **Task 2** as incomplete')

          expect(note1).not_to be_nil
          expect(note2).not_to be_nil
        end
      end

      context 'when tasks position has been modified' do
        before do
          update_issue(description: "- [x] Task 1\n- [X] Task 2")
          update_issue(description: "- [x] Task 1\n- [ ] Task 3\n- [ ] Task 2")
        end

        it 'does not create a system note' do
          note = find_note('marked the task **Task 2** as incomplete')

          expect(note).to be_nil
        end
      end

      context 'when a Task list with a completed item is totally replaced' do
        before do
          update_issue(description: "- [ ] Task 1\n- [X] Task 2")
          update_issue(description: "- [ ] One\n- [ ] Two\n- [ ] Three")
        end

        it 'does not create a system note referencing the position the old item' do
          note = find_note('marked the task **Two** as incomplete')

          expect(note).to be_nil
        end

        it 'does not generate a new note at all' do
          expect do
            update_issue(description: "- [ ] One\n- [ ] Two\n- [ ] Three")
          end.not_to change { Note.count }
        end
      end
    end

    context 'updating labels' do
      let(:label3) { create(:label, project: project) }
      let(:result) { described_class.new(project, user, params).execute(issue).reload }

      context 'when add_label_ids and label_ids are passed' do
        let(:params) { { label_ids: [label.id], add_label_ids: [label3.id] } }

        it 'ignores the label_ids parameter' do
          expect(result.label_ids).not_to include(label.id)
        end

        it 'adds the passed labels' do
          expect(result.label_ids).to include(label3.id)
        end
      end

      context 'when remove_label_ids and label_ids are passed' do
        let(:params) { { label_ids: [], remove_label_ids: [label.id] } }

        before { issue.update_attributes(labels: [label, label3]) }

        it 'ignores the label_ids parameter' do
          expect(result.label_ids).not_to be_empty
        end

        it 'removes the passed labels' do
          expect(result.label_ids).not_to include(label.id)
        end
      end

      context 'when add_label_ids and remove_label_ids are passed' do
        let(:params) { { add_label_ids: [label3.id], remove_label_ids: [label.id] } }

        before { issue.update_attributes(labels: [label]) }

        it 'adds the passed labels' do
          expect(result.label_ids).to include(label3.id)
        end

        it 'removes the passed labels' do
          expect(result.label_ids).not_to include(label.id)
        end
      end
    end

    context 'updating mentions' do
      let(:mentionable) { issue }
      include_examples 'updating mentions', Issues::UpdateService
    end
  end
end
