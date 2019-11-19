# frozen_string_literal: true

require 'spec_helper'

describe MergeRequests::UpdateService, :mailer do
  include ProjectForksHelper

  let(:group) { create(:group, :public) }
  let(:project) { create(:project, :repository, group: group) }
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let(:user3) { create(:user) }
  let(:label) { create(:label, project: project) }
  let(:label2) { create(:label) }

  let(:merge_request) do
    create(:merge_request, :simple, title: 'Old title',
                                    description: "FYI #{user2.to_reference}",
                                    assignee_ids: [user3.id],
                                    source_project: project,
                                    author: create(:user))
  end

  before do
    project.add_maintainer(user)
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
          assignee_ids: [user.id],
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
        expect(@merge_request.assignees).to match_array([user])
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
              total_time_spent: 0,
              description: "FYI #{user2.to_reference}"
            }
          )
      end

      it 'sends email to user2 about assign of new merge request and email to user3 about merge request unassignment', :sidekiq_might_not_need_inline do
        deliveries = ActionMailer::Base.deliveries
        email = deliveries.last
        recipients = deliveries.last(2).flat_map(&:to)
        expect(recipients).to include(user2.email, user3.email)
        expect(email.subject).to include(merge_request.title)
      end

      it 'creates system note about merge_request reassign' do
        note = find_note('assigned to')

        expect(note).not_to be_nil
        expect(note.note).to include "assigned to #{user.to_reference} and unassigned #{user3.to_reference}"
      end

      it 'creates a resource label event' do
        event = merge_request.resource_label_events.last

        expect(event).not_to be_nil
        expect(event.label_id).to eq label.id
        expect(event.user_id).to eq user.id
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

        it 'merges the MR', :sidekiq_might_not_need_inline do
          expect(@merge_request).to be_valid
          expect(@merge_request.state).to eq('merged')
          expect(@merge_request.merge_error).to be_nil
        end
      end

      context 'with finished pipeline' do
        before do
          create(:ci_pipeline,
            project: project,
            ref:     merge_request.source_branch,
            sha:     merge_request.diff_head_sha,
            status:  :success)

          perform_enqueued_jobs do
            @merge_request = service.execute(merge_request)
            @merge_request = MergeRequest.find(merge_request.id)
          end
        end

        it 'merges the MR', :sidekiq_might_not_need_inline do
          expect(@merge_request).to be_valid
          expect(@merge_request.state).to eq('merged')
        end
      end

      context 'with active pipeline' do
        before do
          service_mock = double
          create(
            :ci_pipeline,
            project: project,
            ref: merge_request.source_branch,
            sha: merge_request.diff_head_sha,
            head_pipeline_of: merge_request
          )

          expect(AutoMerge::MergeWhenPipelineSucceedsService).to receive(:new).with(project, user, { sha: merge_request.diff_head_sha })
            .and_return(service_mock)
          allow(service_mock).to receive(:available_for?) { true }
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
          update_merge_request({ assignee_ids: [user2.id] })
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

      context 'when the milestone is removed' do
        let!(:non_subscriber) { create(:user) }

        let!(:subscriber) do
          create(:user) do |u|
            merge_request.toggle_subscription(u, project)
            project.add_developer(u)
          end
        end

        it_behaves_like 'system notes for milestones'

        it 'sends notifications for subscribers of changed milestone', :sidekiq_might_not_need_inline do
          merge_request.milestone = create(:milestone, project: project)

          merge_request.save

          perform_enqueued_jobs do
            update_merge_request(milestone_id: "")
          end

          should_email(subscriber)
          should_not_email(non_subscriber)
        end
      end

      context 'when the milestone is changed' do
        let!(:non_subscriber) { create(:user) }

        let!(:subscriber) do
          create(:user) do |u|
            merge_request.toggle_subscription(u, project)
            project.add_developer(u)
          end
        end

        it 'marks pending todos as done' do
          update_merge_request({ milestone: create(:milestone, project: project) })

          expect(pending_todo.reload).to be_done
        end

        it_behaves_like 'system notes for milestones'

        it 'sends notifications for subscribers of changed milestone', :sidekiq_might_not_need_inline do
          perform_enqueued_jobs do
            update_merge_request(milestone: create(:milestone, project: project))
          end

          should_email(subscriber)
          should_not_email(non_subscriber)
        end
      end

      context 'when the labels change' do
        before do
          Timecop.freeze(1.minute.from_now) do
            update_merge_request({ label_ids: [label.id] })
          end
        end

        it 'marks pending todos as done' do
          expect(pending_todo.reload).to be_done
        end

        it 'updates updated_at' do
          expect(merge_request.reload.updated_at).to be > Time.now
        end
      end

      context 'when the assignee changes' do
        it 'updates open merge request counter for assignees when merge request is reassigned' do
          update_merge_request(assignee_ids: [user2.id])

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

      context 'when auto merge is enabled and target branch changed' do
        before do
          AutoMergeService.new(project, user, { sha: merge_request.diff_head_sha }).execute(merge_request, AutoMergeService::STRATEGY_MERGE_WHEN_PIPELINE_SUCCEEDS)

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

      it 'sends notifications for subscribers of newly added labels', :sidekiq_might_not_need_inline do
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

    context 'updating mentions' do
      let(:mentionable) { merge_request }

      include_examples 'updating mentions', described_class
    end

    context 'when MergeRequest has tasks' do
      before do
        update_merge_request({ description: "- [ ] Task 1\n- [ ] Task 2" })
      end

      it { expect(@merge_request.tasks?).to eq(true) }

      it_behaves_like 'updating a single task'

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

    context 'updating asssignee_ids' do
      it 'does not update assignee when assignee_id is invalid' do
        merge_request.update(assignee_ids: [user.id])

        update_merge_request(assignee_ids: [-1])

        expect(merge_request.reload.assignees).to eq([user])
      end

      it 'unassigns assignee when user id is 0' do
        merge_request.update(assignee_ids: [user.id])

        update_merge_request(assignee_ids: [0])

        expect(merge_request.assignee_ids).to be_empty
      end

      it 'saves assignee when user id is valid' do
        update_merge_request(assignee_ids: [user.id])

        expect(merge_request.assignee_ids).to eq([user.id])
      end

      it 'does not update assignee_id when user cannot read issue' do
        non_member = create(:user)
        original_assignees = merge_request.assignees

        update_merge_request(assignee_ids: [non_member.id])

        expect(merge_request.reload.assignees).to eq(original_assignees)
      end

      context "when issuable feature is private" do
        levels = [Gitlab::VisibilityLevel::INTERNAL, Gitlab::VisibilityLevel::PUBLIC]

        levels.each do |level|
          it "does not update with unauthorized assignee when project is #{Gitlab::VisibilityLevel.level_name(level)}" do
            assignee = create(:user)
            project.update(visibility_level: level)
            feature_visibility_attr = :"#{merge_request.model_name.plural}_access_level"
            project.project_feature.update_attribute(feature_visibility_attr, ProjectFeature::PRIVATE)

            expect { update_merge_request(assignee_ids: [assignee]) }.not_to change(merge_request.assignees, :count)
          end
        end
      end
    end

    include_examples 'issuable update service' do
      let(:open_issuable) { merge_request }
      let(:closed_issuable) { create(:closed_merge_request, source_project: project) }
    end

    context 'setting `allow_collaboration`' do
      let(:target_project) { create(:project, :repository, :public) }
      let(:source_project) { fork_project(target_project, nil, repository: true) }
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

      it 'does not allow a maintainer of the target project to set `allow_collaboration`' do
        target_project.add_developer(user)

        update_merge_request(allow_collaboration: true, title: 'Updated title')

        expect(merge_request.title).to eq('Updated title')
        expect(merge_request.allow_collaboration).to be_falsy
      end

      it 'is allowed by a user that can push to the source and can update the merge request' do
        merge_request.update!(assignees: [user])
        source_project.add_developer(user)

        update_merge_request(allow_collaboration: true, title: 'Updated title')

        expect(merge_request.title).to eq('Updated title')
        expect(merge_request.allow_collaboration).to be_truthy
      end
    end

    context 'updating `force_remove_source_branch`' do
      let(:target_project) { create(:project, :repository, :public) }
      let(:source_project) { fork_project(target_project, nil, repository: true) }
      let(:user) { target_project.owner }
      let(:merge_request) do
        create(:merge_request,
               source_project: source_project,
               source_branch: 'fixes',
               target_project: target_project)
      end

      it "cannot be done by members of the target project when they don't have access" do
        expect { update_merge_request(force_remove_source_branch: true) }
          .not_to change { merge_request.reload.force_remove_source_branch? }.from(nil)
      end

      it 'can be done by members of the target project if they can push to the source project' do
        source_project.add_developer(user)

        expect { update_merge_request(force_remove_source_branch: true) }
          .to change { merge_request.reload.force_remove_source_branch? }.from(nil).to(true)
      end
    end
  end
end
