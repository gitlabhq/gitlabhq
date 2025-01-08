# frozen_string_literal: true
require 'spec_helper'

RSpec.describe DraftNotes::PublishService, feature_category: :code_review_workflow do
  include RepoHelpers

  let_it_be(:merge_request) { create(:merge_request, reviewers: create_list(:user, 1), assignees: create_list(:user, 1)) }
  let(:project) { merge_request.target_project }
  let(:user) { merge_request.author }
  let(:commit) { project.commit(sample_commit.id) }
  let(:internal) { false }
  let(:executing_user) { nil }

  let(:position) do
    Gitlab::Diff::Position.new(
      old_path: "files/ruby/popen.rb",
      new_path: "files/ruby/popen.rb",
      old_line: nil,
      new_line: 14,
      diff_refs: commit.diff_refs
    )
  end

  def publish(draft: nil)
    DraftNotes::PublishService.new(merge_request, user).execute(draft: draft, executing_user: executing_user)
  end

  context 'single draft note' do
    let(:commit_id) { nil }
    let!(:drafts) { create_list(:draft_note, 2, merge_request: merge_request, author: user, commit_id: commit_id, position: position, internal: internal) }

    it 'publishes' do
      expect { publish(draft: drafts.first) }.to change { DraftNote.count }.by(-1).and change { Note.count }.by(1)
      expect(DraftNote.count).to eq(1)
    end

    it 'does not skip notification', :sidekiq_might_not_need_inline do
      note_params = drafts.first.publish_params.merge(skip_keep_around_commits: false)
      expect(Notes::CreateService).to receive(:new).with(project, user, note_params).and_call_original
      expect_next_instance_of(NotificationService) do |notification_service|
        expect(notification_service).to receive(:new_note)
      end

      result = publish(draft: drafts.first)

      expect(result[:status]).to eq(:success)
    end

    it 'does not track the publish event' do
      expect(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter)
        .not_to receive(:track_publish_review_action)

      publish(draft: drafts.first)
    end

    context 'commit_id is set' do
      let(:commit_id) { commit.id }

      it 'creates note from draft with commit_id' do
        result = publish(draft: drafts.first)

        expect(result[:status]).to eq(:success)
        expect(merge_request.notes.first.commit_id).to eq(commit_id)
      end
    end

    context 'internal is set' do
      let(:position) { nil }
      let(:internal) { true }

      it 'creates internal note from draft' do
        result = publish(draft: drafts.first)

        expect(result[:status]).to eq(:success)
        expect(merge_request.notes.first.internal).to eq(internal)
      end
    end
  end

  context 'multiple draft notes' do
    let(:commit_id) { nil }

    before do
      create(:draft_note_on_text_diff, merge_request: merge_request, author: user, note: 'first note', commit_id: commit_id, position: position)
      create(:draft_note_on_text_diff, merge_request: merge_request, author: user, note: 'second note', commit_id: commit_id, position: position)
    end

    context 'when review fails to create' do
      before do
        expect_next_instance_of(Review) do |review|
          allow(review).to receive(:save!).and_raise(ActiveRecord::RecordInvalid.new(review))
        end
      end

      it_behaves_like 'does not trigger GraphQL subscription mergeRequestMergeStatusUpdated' do
        let(:action) { publish }
      end

      it 'does not publish any draft note' do
        expect { publish }.not_to change { DraftNote.count }
      end

      it 'does not track the publish event' do
        expect(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter)
          .not_to receive(:track_publish_review_action)

        publish
      end

      it 'returns an error' do
        result = publish

        expect(result[:status]).to eq(:error)
        expect(result[:message]).to match(/Unable to save Review/)
      end
    end

    it_behaves_like 'triggers GraphQL subscription mergeRequestMergeStatusUpdated' do
      let(:action) { publish }
    end

    it 'returns success' do
      result = publish

      expect(result[:status]).to eq(:success)
    end

    it 'publishes all draft notes for a user in a merge request' do
      expect { publish }.to change { DraftNote.count }.by(-2).and change { Note.count }.by(2).and change { Review.count }.by(1)
      expect(DraftNote.count).to eq(0)

      notes = merge_request.notes.order(id: :asc)
      expect(notes.first.note).to eq('first note')
      expect(notes.last.note).to eq('second note')
    end

    it 'sends batch notification' do
      expect_next_instance_of(NotificationService) do |notification_service|
        expect(notification_service).to receive_message_chain(:async, :new_review).with(kind_of(Review))
      end

      publish
    end

    it 'resolves todos for the MR' do
      expect_any_instance_of(TodoService) do |todo_service|
        expect(todo_service).to receive(:new_review).with(kind_of(Review), user)
      end

      publish
    end

    it 'tracks the publish event' do
      expect(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter)
        .to receive(:track_publish_review_action)
        .with(user: user)

      publish
    end

    it 'invalidates cache counts' do
      expect(merge_request.assignees).to all(receive(:invalidate_merge_request_cache_counts))

      stub_feature_flags(merge_request_dashboard: true)

      publish
    end

    context 'capturing diff notes positions and keeping around commits' do
      before do
        # Need to execute this to ensure that we'll be able to test creation of
        # DiffNotePosition records as that only happens when the `MergeRequest#merge_ref_head`
        # is present. This service creates that for the specified merge request.
        MergeRequests::MergeToRefService.new(project: project, current_user: user).execute(merge_request)

        # Need to re-stub this and call original as we are stubbing
        # `Gitlab::Git::KeepAround#execute` in spec_helper for performance reason.
        # Enabling it here so we can test the Gitaly calls it makes.
        allow(Gitlab::Git::KeepAround).to receive(:execute).and_call_original
      end

      it 'creates diff_note_positions for diff notes' do
        publish

        notes = merge_request.notes.order(id: :asc)
        expect(notes.first.diff_note_positions).to be_any
        expect(notes.last.diff_note_positions).to be_any
      end

      it 'keeps around the commits of each published note' do
        publish

        repository = project.repository
        notes = merge_request.notes.order(id: :asc)

        notes.first.shas.each do |sha|
          expect(repository.ref_exists?("refs/keep-around/#{sha}")).to be_truthy
        end

        notes.last.shas.each do |sha|
          expect(repository.ref_exists?("refs/keep-around/#{sha}")).to be_truthy
        end
      end

      context 'checking gitaly calls' do
        # NOTE: This was added to avoid test flakiness.
        let(:merge_request) { create(:merge_request) }

        it 'does not request a lot from Gitaly', :request_store, :clean_gitlab_redis_cache do
          merge_request
          position

          Gitlab::GitalyClient.reset_counts

          # NOTE: This should be reduced as we work on reducing Gitaly calls.
          # Gitaly requests shouldn't go above this threshold as much as possible
          # as it may add more to the Gitaly N+1 issue we are experiencing.
          expect { publish }.to change { Gitlab::GitalyClient.get_request_count }.by(19)
        end
      end
    end

    context 'commit_id is set' do
      let(:commit_id) { commit.id }

      it 'creates note from draft with commit_id' do
        result = publish

        expect(result[:status]).to eq(:success)

        merge_request.notes.each do |note|
          expect(note.commit_id).to eq(commit_id)
        end
      end
    end

    it 'does not call UpdateReviewerStateService' do
      publish

      expect(MergeRequests::UpdateReviewerStateService).not_to receive(:new)
    end
  end

  context 'with many draft notes', :use_sql_query_cache, :request_store do
    let(:merge_request) { create(:merge_request) }

    it 'reduce N+1 queries' do
      5.times do
        create(:draft_note_on_discussion, merge_request: merge_request, author: user, note: 'some note')
      end

      recorder = ActiveRecord::QueryRecorder.new(skip_cached: false) { publish }

      expect(recorder.count).not_to be > 116
    end
  end

  context 'draft notes with suggestions' do
    let(:project) { create(:project, :repository) }
    let(:merge_request) { create(:merge_request, source_project: project, target_project: project) }

    let(:suggestion_note) do
      <<-MARKDOWN.strip_heredoc
        ```suggestion
          foo
        ```
      MARKDOWN
    end

    let!(:draft) { create(:draft_note_on_text_diff, note: suggestion_note, merge_request: merge_request, author: user) }

    it 'creates a suggestion with correct content' do
      expect { publish(draft: draft) }.to change { Suggestion.count }.by(1)
        .and change { DiffNote.count }.from(0).to(1)

      suggestion = Suggestion.last

      expect(suggestion.from_line).to eq(14)
      expect(suggestion.to_line).to eq(14)
      expect(suggestion.from_content).to eq("    vars = {\n")
      expect(suggestion.to_content).to eq("  foo\n")
    end

    context 'when the diff is changed' do
      let(:file_path) { 'files/ruby/popen.rb' }
      let(:branch_name) { project.default_branch }
      let(:commit) { project.repository.commit }

      def update_file(file_path, new_content)
        params = {
          file_path: file_path,
          commit_message: "Update File",
          file_content: new_content,
          start_project: project,
          start_branch: project.default_branch,
          branch_name: branch_name
        }

        Files::UpdateService.new(project, user, params).execute
      end

      before do
        project.add_developer(user)
      end

      it 'creates a suggestion based on the latest diff content and positions' do
        diff_file = merge_request.diffs(paths: [file_path]).diff_files.first
        raw_data = diff_file.new_blob.data

        # Add a line break to the beginning of the file
        result = update_file(file_path, raw_data.prepend("\n"))
        oldrev = merge_request.diff_head_sha
        newrev = result[:result]

        expect(newrev).to be_present

        # Generates new MR revision at DB level
        refresh = MergeRequests::RefreshService.new(project: project, current_user: user)
        refresh.execute(oldrev, newrev, merge_request.source_branch_ref)

        merge_request.reload
        expect { publish(draft: draft) }.to change { Suggestion.count }.by(1)
          .and change { DiffNote.count }.from(0).to(1)

        suggestion = Suggestion.last

        expect(suggestion.from_line).to eq(15)
        expect(suggestion.to_line).to eq(15)
        expect(suggestion.from_content).to eq("    vars = {\n")
        expect(suggestion.to_content).to eq("  foo\n")
      end
    end
  end

  it 'only publishes the draft notes belonging to the current user' do
    other_user = create(:user)
    project.add_maintainer(other_user)

    create_list(:draft_note, 2, merge_request: merge_request, author: user)
    create_list(:draft_note, 2, merge_request: merge_request, author: other_user)

    expect { publish }.to change { DraftNote.count }.by(-2).and change { Note.count }.by(2)
    expect(DraftNote.count).to eq(2)
  end

  context 'with quick actions', :sidekiq_inline do
    it 'performs quick actions' do
      other_user = create(:user)
      project.add_developer(other_user)

      create(
        :draft_note,
        merge_request: merge_request,
        author: user,
        note: "thanks\n/assign #{other_user.to_reference}"
      )

      expect { publish }.to change { DraftNote.count }.by(-1).and change { Note.count }.by(2)
      expect(merge_request.reload.assignees).to match_array([other_user])
      expect(merge_request.notes.last).to be_system
    end

    it 'does not create a note if it only contains quick actions' do
      create(:draft_note, merge_request: merge_request, author: user, note: "/assign #{user.to_reference}")

      expect { publish }.to change { DraftNote.count }.by(-1).and change { Note.count }.by(1)
      expect(merge_request.reload.assignees).to include(user)
      expect(merge_request.notes.last).to be_system
    end
  end

  context 'with drafts that resolve threads' do
    let!(:note) { create(:discussion_note_on_merge_request, noteable: merge_request, project: project) }
    let!(:draft_note) { create(:draft_note, merge_request: merge_request, author: user, resolve_discussion: true, discussion_id: note.discussion.reply_id) }

    it 'resolves the thread' do
      publish(draft: draft_note)

      # discussion is memoized and reload doesn't clear the memoization
      expect(Note.find(note.id).discussion.resolved?).to be true
    end

    it 'sends notifications if all threads are resolved' do
      expect_next_instance_of(MergeRequests::ResolvedDiscussionNotificationService) do |instance|
        expect(instance).to receive(:execute).with(merge_request)
      end

      publish
    end
  end

  context 'user cannot create notes' do
    before do
      allow(Ability).to receive(:allowed?).with(user, :create_note, merge_request).and_return(false)
    end

    it 'returns an error' do
      expect(publish[:status]).to eq(:error)
    end

    context 'when executing_user is specified' do
      let(:executing_user) { create(:user) }

      context 'and executing_user can create notes' do
        before do
          allow(Ability)
            .to receive(:allowed?)
            .with(executing_user, :create_note, merge_request)
            .and_return(true)
        end

        it 'returns success' do
          expect(publish[:status]).to eq(:success)
        end
      end

      context 'and executing_user cannot create notes' do
        before do
          allow(Ability)
            .to receive(:allowed?)
            .with(executing_user, :create_note, merge_request)
            .and_return(false)
        end

        it 'returns an error' do
          expect(publish[:status]).to eq(:error)
        end
      end
    end
  end
end
