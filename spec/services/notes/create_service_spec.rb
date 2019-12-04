# frozen_string_literal: true

require 'spec_helper'

describe Notes::CreateService do
  set(:project) { create(:project, :repository) }
  set(:issue) { create(:issue, project: project) }
  set(:user) { create(:user) }
  let(:opts) do
    { note: 'Awesome comment', noteable_type: 'Issue', noteable_id: issue.id }
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
        note = build(:note, project: project)
        allow(Note).to receive(:new).with(opts) { note }

        expect_any_instance_of(TodoService).to receive(:new_note).with(note, user)

        described_class.new(project, user, opts).execute
      end

      it 'enqueues NewNoteWorker' do
        note = build(:note, id: 999, project: project)
        allow(Note).to receive(:new).with(opts) { note }

        expect(NewNoteWorker).to receive(:perform_async).with(note.id)

        described_class.new(project, user, opts).execute
      end
    end

    context 'noteable highlight cache clearing' do
      let(:project_with_repo) { create(:project, :repository) }
      let(:merge_request) do
        create(:merge_request, source_project: project_with_repo,
                               target_project: project_with_repo)
      end

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

      context 'using Gitlab::Diff::DeprecatedHighlightCache' do
        before do
          stub_feature_flags(hset_redis_diff_caching: false)
        end

        it 'clears noteable diff cache when it was unfolded for the note position' do
          expect_any_instance_of(Gitlab::Diff::DeprecatedHighlightCache).to receive(:clear)

          described_class.new(project_with_repo, user, new_opts).execute
        end
      end

      context 'using Gitlab::Diff::HighlightCache' do
        before do
          stub_feature_flags(hset_redis_diff_caching: true)
        end

        it 'clears noteable diff cache when it was unfolded for the note position' do
          expect_any_instance_of(Gitlab::Diff::HighlightCache).to receive(:clear)

          described_class.new(project_with_repo, user, new_opts).execute
        end
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
      let(:project_with_repo) { create(:project, :repository) }
      let(:merge_request) do
        create(:merge_request,
               source_project: project_with_repo,
               target_project: project_with_repo)
      end
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
          note = described_class.new(project_with_repo, user, new_opts).execute

          expect(note).to be_persisted
          expect(note.note_diff_file).to be_present
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

    context 'note with commands' do
      context 'all quick actions' do
        set(:milestone) { create(:milestone, project: project, title: "sprint") }
        set(:bug_label) { create(:label, project: project, title: 'bug') }
        set(:to_be_copied_label) { create(:label, project: project, title: 'to be copied') }
        set(:feature_label) { create(:label, project: project, title: 'feature') }
        set(:issue) { create(:issue, project: project, labels: [bug_label], due_date: '2019-01-01') }
        set(:issue_2) { create(:issue, project: project, labels: [bug_label, to_be_copied_label]) }

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
          set(:merge_request) { create(:merge_request, source_project: project, labels: [bug_label]) }
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
                action_text: "/wip",
                before_action: -> {
                  issuable.reload.update(title: "title")
                },
                expectation: ->(issuable, can_use_quick_action) {
                  expect(issuable.work_in_progress?).to eq(can_use_quick_action)
                }
              ),
              # Remove WIP status
              QuickAction.new(
                action_text: "/wip",
                before_action: -> {
                  issuable.reload.update(title: "WIP: title")
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

          Timecop.freeze(Time.now + 1.minute) { subject }

          existing_note.reload
        end.to change { existing_note.type }.from(nil).to('DiscussionNote')
            .and change { existing_note.updated_at }
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
