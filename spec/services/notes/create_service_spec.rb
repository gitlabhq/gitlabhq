# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Notes::CreateService, feature_category: :team_planning do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :repository, group: group) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:user) { create(:user) }

  let(:base_opts) { { note: 'Awesome comment', noteable_type: 'Issue', noteable_id: issue.id } }
  let(:opts) { base_opts.merge(confidential: true) }

  describe '#execute' do
    subject(:note) { described_class.new(project, user, opts).execute }

    before_all do
      group.add_maintainer(user)
    end

    context "valid params" do
      context 'when noteable is an issue that belongs directly to a group' do
        it 'creates a note without a project and correct namespace', :aggregate_failures do
          group_issue = create(:issue, :group_level, namespace: group)
          note_params = { note: 'test note', noteable: group_issue }

          expect do
            described_class.new(nil, user, note_params).execute
          end.to change { Note.count }.by(1)

          created_note = Note.last

          expect(created_note.namespace).to eq(group)
          expect(created_note.project).to be_nil
        end
      end

      context 'when noteable is a work item that belongs directly to a group' do
        it 'creates a note without a project and correct namespace', :aggregate_failures do
          group_work_item = create(:work_item, :group_level, namespace: group)
          note_params = { note: 'test note', noteable: group_work_item }

          expect do
            described_class.new(nil, user, note_params).execute
          end.to change { Note.count }.by(1)

          created_note = Note.last

          expect(created_note.namespace).to eq(group)
          expect(created_note.project).to be_nil
        end
      end

      it_behaves_like 'does not trigger GraphQL subscription mergeRequestMergeStatusUpdated' do
        let(:action) { note }
      end

      it 'returns a valid note' do
        expect(note).to be_valid
      end

      it 'returns a persisted note' do
        expect(note).to be_persisted
      end

      it 'checks for spam' do
        expect_next_instance_of(Note) do |instance|
          expect(instance).to receive(:check_for_spam).with(action: :create, user: user)
        end

        note
      end

      it 'does not persist when spam' do
        expect_next_instance_of(Note) do |instance|
          expect(instance).to receive(:check_for_spam).with(action: :create, user: user) do
            instance.spam!
          end
        end

        expect(note).not_to be_persisted
      end

      context 'with internal parameter' do
        context 'when confidential' do
          let(:opts) { base_opts.merge(internal: true) }

          it 'returns a confidential note' do
            expect(note).to be_confidential
          end
        end

        context 'when not confidential' do
          let(:opts) { base_opts.merge(internal: false) }

          it 'returns a confidential note' do
            expect(note).not_to be_confidential
          end
        end
      end

      context 'with confidential parameter' do
        context 'when confidential' do
          let(:opts) { base_opts.merge(confidential: true) }

          it 'returns a confidential note' do
            expect(note).to be_confidential
          end
        end

        context 'when not confidential' do
          let(:opts) { base_opts.merge(confidential: false) }

          it 'returns a confidential note' do
            expect(note).not_to be_confidential
          end
        end
      end

      context 'with confidential and internal parameter set' do
        let(:opts) { base_opts.merge(internal: true, confidential: false) }

        it 'prefers the internal parameter' do
          expect(note).to be_confidential
        end
      end

      it 'note has valid content' do
        expect(note.note).to eq(opts[:note])
      end

      it 'note belongs to the correct project' do
        expect(note.project).to eq(project)
      end

      it 'TodoService#new_note is called' do
        note = build(:note, project: project, noteable: issue)
        allow(Note).to receive(:new).with(opts) { note }

        expect_any_instance_of(TodoService).to receive(:new_note).with(note, user)

        described_class.new(project, user, opts).execute
      end

      it 'enqueues NewNoteWorker' do
        note = build(:note, id: non_existing_record_id, project: project, noteable: issue)
        allow(Note).to receive(:new).with(opts) { note }

        expect(NewNoteWorker).to receive(:perform_async).with(note.id)

        described_class.new(project, user, opts).execute
      end

      context 'when importing execute option is set to true' do
        it 'does not enqueue NewNoteWorker' do
          expect(NewNoteWorker).not_to receive(:perform_async)

          described_class.new(project, user, opts).execute(importing: true)
        end
      end

      context 'issue is an incident' do
        let(:issue) { create(:incident, project: project) }

        it_behaves_like 'an incident management tracked event', :incident_management_incident_comment do
          let(:current_user) { user }
        end
      end

      context 'in a commit' do
        let_it_be(:commit) { create(:commit, project: project) }
        let(:opts) { { note: 'Awesome comment', noteable_type: 'Commit', commit_id: commit.id } }

        subject(:execute_create_service) { described_class.new(project, user, opts).execute }

        it_behaves_like 'internal event tracking' do
          let(:event) { 'create_commit_note' }
          let(:category) { described_class.to_s }
        end
      end

      describe 'event tracking' do
        subject(:execute_create_service) { described_class.new(project, user, opts).execute }

        it_behaves_like 'internal event not tracked' do
          let(:event) { 'create_commit_note' }
          let(:category) { described_class.to_s }
        end

        it 'does not track merge request usage data' do
          expect(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter).not_to receive(:track_create_comment_action)

          execute_create_service
        end

        it_behaves_like 'internal event tracking' do
          let(:event) { Gitlab::UsageDataCounters::IssueActivityUniqueCounter::ISSUE_COMMENT_ADDED }
          let(:namespace) { project.namespace }
          subject(:service_action) { execute_create_service }
        end
      end

      context 'in a merge request' do
        let_it_be(:project_with_repo) { create(:project, :repository) }
        let_it_be(:merge_request) do
          create(:merge_request, source_project: project_with_repo, target_project: project_with_repo)
        end

        let(:new_opts) { opts.merge(noteable_type: 'MergeRequest', noteable_id: merge_request.id) }

        context 'noteable highlight cache clearing' do
          let(:position) do
            Gitlab::Diff::Position.new(
              old_path: "files/ruby/popen.rb",
              new_path: "files/ruby/popen.rb",
              old_line: nil,
              new_line: 14,
              diff_refs: merge_request.diff_refs
            )
          end

          let(:new_opts) do
            opts.merge(
              in_reply_to_discussion_id: nil,
              type: 'DiffNote',
              noteable_type: 'MergeRequest',
              noteable_id: merge_request.id,
              position: position.to_h,
              confidential: false
            )
          end

          before do
            allow_any_instance_of(Gitlab::Diff::Position)
              .to receive(:unfolded_diff?) { true }
          end

          it 'does not track issue comment usage data' do
            expect(Gitlab::UsageDataCounters::IssueActivityUniqueCounter).not_to receive(:track_issue_comment_added_action)

            described_class.new(project_with_repo, user, new_opts).execute
          end

          it 'tracks merge request usage data' do
            expect(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter).to receive(:track_create_comment_action).with(note: kind_of(Note))

            described_class.new(project_with_repo, user, new_opts).execute
          end

          it 'clears noteable diff cache when it was unfolded for the note position' do
            expect_any_instance_of(Gitlab::Diff::HighlightCache).to receive(:clear)

            described_class.new(project_with_repo, user, new_opts).execute
          end

          it 'does not clear cache when note is not the first of the discussion' do
            prev_note =
              create(:diff_note_on_merge_request, noteable: merge_request, project: project_with_repo)
            reply_opts =
              opts.merge(
                in_reply_to_discussion_id: prev_note.discussion_id,
                type: 'DiffNote',
                noteable_type: 'MergeRequest',
                noteable_id: merge_request.id,
                position: position.to_h,
                confidential: false
              )

            expect(merge_request).not_to receive(:diffs)

            described_class.new(project_with_repo, user, reply_opts).execute
          end
        end

        context 'note diff file' do
          let(:line_number) { 14 }
          let(:position) do
            Gitlab::Diff::Position.new(
              old_path: "files/ruby/popen.rb",
              new_path: "files/ruby/popen.rb",
              old_line: nil,
              new_line: line_number,
              diff_refs: merge_request.diff_refs
            )
          end

          let(:previous_note) do
            create(:diff_note_on_merge_request, noteable: merge_request, project: project_with_repo)
          end

          before do
            project_with_repo.add_maintainer(user)
          end

          context 'when eligible to have a note diff file' do
            let(:new_opts) do
              opts.merge(
                in_reply_to_discussion_id: nil,
                type: 'DiffNote',
                noteable_type: 'MergeRequest',
                noteable_id: merge_request.id,
                position: position.to_h,
                confidential: false
              )
            end

            it_behaves_like 'triggers GraphQL subscription mergeRequestMergeStatusUpdated' do
              let(:action) { described_class.new(project_with_repo, user, new_opts).execute }
            end

            it 'note is associated with a note diff file' do
              MergeRequests::MergeToRefService.new(project: merge_request.project, current_user: merge_request.author).execute(merge_request)

              note = described_class.new(project_with_repo, user, new_opts).execute

              expect(note).to be_persisted
              expect(note.note_diff_file).to be_present
              expect(note.diff_note_positions).to be_present
            end

            context 'when skip_capture_diff_note_position execute option is set to true' do
              it 'does not execute Discussions::CaptureDiffNotePositionService' do
                expect(Discussions::CaptureDiffNotePositionService).not_to receive(:new)

                described_class.new(project_with_repo, user, new_opts).execute(skip_capture_diff_note_position: true)
              end
            end

            context 'when skip_merge_status_trigger execute option is set to true' do
              it_behaves_like 'does not trigger GraphQL subscription mergeRequestMergeStatusUpdated' do
                let(:action) do
                  described_class
                    .new(project_with_repo, user, new_opts)
                    .execute(skip_merge_status_trigger: true)
                end
              end
            end

            it 'does not track ipynb note usage data' do
              expect(::Gitlab::UsageDataCounters::IpynbDiffActivityCounter).not_to receive(:note_created)

              described_class.new(project_with_repo, user, new_opts).execute
            end

            context 'is ipynb file' do
              before do
                allow_any_instance_of(::Gitlab::Diff::File).to receive(:ipynb?).and_return(true)
              end

              it 'tracks ipynb diff note creation' do
                expect(::Gitlab::UsageDataCounters::IpynbDiffActivityCounter).to receive(:note_created)

                described_class.new(project_with_repo, user, new_opts).execute
              end
            end
          end

          context 'when DiffNote is a reply' do
            let(:new_opts) do
              opts.merge(
                in_reply_to_discussion_id: previous_note.discussion_id,
                type: 'DiffNote',
                noteable_type: 'MergeRequest',
                noteable_id: merge_request.id,
                position: position.to_h,
                confidential: false
              )
            end

            it 'note is not associated with a note diff file' do
              expect(Discussions::CaptureDiffNotePositionService).not_to receive(:new)

              note = described_class.new(project_with_repo, user, new_opts).execute

              expect(note).to be_persisted
              expect(note.note_diff_file).to be_nil
            end

            context 'when DiffNote from an image' do
              let(:image_position) do
                Gitlab::Diff::Position.new(
                  old_path: "files/images/6049019_460s.jpg",
                  new_path: "files/images/6049019_460s.jpg",
                  width: 100,
                  height: 100,
                  x: 1,
                  y: 100,
                  diff_refs: merge_request.diff_refs,
                  position_type: 'image'
                )
              end

              let(:new_opts) do
                opts.merge(
                  in_reply_to_discussion_id: nil,
                  type: 'DiffNote',
                  noteable_type: 'MergeRequest',
                  noteable_id: merge_request.id,
                  position: image_position.to_h,
                  confidential: false
                )
              end

              it 'note is not associated with a note diff file' do
                note = described_class.new(project_with_repo, user, new_opts).execute

                expect(note).to be_persisted
                expect(note.note_diff_file).to be_nil
              end
            end
          end
        end
      end
    end

    context 'note with commands' do
      context 'all quick actions' do
        let_it_be(:milestone) { create(:milestone, project: project, title: "sprint") }
        let_it_be(:bug_label) { create(:label, project: project, title: 'bug') }
        let_it_be(:to_be_copied_label) { create(:label, project: project, title: 'to be copied') }
        let_it_be(:feature_label) { create(:label, project: project, title: 'feature') }
        let_it_be(:issue, reload: true) { create(:issue, project: project, labels: [bug_label], due_date: '2019-01-01') }
        let_it_be(:issue_2) { create(:issue, project: project, labels: [bug_label, to_be_copied_label]) }

        context 'for issues' do
          let(:issuable) { issue }
          let(:note_params) { opts }
          let(:issue_quick_actions) do
            [
              QuickAction.new(
                action_text: '/confidential',
                expectation: ->(noteable, can_use_quick_action) {
                  if can_use_quick_action
                    expect(noteable).to be_confidential
                  else
                    expect(noteable).not_to be_confidential
                  end
                }
              ),
              QuickAction.new(
                action_text: '/due 2016-08-28',
                expectation: ->(noteable, can_use_quick_action) {
                  expect(noteable.due_date == Date.new(2016, 8, 28)).to eq(can_use_quick_action)
                }
              ),
              QuickAction.new(
                action_text: '/remove_due_date',
                expectation: ->(noteable, can_use_quick_action) {
                  if can_use_quick_action
                    expect(noteable.due_date).to be_nil
                  else
                    expect(noteable.due_date).not_to be_nil
                  end
                }
              ),
              QuickAction.new(
                action_text: "/duplicate #{issue_2.to_reference}",
                before_action: -> {
                  issuable.reopen
                },
                expectation: ->(noteable, can_use_quick_action) {
                  expect(noteable.closed?).to eq(can_use_quick_action)
                }
              )
            ]
          end

          it_behaves_like 'issuable quick actions' do
            let(:quick_actions) { issuable_quick_actions + issue_quick_actions }
          end
        end

        context 'for merge requests', feature_category: :code_review_workflow do
          let_it_be(:merge_request) { create(:merge_request, source_project: project, labels: [bug_label]) }

          let(:issuable) { merge_request }
          let(:note_params) { opts.merge(noteable_type: 'MergeRequest', noteable_id: merge_request.id, confidential: false) }
          let(:merge_request_quick_actions) do
            [
              QuickAction.new(
                action_text: "/target_branch fix",
                expectation: ->(noteable, can_use_quick_action) {
                  expect(noteable.target_branch == "fix").to eq(can_use_quick_action)
                }
              ),
              # Set Draft status
              QuickAction.new(
                action_text: "/draft",
                before_action: -> {
                  issuable.reload.update!(title: "title")
                },
                expectation: ->(issuable, can_use_quick_action) {
                  expect(issuable.draft?).to eq(can_use_quick_action)
                }
              ),
              # Remove draft (set ready) status
              QuickAction.new(
                action_text: "/ready",
                before_action: -> {
                  issuable.reload.update!(title: "Draft: title")
                },
                expectation: ->(noteable, can_use_quick_action) {
                  expect(noteable.draft?).not_to eq(can_use_quick_action)
                }
              )
            ]
          end

          it_behaves_like 'issuable quick actions' do
            let(:quick_actions) { issuable_quick_actions + merge_request_quick_actions }
          end
        end
      end

      context 'when note only has commands' do
        it 'adds commands applied message to note errors' do
          note_text = %(/close)
          service = double(:service)
          allow(Issues::UpdateService).to receive(:new).and_return(service)
          expect(service).to receive(:execute)

          note = described_class.new(project, user, opts.merge(note: note_text)).execute

          expect(note.quick_actions_status.messages).to be_present
          expect(note.quick_actions_status.error_messages).to be_empty
        end

        it 'adds commands failed message to note errors' do
          note_text = %(/reopen)
          note = described_class.new(project, user, opts.merge(note: note_text)).execute

          expect(note.quick_actions_status.messages).to eq(['Could not apply reopen command.'])
          expect(note.quick_actions_status.error_messages).to be_empty
        end

        it 'generates success and failed error messages' do
          note_text = %(/close\n/reopen)
          service = double(:service)
          allow(Issues::UpdateService).to receive(:new).and_return(service)
          expect(service).to receive(:execute)

          note = described_class.new(project, user, opts.merge(note: note_text)).execute

          expect(note.quick_actions_status.error?).to be(false)
          expect(note.quick_actions_status.command_names).to eq(%w[close reopen])
          expect(note.quick_actions_status.messages).to eq(['Closed this issue. Could not apply reopen command.'])
          expect(note.quick_actions_status.error_messages).to be_empty
        end

        it 'does not check for spam' do
          expect_next_instance_of(Note) do |instance|
            expect(instance).not_to receive(:check_for_spam).with(action: :create, user: user)
          end

          note_text = %(/close)
          described_class.new(project, user, opts.merge(note: note_text)).execute
        end

        it 'generates failed update error messages' do
          note_text = %(/confidential)
          service = double(:service)
          issue.errors.add(:confidential, 'an error occurred')
          allow(Issues::UpdateService).to receive(:new).and_return(service)
          allow_next_instance_of(Issues::UpdateService) do |service_instance|
            allow(service_instance).to receive(:execute).and_return(issue)
          end

          note = described_class.new(project, user, opts.merge(note: note_text)).execute

          expect(note.quick_actions_status.error?).to be(true)
          expect(note.quick_actions_status.command_names).to eq(['confidential'])
          expect(note.quick_actions_status.error_messages).to eq(['Confidential an error occurred'])
        end
      end
    end

    context 'personal snippet note', feature_category: :source_code_management do
      subject { described_class.new(nil, user, params).execute }

      let(:snippet) { create(:personal_snippet) }
      let(:params) do
        { note: 'comment', noteable_type: 'Snippet', noteable_id: snippet.id }
      end

      it 'returns a valid note' do
        expect(subject).to be_valid
      end

      it 'returns a persisted note' do
        expect(subject).to be_persisted
      end

      it 'note has valid content' do
        expect(subject.note).to eq(params[:note])
      end
    end

    context 'design note', feature_category: :design_management do
      subject(:service) { described_class.new(project, user, params) }

      let_it_be(:design) { create(:design, :with_file) }
      let_it_be(:project) { design.project }
      let_it_be(:user) { project.first_owner }
      let_it_be(:params) do
        {
          type: 'DiffNote',
          noteable: design,
          note: "A message",
          position: {
            old_path: design.full_path,
            new_path: design.full_path,
            position_type: 'image',
            width: '100',
            height: '100',
            x: '50',
            y: '50',
            base_sha: design.diff_refs.base_sha,
            start_sha: design.diff_refs.base_sha,
            head_sha: design.diff_refs.head_sha
          }
        }
      end

      it 'can create diff notes for designs' do
        note = service.execute

        expect(note).to be_a(DiffNote)
        expect(note).to be_persisted
        expect(note.noteable).to eq(design)
      end

      it 'sends a notification about this note', :sidekiq_might_not_need_inline do
        notifier = double
        allow(::NotificationService).to receive(:new).and_return(notifier)

        expect(notifier)
          .to receive(:new_note)
          .with have_attributes(noteable: design)

        service.execute
      end

      it 'correctly builds the position of the note' do
        note = service.execute

        expect(note.position.new_path).to eq(design.full_path)
        expect(note.position.old_path).to eq(design.full_path)
        expect(note.position.diff_refs).to eq(design.diff_refs)
      end
    end

    context 'note with emoji only' do
      it 'creates regular note' do
        opts = {
          note: ':smile: ',
          noteable_type: 'Issue',
          noteable_id: issue.id
        }
        note = described_class.new(project, user, opts).execute

        expect(note).to be_valid
        expect(note.note).to eq(':smile:')
      end
    end

    context 'reply to individual note' do
      let(:existing_note) { create(:note_on_issue, noteable: issue, project: project) }
      let(:reply_opts) { opts.merge(in_reply_to_discussion_id: existing_note.discussion_id) }

      subject { described_class.new(project, user, reply_opts).execute }

      it 'creates a DiscussionNote in reply to existing note' do
        expect(subject).to be_a(DiscussionNote)
        expect(subject.discussion_id).to eq(existing_note.discussion_id)
      end

      it 'converts existing note to DiscussionNote' do
        expect do
          existing_note

          travel_to(Time.current + 1.minute) { subject }

          existing_note.reload
        end.to change { existing_note.type }.from(nil).to('DiscussionNote')
            .and change { existing_note.updated_at }
      end

      context 'failure in when_saved' do
        let(:service) { described_class.new(project, user, reply_opts) }

        it 'converts existing note to DiscussionNote' do
          expect do
            existing_note

            allow(service).to receive(:when_saved).and_raise(ActiveRecord::StatementInvalid)

            travel_to(Time.current + 1.minute) do
              service.execute
            rescue ActiveRecord::StatementInvalid
            end

            existing_note.reload
          end.to change { existing_note.type }.from(nil).to('DiscussionNote')
            .and change { existing_note.updated_at }
        end
      end

      it 'returns a DiscussionNote with its parent discussion refreshed correctly' do
        discussion_notes = subject.discussion.notes

        expect(discussion_notes.size).to eq(2)
        expect(discussion_notes.first).to be_a(DiscussionNote)
      end

      context 'discussion to reply cannot be found' do
        before do
          existing_note.delete
        end

        it 'returns an note with errors' do
          note = subject

          expect(note.errors).not_to be_empty
          expect(note.errors[:base]).to eq(['Discussion to reply to cannot be found'])
        end
      end
    end

    describe "event tracking" do
      let(:event) { 'create_snippet_note' }
      let(:category) { described_class.to_s }

      context 'merge request' do
        let(:merge_request) { create(:merge_request) }
        let(:opts) { { note: 'reply', noteable_type: 'MergeRequest', noteable_id: merge_request.id, project: merge_request.project } }

        it_behaves_like 'internal event tracking' do
          let(:event) { 'create_merge_request_note' }
          let(:project) { merge_request.project }

          subject(:track_event) { described_class.new(merge_request.project, user, opts).execute }
        end
      end

      context 'snippet note' do
        let(:snippet) { create(:project_snippet, project: project) }
        let(:opts) { { note: 'reply', noteable_type: 'Snippet', noteable_id: snippet.id, project: project } }

        subject(:execute_create_service) { described_class.new(project, user, opts).execute }

        it_behaves_like 'internal event tracking'

        context 'when creation fails' do
          let(:opts) { { note: '' } }

          it_behaves_like 'internal event not tracked'
        end
      end

      context 'issue note' do
        let(:issue) { create(:issue, project: project) }
        let(:opts) { { note: 'reply', noteable_type: 'Issue', noteable_id: issue.id, project: project } }

        it_behaves_like 'internal event not tracked'
      end
    end
  end
end
