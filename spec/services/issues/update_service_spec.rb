# coding: utf-8
require 'spec_helper'

describe Issues::UpdateService, :mailer do
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let(:user3) { create(:user) }
  let(:project) { create(:project) }
  let(:label) { create(:label, project: project) }
  let(:label2) { create(:label) }

  let(:issue) do
    create(:issue, title: 'Old title',
                   description: "for #{user2.to_reference}",
                   assignee_ids: [user3.id],
                   project: project,
                   author: create(:user))
  end

  before do
    project.add_master(user)
    project.add_developer(user2)
    project.add_developer(user3)
  end

  describe 'execute' do
    def find_note(starting_with)
      issue.notes.find do |note|
        note && note.note.start_with?(starting_with)
      end
    end

    def find_notes(action)
      issue
        .notes
        .joins(:system_note_metadata)
        .where(system_note_metadata: { action: action })
    end

    def update_issue(opts)
      described_class.new(project, user, opts).execute(issue)
    end

    context 'valid params' do
      let(:opts) do
        {
          title: 'New title',
          description: 'Also please fix',
          assignee_ids: [user2.id],
          state_event: 'close',
          label_ids: [label.id],
          due_date: Date.tomorrow,
          discussion_locked: true
        }
      end

      it 'updates the issue with the given params' do
        update_issue(opts)

        expect(issue).to be_valid
        expect(issue.title).to eq 'New title'
        expect(issue.description).to eq 'Also please fix'
        expect(issue.assignees).to match_array([user2])
        expect(issue).to be_closed
        expect(issue.labels).to match_array [label]
        expect(issue.due_date).to eq Date.tomorrow
        expect(issue.discussion_locked).to be_truthy
      end

      it 'refreshes the number of open issues when the issue is made confidential', :use_clean_rails_memory_store_caching do
        issue # make sure the issue is created first so our counts are correct.

        expect { update_issue(confidential: true) }
          .to change { project.open_issues_count }.from(1).to(0)
      end

      it 'updates open issue counter for assignees when issue is reassigned' do
        update_issue(assignee_ids: [user2.id])

        expect(user3.assigned_open_issues_count).to eq 0
        expect(user2.assigned_open_issues_count).to eq 1
      end

      it 'sorts issues as specified by parameters' do
        issue1 = create(:issue, project: project, assignees: [user3])
        issue2 = create(:issue, project: project, assignees: [user3])

        [issue, issue1, issue2].each do |issue|
          issue.move_to_end
          issue.save
        end

        opts[:move_between_ids] = [issue1.id, issue2.id]

        update_issue(opts)

        expect(issue.relative_position).to be_between(issue1.relative_position, issue2.relative_position)
      end

      context 'when moving issue between issues from different projects' do
        let(:group) { create(:group) }
        let(:project_1) { create(:project, namespace: group) }
        let(:project_2) { create(:project, namespace: group) }
        let(:project_3) { create(:project, namespace: group) }

        let(:issue_1) { create(:issue, project: project_1) }
        let(:issue_2) { create(:issue, project: project_2) }
        let(:issue_3) { create(:issue, project: project_3) }

        before do
          group.add_developer(user)
        end

        it 'sorts issues as specified by parameters' do
          # Moving all issues to end here like the last example won't work since
          # all projects only have the same issue count
          # so their relative_position will be the same.
          issue_1.move_to_end
          issue_2.move_after(issue_1)
          issue_3.move_after(issue_2)
          [issue_1, issue_2, issue_3].map(&:save)

          opts[:move_between_ids] = [issue_1.id, issue_2.id]
          opts[:board_group_id] = group.id

          described_class.new(issue_3.project, user, opts).execute(issue_3)
          expect(issue_2.relative_position).to be_between(issue_1.relative_position, issue_2.relative_position)
        end
      end

      context 'when current user cannot admin issues in the project' do
        let(:guest) { create(:user) }
        before do
          project.add_guest(guest)
        end

        it 'filters out params that cannot be set without the :admin_issue permission' do
          described_class.new(project, guest, opts).execute(issue)

          expect(issue).to be_valid
          expect(issue.title).to eq 'New title'
          expect(issue.description).to eq 'Also please fix'
          expect(issue.assignees).to match_array [user3]
          expect(issue.labels).to be_empty
          expect(issue.milestone).to be_nil
          expect(issue.due_date).to be_nil
          expect(issue.discussion_locked).to be_falsey
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

        it 'creates system note about discussion lock' do
          note = find_note('locked this issue')

          expect(note).not_to be_nil
          expect(note.note).to eq 'locked this issue'
        end
      end
    end

    context 'when description changed' do
      it 'creates system note about description change' do
        update_issue(description: 'Changed description')

        note = find_note('changed the description')

        expect(note).not_to be_nil
        expect(note.note).to eq('changed the description')
      end
    end

    context 'when issue turns confidential' do
      let(:opts) do
        {
          title: 'New title',
          description: 'Also please fix',
          assignee_ids: [user2],
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

      it 'does not update assignee_id with unauthorized users' do
        project.update(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
        update_issue(confidential: true)
        non_member = create(:user)
        original_assignees = issue.assignees

        update_issue(assignee_ids: [non_member.id])

        expect(issue.reload.assignees).to eq(original_assignees)
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

        it 'does not create any new todos' do
          expect(Todo.count).to eq(1)
        end
      end

      context 'when the description change' do
        before do
          update_issue(description: "Also please fix #{user2.to_reference} #{user3.to_reference}")
        end

        it 'marks todos as done' do
          expect(todo.reload.done?).to eq true
        end

        it 'creates only 1 new todo' do
          expect(Todo.count).to eq(2)
        end
      end

      context 'when is reassigned' do
        before do
          update_issue(assignees: [user2])
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

      context 'when a new assignee added' do
        subject { update_issue(assignees: issue.assignees + [user2]) }

        it 'creates only 1 new todo' do
          expect { subject }.to change { Todo.count }.by(1)
        end

        it 'creates a todo for new assignee' do
          subject

          attributes = {
            project: project,
            author: user,
            user: user2,
            target_id: issue.id,
            target_type: issue.class.name,
            action: Todo::ASSIGNED,
            state: :pending
          }

          expect(Todo.where(attributes).count).to eq(1)
        end
      end

      context 'when the milestone change' do
        it 'marks todos as done' do
          update_issue(milestone: create(:milestone))

          expect(todo.reload.done?).to eq true
        end

        it_behaves_like 'system notes for milestones'
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
          project.add_developer(u)
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
        before do
          issue.labels << label
        end

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
        before do
          update_issue(description: "- [x] Task 1\n- [X] Task 2")
        end

        it 'creates system note about task status change' do
          note1 = find_note('marked the task **Task 1** as completed')
          note2 = find_note('marked the task **Task 2** as completed')

          expect(note1).not_to be_nil
          expect(note2).not_to be_nil

          description_notes = find_notes('description')
          expect(description_notes.length).to eq(1)
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

          description_notes = find_notes('description')
          expect(description_notes.length).to eq(1)
        end
      end

      context 'when tasks position has been modified' do
        before do
          update_issue(description: "- [x] Task 1\n- [X] Task 2")
          update_issue(description: "- [x] Task 1\n- [ ] Task 3\n- [ ] Task 2")
        end

        it 'does not create a system note for the task' do
          task_note = find_note('marked the task **Task 2** as incomplete')
          description_notes = find_notes('description')

          expect(task_note).to be_nil
          expect(description_notes.length).to eq(2)
        end
      end

      context 'when a Task list with a completed item is totally replaced' do
        before do
          update_issue(description: "- [ ] Task 1\n- [X] Task 2")
          update_issue(description: "- [ ] One\n- [ ] Two\n- [ ] Three")
        end

        it 'does not create a system note referencing the position the old item' do
          task_note = find_note('marked the task **Two** as incomplete')
          description_notes = find_notes('description')

          expect(task_note).to be_nil
          expect(description_notes.length).to eq(2)
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

        before do
          issue.update_attributes(labels: [label, label3])
        end

        it 'ignores the label_ids parameter' do
          expect(result.label_ids).not_to be_empty
        end

        it 'removes the passed labels' do
          expect(result.label_ids).not_to include(label.id)
        end
      end

      context 'when add_label_ids and remove_label_ids are passed' do
        let(:params) { { add_label_ids: [label3.id], remove_label_ids: [label.id] } }

        before do
          issue.update_attributes(labels: [label])
        end

        it 'adds the passed labels' do
          expect(result.label_ids).to include(label3.id)
        end

        it 'removes the passed labels' do
          expect(result.label_ids).not_to include(label.id)
        end
      end
    end

    context 'updating asssignee_id' do
      it 'does not update assignee when assignee_id is invalid' do
        update_issue(assignee_ids: [-1])

        expect(issue.reload.assignees).to eq([user3])
      end

      it 'unassigns assignee when user id is 0' do
        update_issue(assignee_ids: [0])

        expect(issue.reload.assignees).to be_empty
      end

      it 'does not update assignee_id when user cannot read issue' do
        update_issue(assignee_ids: [create(:user).id])

        expect(issue.reload.assignees).to eq([user3])
      end

      context "when issuable feature is private" do
        levels = [Gitlab::VisibilityLevel::INTERNAL, Gitlab::VisibilityLevel::PUBLIC]

        levels.each do |level|
          it "does not update with unauthorized assignee when project is #{Gitlab::VisibilityLevel.level_name(level)}" do
            assignee = create(:user)
            project.update(visibility_level: level)
            feature_visibility_attr = :"#{issue.model_name.plural}_access_level"
            project.project_feature.update_attribute(feature_visibility_attr, ProjectFeature::PRIVATE)

            expect { update_issue(assignee_ids: [assignee.id]) }.not_to change { issue.assignees }
          end
        end
      end
    end

    context 'updating mentions' do
      let(:mentionable) { issue }
      include_examples 'updating mentions', described_class
    end

    context 'duplicate issue' do
      let(:canonical_issue) { create(:issue, project: project) }

      context 'invalid canonical_issue_id' do
        it 'does not call the duplicate service' do
          expect(Issues::DuplicateService).not_to receive(:new)

          update_issue(canonical_issue_id: 123456789)
        end
      end

      context 'valid canonical_issue_id' do
        it 'calls the duplicate service with both issues' do
          expect_any_instance_of(Issues::DuplicateService)
            .to receive(:execute).with(issue, canonical_issue)

          update_issue(canonical_issue_id: canonical_issue.id)
        end
      end
    end

    context 'move issue to another project' do
      let(:target_project) { create(:project) }

      context 'valid project' do
        before do
          target_project.add_master(user)
        end

        it 'calls the move service with the proper issue and project' do
          move_stub = instance_double(Issues::MoveService)
          allow(Issues::MoveService).to receive(:new).and_return(move_stub)
          allow(move_stub).to receive(:execute).with(issue, target_project).and_return(issue)

          expect(move_stub).to receive(:execute).with(issue, target_project)

          update_issue(target_project: target_project)
        end
      end
    end

    include_examples 'issuable update service' do
      let(:open_issuable) { issue }
      let(:closed_issuable) { create(:closed_issue, project: project) }
    end
  end
end
