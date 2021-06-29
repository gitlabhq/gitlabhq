# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Notes::CreateService do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:user) { create(:user) }

  let(:opts) do
    { note: 'Awesome comment', noteable_type: 'Issue', noteable_id: issue.id, confidential: true }
  end

  describe '#execute' do
    before do
      project.add_maintainer(user)
    end

    context "valid params" do
      it 'returns a valid note' do
        note = described_class.new(project, user, opts).execute

        expect(note).to be_valid
      end

      it 'returns a persisted note' do
        note = described_class.new(project, user, opts).execute

        expect(note).to be_persisted
      end

      it 'note has valid content' do
        note = described_class.new(project, user, opts).execute

        expect(note.note).to eq(opts[:note])
      end

      it 'note belongs to the correct project' do
        note = described_class.new(project, user, opts).execute

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

      context 'issue is an incident' do
        subject { described_class.new(project, user, opts).execute }

        let(:issue) { create(:incident, project: project) }

        it_behaves_like 'an incident management tracked event', :incident_management_incident_comment do
          let(:current_user) { user }
        end
      end

      it 'tracks issue comment usage data', :clean_gitlab_redis_shared_state do
        event = Gitlab::UsageDataCounters::IssueActivityUniqueCounter::ISSUE_COMMENT_ADDED
        counter = Gitlab::UsageDataCounters::HLLRedisCounter

        expect(Gitlab::UsageDataCounters::IssueActivityUniqueCounter).to receive(:track_issue_comment_added_action).with(author: user).and_call_original
        expect do
          described_class.new(project, user, opts).execute
        end.to change { counter.unique_events(event_names: event, start_date: 1.day.ago, end_date: 1.day.from_now) }.by(1)
      end

      it 'does not track merge request usage data' do
        expect(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter).not_to receive(:track_create_comment_action)

        described_class.new(project, user, opts).execute
      end

      context 'in a merge request' do
        let_it_be(:project_with_repo) { create(:project, :repository) }
        let_it_be(:merge_request) do
          create(:merge_request, source_project: project_with_repo,
                 target_project: project_with_repo)
        end

        context 'noteable highlight cache clearing' do
          let(:position) do
            Gitlab::Diff::Position.new(old_path: "files/ruby/popen.rb",
                                       new_path: "files/ruby/popen.rb",
                                       old_line: nil,
                                       new_line: 14,
                                       diff_refs: merge_request.diff_refs)
          end

          let(:new_opts) do
            opts.merge(in_reply_to_discussion_id: nil,
                       type: 'DiffNote',
                       noteable_type: 'MergeRequest',
                       noteable_id: merge_request.id,
                       position: position.to_h)
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
              create(:diff_note_on_merge_request, noteable: merge_request,
                     project: project_with_repo)
            reply_opts =
              opts.merge(in_reply_to_discussion_id: prev_note.discussion_id,
                         type: 'DiffNote',
                         noteable_type: 'MergeRequest',
                         noteable_id: merge_request.id,
                         position: position.to_h)

            expect(merge_request).not_to receive(:diffs)

            described_class.new(project_with_repo, user, reply_opts).execute
          end
        end

        context 'note diff file' do
          let(:line_number) { 14 }
          let(:position) do
            Gitlab::Diff::Position.new(old_path: "files/ruby/popen.rb",
                                       new_path: "files/ruby/popen.rb",
                                       old_line: nil,
                                       new_line: line_number,
                                       diff_refs: merge_request.diff_refs)
          end

          let(:previous_note) do
            create(:diff_note_on_merge_request, noteable: merge_request, project: project_with_repo)
          end

          before do
            project_with_repo.add_maintainer(user)
          end

          context 'when eligible to have a note diff file' do
            let(:new_opts) do
              opts.merge(in_reply_to_discussion_id: nil,
                         type: 'DiffNote',
                         noteable_type: 'MergeRequest',
                         noteable_id: merge_request.id,
                         position: position.to_h)
            end

            it 'note is associated with a note diff file' do
              MergeRequests::MergeToRefService.new(project: merge_request.project, current_user: merge_request.author).execute(merge_request)

              note = described_class.new(project_with_repo, user, new_opts).execute

              expect(note).to be_persisted
              expect(note.note_diff_file).to be_present
              expect(note.diff_note_positions).to be_present
            end
          end

          context 'when DiffNote is a reply' do
            let(:new_opts) do
              opts.merge(in_reply_to_discussion_id: previous_note.discussion_id,
                         type: 'DiffNote',
                         noteable_type: 'MergeRequest',
                         noteable_id: merge_request.id,
                         position: position.to_h)
            end

            it 'note is not associated with a note diff file' do
              expect(Discussions::CaptureDiffNotePositionService).not_to receive(:new)

              note = described_class.new(project_with_repo, user, new_opts).execute

              expect(note).to be_persisted
              expect(note.note_diff_file).to be_nil
            end

            context 'when DiffNote from an image' do
              let(:image_position) do
                Gitlab::Diff::Position.new(old_path: "files/images/6049019_460s.jpg",
                                           new_path: "files/images/6049019_460s.jpg",
                                           width: 100,
                                           height: 100,
                                           x: 1,
                                           y: 100,
                                           diff_refs: merge_request.diff_refs,
                                           position_type: 'image')
              end

              let(:new_opts) do
                opts.merge(in_reply_to_discussion_id: nil,
                           type: 'DiffNote',
                           noteable_type: 'MergeRequest',
                           noteable_id: merge_request.id,
                           position: image_position.to_h)
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

        context 'for merge requests' do
          let_it_be(:merge_request) { create(:merge_request, source_project: project, labels: [bug_label]) }

          let(:issuable) { merge_request }
          let(:note_params) { opts.merge(noteable_type: 'MergeRequest', noteable_id: merge_request.id) }
          let(:merge_request_quick_actions) do
            [
              QuickAction.new(
                action_text: "/target_branch fix",
                expectation: ->(noteable, can_use_quick_action) {
                  expect(noteable.target_branch == "fix").to eq(can_use_quick_action)
                }
              ),
              # Set WIP status
              QuickAction.new(
                action_text: "/draft",
                before_action: -> {
                  issuable.reload.update!(title: "title")
                },
                expectation: ->(issuable, can_use_quick_action) {
                  expect(issuable.work_in_progress?).to eq(can_use_quick_action)
                }
              ),
              # Remove WIP status
              QuickAction.new(
                action_text: "/draft",
                before_action: -> {
                  issuable.reload.update!(title: "WIP: title")
                },
                expectation: ->(noteable, can_use_quick_action) {
                  expect(noteable.work_in_progress?).not_to eq(can_use_quick_action)
                }
              )
            ]
          end

          it_behaves_like 'issuable quick actions' do
            let(:quick_actions) { issuable_quick_actions + merge_request_quick_actions }
          end
        end
      end

      context 'when note only have commands' do
        it 'adds commands applied message to note errors' do
          note_text = %(/close)
          service = double(:service)
          allow(Issues::UpdateService).to receive(:new).and_return(service)
          expect(service).to receive(:execute)

          note = described_class.new(project, user, opts.merge(note: note_text)).execute

          expect(note.errors[:commands_only]).to be_present
        end

        it 'adds commands failed message to note errors' do
          note_text = %(/reopen)
          note = described_class.new(project, user, opts.merge(note: note_text)).execute

          expect(note.errors[:commands_only]).to contain_exactly('Could not apply reopen command.')
        end

        it 'generates success and failed error messages' do
          note_text = %(/close\n/reopen)
          service = double(:service)
          allow(Issues::UpdateService).to receive(:new).and_return(service)
          expect(service).to receive(:execute)

          note = described_class.new(project, user, opts.merge(note: note_text)).execute

          expect(note.errors[:commands_only]).to contain_exactly('Closed this issue. Could not apply reopen command.')
        end
      end
    end

    context 'personal snippet note' do
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

    context 'design note' do
      subject(:service) { described_class.new(project, user, params) }

      let_it_be(:design) { create(:design, :with_file) }
      let_it_be(:project) { design.project }
      let_it_be(:user) { project.owner }
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

    describe "usage counter" do
      let(:counter) { Gitlab::UsageDataCounters::NoteCounter }

      context 'snippet note' do
        let(:snippet) { create(:project_snippet, project: project) }
        let(:opts) { { note: 'reply', noteable_type: 'Snippet', noteable_id: snippet.id, project: project } }

        it 'increments usage counter' do
          expect do
            note = described_class.new(project, user, opts).execute

            expect(note).to be_valid
          end.to change { counter.read(:create, opts[:noteable_type]) }.by 1
        end

        it 'does not increment usage counter when creation fails' do
          expect do
            note = described_class.new(project, user, { note: '' }).execute

            expect(note).to be_invalid
          end.not_to change { counter.read(:create, opts[:noteable_type]) }
        end
      end

      context 'issue note' do
        let(:issue) { create(:issue, project: project) }
        let(:opts) { { note: 'reply', noteable_type: 'Issue', noteable_id: issue.id, project: project } }

        it 'does not increment usage counter' do
          expect do
            note = described_class.new(project, user, opts).execute

            expect(note).to be_valid
          end.not_to change { counter.read(:create, opts[:noteable_type]) }
        end
      end
    end
  end
end
