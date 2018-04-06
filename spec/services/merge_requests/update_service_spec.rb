require 'spec_helper'

describe MergeRequests::UpdateService, :mailer do
  include ProjectForksHelper

  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let(:user3) { create(:user) }
  let(:label) { create(:label, project: project) }
  let(:label2) { create(:label) }

  let(:merge_request) do
    create(:merge_request, :simple, title: 'Old title',
                                    description: "FYI #{user2.to_reference}",
                                    assignee_id: user3.id,
                                    source_project: project,
                                    author: create(:user))
  end

  before do
    project.add_master(user)
    project.add_developer(user2)
    project.add_developer(user3)
  end

  describe 'execute' do
    def find_note(starting_with)
      @merge_request.notes.find do |note|
        note && note.note.start_with?(starting_with)
      end
    end

    def find_notes(action)
      @merge_request
        .notes
        .joins(:system_note_metadata)
        .where(system_note_metadata: { action: action })
    end

    def update_merge_request(opts)
      @merge_request = MergeRequests::UpdateService.new(project, user, opts).execute(merge_request)
      @merge_request.reload
    end

    context 'valid params' do
      let(:opts) do
        {
          title: 'New title',
          description: 'Also please fix',
          assignee_id: user2.id,
          state_event: 'close',
          label_ids: [label.id],
          target_branch: 'target',
          force_remove_source_branch: '1',
          discussion_locked: true
        }
      end

      let(:service) { described_class.new(project, user, opts) }

      before do
        allow(service).to receive(:execute_hooks)

        perform_enqueued_jobs do
          @merge_request = service.execute(merge_request)
          @merge_request.reload
        end
      end

      it 'matches base expectations' do
        expect(@merge_request).to be_valid
        expect(@merge_request.title).to eq('New title')
        expect(@merge_request.assignee).to eq(user2)
        expect(@merge_request).to be_closed
        expect(@merge_request.labels.count).to eq(1)
        expect(@merge_request.labels.first.title).to eq(label.name)
        expect(@merge_request.target_branch).to eq('target')
        expect(@merge_request.merge_params['force_remove_source_branch']).to eq('1')
        expect(@merge_request.discussion_locked).to be_truthy
      end

      it 'executes hooks with update action' do
        expect(service).to have_received(:execute_hooks)
          .with(
            @merge_request,
            'update',
            old_associations: {
              labels: [],
              mentioned_users: [user2],
              assignees: [user3],
              total_time_spent: 0
            }
          )
      end

      it 'sends email to user2 about assign of new merge request and email to user3 about merge request unassignment' do
        deliveries = ActionMailer::Base.deliveries
        email = deliveries.last
        recipients = deliveries.last(2).map(&:to).flatten
        expect(recipients).to include(user2.email, user3.email)
        expect(email.subject).to include(merge_request.title)
      end

      it 'creates system note about merge_request reassign' do
        note = find_note('assigned to')

        expect(note).not_to be_nil
        expect(note.note).to include "assigned to #{user2.to_reference}"
      end

      it 'creates system note about merge_request label edit' do
        note = find_note('added ~')

        expect(note).not_to be_nil
        expect(note.note).to include "added #{label.to_reference} label"
      end

      it 'creates system note about title change' do
        note = find_note('changed title')

        expect(note).not_to be_nil
        expect(note.note).to eq 'changed title from **{-Old-} title** to **{+New+} title**'
      end

      it 'creates system note about description change' do
        note = find_note('changed the description')

        expect(note).not_to be_nil
        expect(note.note).to eq('changed the description')
      end

      it 'creates system note about branch change' do
        note = find_note('changed target')

        expect(note).not_to be_nil
        expect(note.note).to eq 'changed target branch from `master` to `target`'
      end

      it 'creates system note about discussion lock' do
        note = find_note('locked this merge request')

        expect(note).not_to be_nil
        expect(note.note).to eq 'locked this merge request'
      end

      context 'when not including source branch removal options' do
        before do
          opts.delete(:force_remove_source_branch)
        end

        it 'maintains the original options' do
          update_merge_request(opts)

          expect(@merge_request.merge_params["force_remove_source_branch"]).to eq("1")
        end
      end
    end

    context 'merge' do
      let(:opts) do
        {
          merge: merge_request.diff_head_sha
        }
      end

      let(:service) { described_class.new(project, user, opts) }

      context 'without pipeline' do
        before do
          merge_request.merge_error = 'Error'

          perform_enqueued_jobs do
            service.execute(merge_request)
            @merge_request = MergeRequest.find(merge_request.id)
          end
        end

        it 'merges the MR' do
          expect(@merge_request).to be_valid
          expect(@merge_request.state).to eq('merged')
          expect(@merge_request.merge_error).to be_nil
        end
      end

      context 'with finished pipeline' do
        before do
          create(:ci_pipeline_with_one_job,
            project: project,
            ref:     merge_request.source_branch,
            sha:     merge_request.diff_head_sha,
            status:  :success)

          perform_enqueued_jobs do
            @merge_request = service.execute(merge_request)
            @merge_request = MergeRequest.find(merge_request.id)
          end
        end

        it 'merges the MR' do
          expect(@merge_request).to be_valid
          expect(@merge_request.state).to eq('merged')
        end
      end

      context 'with active pipeline' do
        before do
          service_mock = double
          create(
            :ci_pipeline_with_one_job,
            project: project,
            ref: merge_request.source_branch,
            sha: merge_request.diff_head_sha,
            head_pipeline_of: merge_request
          )

          expect(MergeRequests::MergeWhenPipelineSucceedsService).to receive(:new).with(project, user)
            .and_return(service_mock)
          expect(service_mock).to receive(:execute).with(merge_request)
        end

        it { service.execute(merge_request) }
      end

      context 'with a non-authorised user' do
        let(:visitor) { create(:user) }
        let(:service) { described_class.new(project, visitor, opts) }

        before do
          merge_request.update_attribute(:merge_error, 'Error')

          perform_enqueued_jobs do
            @merge_request = service.execute(merge_request)
            @merge_request = MergeRequest.find(merge_request.id)
          end
        end

        it 'does not merge the MR' do
          expect(@merge_request.state).to eq('opened')
          expect(@merge_request.merge_error).not_to be_nil
        end
      end

      context 'MR can not be merged when note sha != MR sha' do
        let(:opts) do
          {
            merge: 'other_commit'
          }
        end

        before do
          perform_enqueued_jobs do
            @merge_request = service.execute(merge_request)
            @merge_request = MergeRequest.find(merge_request.id)
          end
        end

        it { expect(@merge_request.state).to eq('opened') }
      end

      context 'when not approved' do
        before do
          merge_request.update_attributes(approvals_before_merge: 1)

          perform_enqueued_jobs do
            service.execute(merge_request)
            @merge_request = MergeRequest.find(merge_request.id)
          end
        end

        it { expect(@merge_request).to be_valid }
        it { expect(@merge_request.state).to eq('opened') }
      end

      context 'when approved' do
        before do
          merge_request.update_attributes(approvals_before_merge: 1)
          merge_request.approvals.create(user: user)

          perform_enqueued_jobs do
            service.execute(merge_request)
            @merge_request = MergeRequest.find(merge_request.id)
          end
        end

        it { expect(@merge_request).to be_valid }
        it { expect(@merge_request.state).to eq('merged') }
      end
    end

    context 'todos' do
      let!(:pending_todo) { create(:todo, :assigned, user: user, project: project, target: merge_request, author: user2) }

      context 'when the title change' do
        before do
          update_merge_request({ title: 'New title' })
        end

        it 'marks pending todos as done' do
          expect(pending_todo.reload).to be_done
        end

        it 'does not create any new todos' do
          expect(Todo.count).to eq(1)
        end
      end

      context 'when the description change' do
        before do
          update_merge_request({ description: "Also please fix #{user2.to_reference} #{user3.to_reference}" })
        end

        it 'marks pending todos as done' do
          expect(pending_todo.reload).to be_done
        end

        it 'creates only 1 new todo' do
          expect(Todo.count).to eq(2)
        end
      end

      context 'when is reassigned' do
        before do
          update_merge_request({ assignee: user2 })
        end

        it 'marks previous assignee pending todos as done' do
          expect(pending_todo.reload).to be_done
        end

        it 'creates a pending todo for new assignee' do
          attributes = {
            project: project,
            author: user,
            user: user2,
            target_id: merge_request.id,
            target_type: merge_request.class.name,
            action: Todo::ASSIGNED,
            state: :pending
          }

          expect(Todo.where(attributes).count).to eq 1
        end
      end

      context 'when the milestone change' do
        it 'marks pending todos as done' do
          update_merge_request({ milestone: create(:milestone) })

          expect(pending_todo.reload).to be_done
        end

        it_behaves_like 'system notes for milestones'
      end

      context 'when the labels change' do
        before do
          update_merge_request({ label_ids: [label.id] })
        end

        it 'marks pending todos as done' do
          expect(pending_todo.reload).to be_done
        end
      end

      context 'when the assignee changes' do
        it 'updates open merge request counter for assignees when merge request is reassigned' do
          update_merge_request(assignee_id: user2.id)

          expect(user3.assigned_open_merge_requests_count).to eq 0
          expect(user2.assigned_open_merge_requests_count).to eq 1
        end
      end

      context 'when the target branch change' do
        before do
          update_merge_request({ target_branch: 'target' })
        end

        it 'marks pending todos as done' do
          expect(pending_todo.reload).to be_done
        end
      end
    end

    context 'when the merge request is relabeled' do
      let!(:non_subscriber) { create(:user) }
      let!(:subscriber) { create(:user) { |u| label.toggle_subscription(u, project) } }

      before do
        project.add_developer(non_subscriber)
        project.add_developer(subscriber)
      end

      it 'sends notifications for subscribers of newly added labels' do
        opts = { label_ids: [label.id] }

        perform_enqueued_jobs do
          @merge_request = described_class.new(project, user, opts).execute(merge_request)
        end

        should_email(subscriber)
        should_not_email(non_subscriber)
      end

      context 'when issue has the `label` label' do
        before do
          merge_request.labels << label
        end

        it 'does not send notifications for existing labels' do
          opts = { label_ids: [label.id, label2.id] }

          perform_enqueued_jobs do
            @merge_request = described_class.new(project, user, opts).execute(merge_request)
          end

          should_not_email(subscriber)
          should_not_email(non_subscriber)
        end

        it 'does not send notifications for removed labels' do
          opts = { label_ids: [label2.id] }

          perform_enqueued_jobs do
            @merge_request = described_class.new(project, user, opts).execute(merge_request)
          end

          should_not_email(subscriber)
          should_not_email(non_subscriber)
        end
      end
    end

    context 'when the approvers change' do
      let(:existing_approver) { create(:user) }
      let(:removed_approver) { create(:user) }
      let(:new_approver) { create(:user) }

      before do
        perform_enqueued_jobs do
          update_merge_request(approver_ids: [existing_approver, removed_approver].map(&:id).join(','))
        end

        Todo.where(action: Todo::APPROVAL_REQUIRED).destroy_all
        ActionMailer::Base.deliveries.clear
      end

      context 'when an approver is added and an approver is removed' do
        before do
          perform_enqueued_jobs do
            update_merge_request(approver_ids: [new_approver, existing_approver].map(&:id).join(','))
          end
        end

        it 'adds todos for and sends emails to the new approvers' do
          expect(Todo.where(user: new_approver, action: Todo::APPROVAL_REQUIRED)).not_to be_empty
          should_email(new_approver)
        end

        it 'does not add todos for or send emails to the existing approvers' do
          expect(Todo.where(user: existing_approver, action: Todo::APPROVAL_REQUIRED)).to be_empty
          should_not_email(existing_approver)
        end

        it 'does not add todos for or send emails to the removed approvers' do
          expect(Todo.where(user: removed_approver, action: Todo::APPROVAL_REQUIRED)).to be_empty
          should_not_email(removed_approver)
        end
      end

      context 'when the approvers are set to the same values' do
        it 'does not create any todos' do
          expect do
            update_merge_request(approver_ids: [existing_approver, removed_approver].map(&:id).join(','))
          end.not_to change { Todo.count }
        end

        it 'does not send any emails' do
          expect do
            update_merge_request(approver_ids: [existing_approver, removed_approver].map(&:id).join(','))
          end.not_to change { ActionMailer::Base.deliveries.count }
        end
      end
    end

    context 'updating mentions' do
      let(:mentionable) { merge_request }
      include_examples 'updating mentions', described_class
    end

    context 'when MergeRequest has tasks' do
      before do
        update_merge_request({ description: "- [ ] Task 1\n- [ ] Task 2" })
      end

      it { expect(@merge_request.tasks?).to eq(true) }

      context 'when tasks are marked as completed' do
        before do
          update_merge_request({ description: "- [x] Task 1\n- [X] Task 2" })
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
          update_merge_request({ description: "- [x] Task 1\n- [X] Task 2" })
          update_merge_request({ description: "- [ ] Task 1\n- [ ] Task 2" })
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
    end

    context 'while saving references to issues that the updated merge request closes' do
      let(:first_issue) { create(:issue, project: project) }
      let(:second_issue) { create(:issue, project: project) }

      it 'creates a `MergeRequestsClosingIssues` record for each issue' do
        issue_closing_opts = { description: "Closes #{first_issue.to_reference} and #{second_issue.to_reference}" }
        service = described_class.new(project, user, issue_closing_opts)
        allow(service).to receive(:execute_hooks)
        service.execute(merge_request)

        issue_ids = MergeRequestsClosingIssues.where(merge_request: merge_request).pluck(:issue_id)
        expect(issue_ids).to match_array([first_issue.id, second_issue.id])
      end

      it 'removes `MergeRequestsClosingIssues` records when issues are not closed anymore' do
        opts = {
          title: 'Awesome merge_request',
          description: "Closes #{first_issue.to_reference} and #{second_issue.to_reference}",
          source_branch: 'feature',
          target_branch: 'master',
          force_remove_source_branch: '1'
        }

        merge_request = MergeRequests::CreateService.new(project, user, opts).execute

        issue_ids = MergeRequestsClosingIssues.where(merge_request: merge_request).pluck(:issue_id)
        expect(issue_ids).to match_array([first_issue.id, second_issue.id])

        service = described_class.new(project, user, description: "not closing any issues")
        allow(service).to receive(:execute_hooks)
        service.execute(merge_request.reload)

        issue_ids = MergeRequestsClosingIssues.where(merge_request: merge_request).pluck(:issue_id)
        expect(issue_ids).to be_empty
      end
    end

    context 'updating target_branch' do
      it 'resets approvals when target_branch is changed' do
        merge_request.target_project.update(reset_approvals_on_push: true, approvals_before_merge: 2)
        merge_request.approvals.create(user_id: user2.id)

        update_merge_request(target_branch: 'video')

        expect(merge_request.reload.approvals).to be_empty
      end
    end

    context 'updating asssignee_id' do
      it 'does not update assignee when assignee_id is invalid' do
        merge_request.update(assignee_id: user.id)

        update_merge_request(assignee_id: -1)

        expect(merge_request.reload.assignee).to eq(user)
      end

      it 'unassigns assignee when user id is 0' do
        merge_request.update(assignee_id: user.id)

        update_merge_request(assignee_id: 0)

        expect(merge_request.assignee_id).to be_nil
      end

      it 'saves assignee when user id is valid' do
        update_merge_request(assignee_id: user.id)

        expect(merge_request.assignee_id).to eq(user.id)
      end

      it 'does not update assignee_id when user cannot read issue' do
        non_member        = create(:user)
        original_assignee = merge_request.assignee

        update_merge_request(assignee_id: non_member.id)

        expect(merge_request.assignee_id).to eq(original_assignee.id)
      end

      context "when issuable feature is private" do
        levels = [Gitlab::VisibilityLevel::INTERNAL, Gitlab::VisibilityLevel::PUBLIC]

        levels.each do |level|
          it "does not update with unauthorized assignee when project is #{Gitlab::VisibilityLevel.level_name(level)}" do
            assignee = create(:user)
            project.update(visibility_level: level)
            feature_visibility_attr = :"#{merge_request.model_name.plural}_access_level"
            project.project_feature.update_attribute(feature_visibility_attr, ProjectFeature::PRIVATE)

            expect { update_merge_request(assignee_id: assignee) }.not_to change { merge_request.assignee }
          end
        end
      end
    end

    include_examples 'issuable update service' do
      let(:open_issuable) { merge_request }
      let(:closed_issuable) { create(:closed_merge_request, source_project: project) }
    end

    context 'setting `allow_maintainer_to_push`' do
      let(:target_project) { create(:project, :public) }
      let(:source_project) { fork_project(target_project) }
      let(:user) { create(:user) }
      let(:merge_request) do
        create(:merge_request,
               source_project: source_project,
               source_branch: 'fixes',
               target_project: target_project)
      end

      before do
        allow(ProtectedBranch).to receive(:protected?).with(source_project, 'fixes') { false }
      end

      it 'does not allow a maintainer of the target project to set `allow_maintainer_to_push`' do
        target_project.add_developer(user)

        update_merge_request(allow_maintainer_to_push: true, title: 'Updated title')

        expect(merge_request.title).to eq('Updated title')
        expect(merge_request.allow_maintainer_to_push).to be_falsy
      end

      it 'is allowed by a user that can push to the source and can update the merge request' do
        merge_request.update!(assignee: user)
        source_project.add_developer(user)

        update_merge_request(allow_maintainer_to_push: true, title: 'Updated title')

        expect(merge_request.title).to eq('Updated title')
        expect(merge_request.allow_maintainer_to_push).to be_truthy
      end
    end
  end
end
