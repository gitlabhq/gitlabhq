# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::UpdateService, :mailer do
  include ProjectForksHelper

  let(:group) { create(:group, :public) }
  let(:project) { create(:project, :private, :repository, group: group) }
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let(:user3) { create(:user) }
  let(:label) { create(:label, project: project) }
  let(:label2) { create(:label) }
  let(:milestone) { create(:milestone, project: project) }

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
      @merge_request = MergeRequests::UpdateService.new(project: project, current_user: user, params: opts).execute(merge_request)
      @merge_request.reload
    end

    context 'valid params' do
      let(:locked) { true }

      let(:opts) do
        {
          title: 'New title',
          description: 'Also please fix',
          assignee_ids: [user.id],
          reviewer_ids: [],
          state_event: 'close',
          label_ids: [label.id],
          target_branch: 'target',
          force_remove_source_branch: '1',
          discussion_locked: locked
        }
      end

      let(:service) { described_class.new(project: project, current_user: current_user, params: opts) }
      let(:current_user) { user }

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
        expect(@merge_request.reviewers).to match_array([])
        expect(@merge_request).to be_closed
        expect(@merge_request.labels.count).to eq(1)
        expect(@merge_request.labels.first.title).to eq(label.name)
        expect(@merge_request.target_branch).to eq('target')
        expect(@merge_request.merge_params['force_remove_source_branch']).to eq('1')
        expect(@merge_request.discussion_locked).to be_truthy
      end

      context 'usage counters' do
        let(:merge_request2) { create(:merge_request) }
        let(:draft_merge_request) { create(:merge_request, :draft_merge_request)}

        it 'update as expected' do
          expect(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter)
            .to receive(:track_title_edit_action).once.with(user: user)
          expect(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter)
            .to receive(:track_description_edit_action).once.with(user: user)

          MergeRequests::UpdateService.new(project: project, current_user: user, params: opts).execute(merge_request2)
        end

        it 'tracks Draft/WIP marking' do
          expect(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter)
            .to receive(:track_marked_as_draft_action).once.with(user: user)

          opts[:title] = "WIP: #{opts[:title]}"

          MergeRequests::UpdateService.new(project: project, current_user: user, params: opts).execute(merge_request2)
        end

        it 'tracks Draft/WIP un-marking' do
          expect(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter)
            .to receive(:track_unmarked_as_draft_action).once.with(user: user)

          opts[:title] = "Non-draft/wip title string"

          MergeRequests::UpdateService.new(project: project, current_user: user, params: opts).execute(draft_merge_request)
        end

        context 'when MR is locked' do
          context 'when locked again' do
            it 'does not track discussion locking' do
              expect(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter)
                .not_to receive(:track_discussion_locked_action)

              opts[:discussion_locked] = true

              MergeRequests::UpdateService.new(project: project, current_user: user, params: opts).execute(merge_request)
            end
          end

          context 'when unlocked' do
            it 'tracks dicussion unlocking' do
              expect(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter)
                .to receive(:track_discussion_unlocked_action).once.with(user: user)

              opts[:discussion_locked] = false

              MergeRequests::UpdateService.new(project: project, current_user: user, params: opts).execute(merge_request)
            end
          end
        end

        context 'when MR is unlocked' do
          let(:locked) { false }

          context 'when unlocked again' do
            it 'does not track discussion unlocking' do
              expect(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter)
                .not_to receive(:track_discussion_unlocked_action)

              opts[:discussion_locked] = false

              MergeRequests::UpdateService.new(project: project, current_user: user, params: opts).execute(merge_request)
            end
          end

          context 'when locked' do
            it 'tracks dicussion locking' do
              expect(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter)
                .to receive(:track_discussion_locked_action).once.with(user: user)

              opts[:discussion_locked] = true

              MergeRequests::UpdateService.new(project: project, current_user: user, params: opts).execute(merge_request)
            end
          end
        end

        it 'tracks time estimate and spend time changes' do
          expect(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter)
            .to receive(:track_time_estimate_changed_action).once.with(user: user)

          expect(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter)
            .to receive(:track_time_spent_changed_action).once.with(user: user)

          opts[:time_estimate] = 86400
          opts[:spend_time] = {
            duration: 3600,
            user_id: user.id,
            spent_at: Date.parse('2021-02-24')
          }

          MergeRequests::UpdateService.new(project: project, current_user: user, params: opts).execute(merge_request)
        end

        it 'tracks milestone change' do
          expect(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter)
            .to receive(:track_milestone_changed_action).once.with(user: user)

          opts[:milestone] = milestone

          MergeRequests::UpdateService.new(project: project, current_user: user, params: opts).execute(merge_request)
        end

        it 'track labels change' do
          expect(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter)
            .to receive(:track_labels_changed_action).once.with(user: user)

          opts[:label_ids] = [label2.id]

          MergeRequests::UpdateService.new(project: project, current_user: user, params: opts).execute(merge_request)
        end

        context 'reviewers' do
          context 'when reviewers changed' do
            it 'tracks reviewers changed event' do
              expect(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter)
                .to receive(:track_reviewers_changed_action).once.with(user: user)

              opts[:reviewers] = [user2]

              MergeRequests::UpdateService.new(project: project, current_user: user, params: opts).execute(merge_request)
            end
          end

          context 'when reviewers did not change' do
            it 'does not track reviewers changed event' do
              expect(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter)
                .not_to receive(:track_reviewers_changed_action)

              opts[:reviewers] = merge_request.reviewers

              MergeRequests::UpdateService.new(project: project, current_user: user, params: opts).execute(merge_request)
            end
          end
        end
      end

      context 'updating milestone' do
        RSpec.shared_examples 'updates milestone' do
          it 'sets milestone' do
            expect(@merge_request.milestone).to eq milestone
          end
        end

        context 'when milestone_id param' do
          let(:opts) { { milestone_id: milestone.id } }

          it_behaves_like 'updates milestone'
        end

        context 'when milestone param' do
          let(:opts) { { milestone: milestone } }

          it_behaves_like 'updates milestone'
        end

        context 'milestone counters cache reset' do
          let(:milestone_old) { create(:milestone, project: project) }
          let(:opts) { { milestone: milestone_old } }

          it 'deletes milestone counters' do
            expect_next_instance_of(Milestones::MergeRequestsCountService, milestone_old) do |service|
              expect(service).to receive(:delete_cache).and_call_original
            end

            expect_next_instance_of(Milestones::MergeRequestsCountService, milestone) do |service|
              expect(service).to receive(:delete_cache).and_call_original
            end

            update_merge_request(milestone: milestone)
          end

          it 'deletes milestone counters when the milestone is removed' do
            expect_next_instance_of(Milestones::MergeRequestsCountService, milestone_old) do |service|
              expect(service).to receive(:delete_cache).and_call_original
            end

            update_merge_request(milestone: nil)
          end

          it 'deletes milestone counters when the milestone was not set' do
            update_merge_request(milestone: nil)

            expect_next_instance_of(Milestones::MergeRequestsCountService, milestone) do |service|
              expect(service).to receive(:delete_cache).and_call_original
            end

            update_merge_request(milestone: milestone)
          end
        end
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
              reviewers: [],
              milestone: nil,
              total_time_spent: 0,
              time_change: 0,
              description: "FYI #{user2.to_reference}"
            }
          )
      end

      context 'with reviewers' do
        let(:opts) { { reviewer_ids: [user2.id] } }

        it 'creates system note about merge_request review request' do
          note = find_note('requested review from')

          expect(note).not_to be_nil
          expect(note.note).to include "requested review from #{user2.to_reference}"
        end

        it 'updates the tracking' do
          expect(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter)
            .to receive(:track_users_review_requested)
            .with(users: [user])

          update_merge_request(reviewer_ids: [user.id])
        end
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

      context 'when current user cannot admin issues in the project' do
        let(:guest) { create(:user) }
        let(:current_user) { guest }

        before do
          project.add_guest(guest)
        end

        it 'filters out params that cannot be set without the :admin_merge_request permission' do
          expect(@merge_request).to be_valid
          expect(@merge_request.title).to eq('New title')
          expect(@merge_request.assignees).to match_array([user3])
          expect(@merge_request).to be_opened
          expect(@merge_request.labels.count).to eq(0)
          expect(@merge_request.target_branch).to eq('target')
          expect(@merge_request.discussion_locked).to be_falsey
          expect(@merge_request.milestone).to be_nil
        end

        context 'updating milestone' do
          RSpec.shared_examples 'does not update milestone' do
            it 'sets milestone' do
              expect(@merge_request.milestone).to be_nil
            end
          end

          context 'when milestone_id param' do
            let(:opts) { { milestone_id: milestone.id } }

            it_behaves_like 'does not update milestone'
          end

          context 'when milestone param' do
            let(:opts) { { milestone: milestone } }

            it_behaves_like 'does not update milestone'
          end
        end
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

      it_behaves_like 'reviewer_ids filter' do
        let(:opts) { {} }
        let(:execute) { update_merge_request(opts) }
      end

      context 'with an existing reviewer' do
        let(:merge_request) do
          create(:merge_request, :simple, source_project: project, reviewer_ids: [user2.id])
        end

        context 'when merge_request_reviewer feature is enabled' do
          before do
            stub_feature_flags(merge_request_reviewer: true)
          end

          let(:opts) { { reviewer_ids: [IssuableFinder::Params::NONE] } }

          it 'removes reviewers' do
            expect(update_merge_request(opts).reviewers).to eq []
          end
        end
      end
    end

    context 'after_save callback to store_mentions' do
      let(:merge_request) { create(:merge_request, title: 'Old title', description: "simple description", source_branch: 'test', source_project: project, author: user) }
      let(:labels) { create_pair(:label, project: project) }
      let(:milestone) { create(:milestone, project: project) }
      let(:req_opts) { { source_branch: 'feature', target_branch: 'master' } }

      subject { MergeRequests::UpdateService.new(project: project, current_user: user, params: opts).execute(merge_request) }

      context 'when mentionable attributes change' do
        let(:opts) { { description: "Description with #{user.to_reference}" }.merge(req_opts) }

        it 'saves mentions' do
          expect(merge_request).to receive(:store_mentions!).and_call_original

          expect { subject }.to change { MergeRequestUserMention.count }.by(1)

          expect(merge_request.referenced_users).to match_array([user])
        end
      end

      context 'when mentionable attributes do not change' do
        let(:opts) { { label_ids: [label.id, label2.id], milestone_id: milestone.id }.merge(req_opts) }

        it 'does not call store_mentions' do
          expect(merge_request).not_to receive(:store_mentions!).and_call_original

          expect { subject }.not_to change { MergeRequestUserMention.count }

          expect(merge_request.referenced_users).to be_empty
        end
      end

      context 'when save fails' do
        let(:opts) { { title: '', label_ids: labels.map(&:id), milestone_id: milestone.id } }

        it 'does not call store_mentions' do
          expect(merge_request).not_to receive(:store_mentions!).and_call_original

          expect { subject }.not_to change { MergeRequestUserMention.count }

          expect(merge_request.referenced_users).to be_empty
          expect(merge_request.valid?).to be false
        end
      end
    end

    shared_examples_for 'correct merge behavior' do
      let(:opts) do
        {
          merge: merge_request.diff_head_sha
        }
      end

      let(:service) { described_class.new(project: project, current_user: user, params: opts) }

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
        let(:service) { described_class.new(project: project, current_user: visitor, params: opts) }

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

    describe 'merge' do
      it_behaves_like 'correct merge behavior'
    end

    context 'todos' do
      let!(:pending_todo) { create(:todo, :assigned, user: user, project: project, target: merge_request, author: user2) }

      context 'when the title change' do
        it 'calls MergeRequest::ResolveTodosService#async_execute' do
          expect_next_instance_of(MergeRequests::ResolveTodosService, merge_request, user) do |service|
            expect(service).to receive(:async_execute)
          end

          update_merge_request({ title: 'New title' })
        end

        it 'does not create any new todos' do
          update_merge_request({ title: 'New title' })

          expect(Todo.count).to eq(1)
        end
      end

      context 'when the description change' do
        it 'calls MergeRequest::ResolveTodosService#async_execute' do
          expect_next_instance_of(MergeRequests::ResolveTodosService, merge_request, user) do |service|
            expect(service).to receive(:async_execute)
          end

          update_merge_request({ description: "Also please fix #{user2.to_reference} #{user3.to_reference}" })
        end

        it 'creates only 1 new todo' do
          update_merge_request({ description: "Also please fix #{user2.to_reference} #{user3.to_reference}" })

          expect(Todo.count).to eq(2)
        end
      end

      context 'when is reassigned' do
        it 'calls MergeRequest::ResolveTodosService#async_execute' do
          expect_next_instance_of(MergeRequests::ResolveTodosService, merge_request, user) do |service|
            expect(service).to receive(:async_execute)
          end

          update_merge_request({ assignee_ids: [user2.id] })
        end
      end

      context 'when reviewers gets changed' do
        it 'calls MergeRequest::ResolveTodosService#async_execute' do
          expect_next_instance_of(MergeRequests::ResolveTodosService, merge_request, user) do |service|
            expect(service).to receive(:async_execute)
          end

          update_merge_request({ reviewer_ids: [user2.id] })
        end

        it 'creates a pending todo for new review request' do
          update_merge_request({ reviewer_ids: [user2.id] })

          attributes = {
            project: project,
            author: user,
            user: user2,
            target_id: merge_request.id,
            target_type: merge_request.class.name,
            action: Todo::REVIEW_REQUESTED,
            state: :pending
          }

          expect(Todo.where(attributes).count).to eq 1
        end

        it 'sends email reviewer change notifications to old and new reviewers', :sidekiq_might_not_need_inline do
          merge_request.reviewers = [user2]

          perform_enqueued_jobs do
            update_merge_request({ reviewer_ids: [user3.id] })
          end

          should_email(user2)
          should_email(user3)
        end

        it 'updates open merge request counter for reviewers', :use_clean_rails_memory_store_caching do
          merge_request.reviewers = [user3]

          # Cache them to ensure the cache gets invalidated on update
          expect(user2.review_requested_open_merge_requests_count).to eq(0)
          expect(user3.review_requested_open_merge_requests_count).to eq(1)

          update_merge_request(reviewer_ids: [user2.id])

          expect(user2.review_requested_open_merge_requests_count).to eq(1)
          expect(user3.review_requested_open_merge_requests_count).to eq(0)
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

        it 'sends notifications for subscribers of changed milestone', :sidekiq_might_not_need_inline do
          merge_request.milestone = create(:milestone, project: project)

          merge_request.save!

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

        it 'calls MergeRequests::ResolveTodosService#async_execute' do
          expect_next_instance_of(MergeRequests::ResolveTodosService, merge_request, user) do |service|
            expect(service).to receive(:async_execute)
          end

          update_merge_request({ milestone: create(:milestone, project: project) })
        end

        it 'sends notifications for subscribers of changed milestone', :sidekiq_might_not_need_inline do
          perform_enqueued_jobs do
            update_merge_request(milestone: create(:milestone, project: project))
          end

          should_email(subscriber)
          should_not_email(non_subscriber)
        end
      end

      context 'when the labels change' do
        it 'calls MergeRequests::ResolveTodosService#async_execute' do
          expect_next_instance_of(MergeRequests::ResolveTodosService, merge_request, user) do |service|
            expect(service).to receive(:async_execute)
          end

          update_merge_request({ label_ids: [label.id] })
        end

        it 'updates updated_at' do
          travel_to(1.minute.from_now) do
            update_merge_request({ label_ids: [label.id] })
          end

          expect(merge_request.reload.updated_at).to be > Time.current
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
        it 'calls MergeRequests::ResolveTodosService#async_execute' do
          expect_next_instance_of(MergeRequests::ResolveTodosService, merge_request, user) do |service|
            expect(service).to receive(:async_execute)
          end

          update_merge_request({ target_branch: 'target' })
        end

        it "does not try to mark as unchecked if it's already unchecked" do
          expect(merge_request).to receive(:unchecked?).and_return(true)
          expect(merge_request).not_to receive(:mark_as_unchecked)

          update_merge_request({ target_branch: "target" })
        end
      end

      context 'when auto merge is enabled and target branch changed' do
        before do
          AutoMergeService.new(project, user, { sha: merge_request.diff_head_sha }).execute(merge_request, AutoMergeService::STRATEGY_MERGE_WHEN_PIPELINE_SUCCEEDS)
        end

        it 'calls MergeRequests::ResolveTodosService#async_execute' do
          expect_next_instance_of(MergeRequests::ResolveTodosService, merge_request, user) do |service|
            expect(service).to receive(:async_execute)
          end

          update_merge_request({ target_branch: 'target' })
        end
      end
    end

    context 'when the draft status is changed' do
      let!(:non_subscriber) { create(:user) }
      let!(:subscriber) do
        create(:user) { |u| merge_request.toggle_subscription(u, project) }
      end

      before do
        project.add_developer(non_subscriber)
        project.add_developer(subscriber)
      end

      context 'removing draft status' do
        before do
          merge_request.update_attribute(:title, 'Draft: New Title')
        end

        it 'sends notifications for subscribers', :sidekiq_might_not_need_inline do
          opts = { title: 'New title' }

          perform_enqueued_jobs do
            @merge_request = described_class.new(project: project, current_user: user, params: opts).execute(merge_request)
          end

          should_email(subscriber)
          should_not_email(non_subscriber)
        end
      end

      context 'adding draft status' do
        it 'does not send notifications', :sidekiq_might_not_need_inline do
          opts = { title: 'Draft: New title' }

          perform_enqueued_jobs do
            @merge_request = described_class.new(project: project, current_user: user, params: opts).execute(merge_request)
          end

          should_not_email(subscriber)
          should_not_email(non_subscriber)
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
          @merge_request = described_class.new(project: project, current_user: user, params: opts).execute(merge_request)
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
            @merge_request = described_class.new(project: project, current_user: user, params: opts).execute(merge_request)
          end

          should_not_email(subscriber)
          should_not_email(non_subscriber)
        end

        it 'does not send notifications for removed labels' do
          opts = { label_ids: [label2.id] }

          perform_enqueued_jobs do
            @merge_request = described_class.new(project: project, current_user: user, params: opts).execute(merge_request)
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
        service = described_class.new(project: project, current_user: user, params: issue_closing_opts)
        allow(service).to receive(:execute_hooks)
        service.execute(merge_request)

        issue_ids = MergeRequestsClosingIssues.where(merge_request: merge_request).pluck(:issue_id)
        expect(issue_ids).to match_array([first_issue.id, second_issue.id])
      end

      it 'removes `MergeRequestsClosingIssues` records when issues are not closed anymore' do
        create(:merge_requests_closing_issues, issue: first_issue, merge_request: merge_request)
        create(:merge_requests_closing_issues, issue: second_issue, merge_request: merge_request)

        service = described_class.new(project: project, current_user: user, params: { description: "not closing any issues" })
        allow(service).to receive(:execute_hooks)
        service.execute(merge_request.reload)

        issue_ids = MergeRequestsClosingIssues.where(merge_request: merge_request).pluck(:issue_id)
        expect(issue_ids).to be_empty
      end
    end

    context 'updating asssignee_ids' do
      context ':use_specialized_service' do
        context 'when true' do
          it 'passes the update action to ::MergeRequests::UpdateAssigneesService' do
            expect(::MergeRequests::UpdateAssigneesService)
              .to receive(:new).and_call_original

            update_merge_request({
              assignee_ids: [user2.id],
              use_specialized_service: true
            })
          end
        end

        context 'when false or nil' do
          before do
            expect(::MergeRequests::UpdateAssigneesService).not_to receive(:new)
          end

          it 'does not pass the update action to ::MergeRequests::UpdateAssigneesService when false' do
            update_merge_request({
              assignee_ids: [user2.id],
              use_specialized_service: false
            })
          end

          it 'does not pass the update action to ::MergeRequests::UpdateAssigneesService when nil' do
            update_merge_request({
              assignee_ids: [user2.id],
              use_specialized_service: nil
            })
          end
        end
      end

      it 'does not update assignee when assignee_id is invalid' do
        merge_request.update!(assignee_ids: [user.id])

        expect(MergeRequests::HandleAssigneesChangeService).not_to receive(:new)

        update_merge_request(assignee_ids: [-1])

        expect(merge_request.reload.assignees).to eq([user])
      end

      it 'unassigns assignee when user id is 0' do
        merge_request.update!(assignee_ids: [user.id])

        expect_next_instance_of(MergeRequests::HandleAssigneesChangeService, project: project, current_user: user) do |service|
          expect(service)
            .to receive(:async_execute)
            .with(merge_request, [user])
        end

        update_merge_request(assignee_ids: [0])

        expect(merge_request.assignee_ids).to be_empty
      end

      it 'saves assignee when user id is valid' do
        expect_next_instance_of(MergeRequests::HandleAssigneesChangeService, project: project, current_user: user) do |service|
          expect(service)
            .to receive(:async_execute)
            .with(merge_request, [user3])
        end

        update_merge_request(assignee_ids: [user.id])

        expect(merge_request.assignee_ids).to eq([user.id])
      end

      it 'does not update assignee_id when user cannot read issue' do
        non_member = create(:user)
        original_assignees = merge_request.assignees

        expect(MergeRequests::HandleAssigneesChangeService).not_to receive(:new)

        update_merge_request(assignee_ids: [non_member.id])

        expect(merge_request.reload.assignees).to eq(original_assignees)
      end

      context "when issuable feature is private" do
        levels = [Gitlab::VisibilityLevel::INTERNAL, Gitlab::VisibilityLevel::PUBLIC]

        levels.each do |level|
          it "does not update with unauthorized assignee when project is #{Gitlab::VisibilityLevel.level_name(level)}" do
            assignee = create(:user)
            project.update!(visibility_level: level)
            feature_visibility_attr = :"#{merge_request.model_name.plural}_access_level"
            project.project_feature.update_attribute(feature_visibility_attr, ProjectFeature::PRIVATE)

            expect { update_merge_request(assignee_ids: [assignee]) }.not_to change(merge_request.assignees, :count)
          end
        end
      end
    end

    context 'when adding time spent' do
      let(:spend_time) { { duration: 1800, user_id: user3.id } }

      context ':use_specialized_service' do
        context 'when true' do
          it 'passes the update action to ::MergeRequests::AddSpentTimeService' do
            expect(::MergeRequests::AddSpentTimeService)
              .to receive(:new).and_call_original

            update_merge_request(spend_time: spend_time, use_specialized_service: true)
          end
        end

        context 'when false or nil' do
          before do
            expect(::MergeRequests::AddSpentTimeService).not_to receive(:new)
          end

          it 'does not pass the update action to ::MergeRequests::UpdateAssigneesService when false' do
            update_merge_request(spend_time: spend_time, use_specialized_service: false)
          end

          it 'does not pass the update action to ::MergeRequests::UpdateAssigneesService when nil' do
            update_merge_request(spend_time: spend_time, use_specialized_service: nil)
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

        update_merge_request(allow_collaboration: false, title: 'Updated title')

        expect(merge_request.title).to eq('Updated title')
        expect(merge_request.allow_collaboration).to be_truthy
      end

      it 'is allowed by a user that can push to the source and can update the merge request' do
        merge_request.update!(assignees: [user])
        source_project.add_developer(user)

        update_merge_request(allow_collaboration: false, title: 'Updated title')

        expect(merge_request.title).to eq('Updated title')
        expect(merge_request.allow_collaboration).to be_falsy
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

    context 'updating `target_branch`' do
      let(:merge_request) do
        create(:merge_request,
               source_project: project,
               source_branch: 'mr-b',
               target_branch: 'mr-a')
      end

      it 'updates to master' do
        expect(SystemNoteService).to receive(:change_branch).with(
          merge_request, project, user, 'target', 'update', 'mr-a', 'master'
        )

        expect { update_merge_request(target_branch: 'master') }
          .to change { merge_request.reload.target_branch }.from('mr-a').to('master')
      end

      it 'updates to master because of branch deletion' do
        expect(SystemNoteService).to receive(:change_branch).with(
          merge_request, project, user, 'target', 'delete', 'mr-a', 'master'
        )

        expect { update_merge_request(target_branch: 'master', target_branch_was_deleted: true) }
          .to change { merge_request.reload.target_branch }.from('mr-a').to('master')
      end
    end

    it_behaves_like 'issuable record that supports quick actions' do
      let(:existing_merge_request) { create(:merge_request, source_project: project) }
      let(:issuable) { described_class.new(project: project, current_user: user, params: params).execute(existing_merge_request) }
    end
  end
end
