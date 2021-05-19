# frozen_string_literal: true
require 'spec_helper'

RSpec.describe DraftNotes::PublishService do
  include RepoHelpers

  let(:merge_request) { create(:merge_request) }
  let(:project) { merge_request.target_project }
  let(:user) { merge_request.author }
  let(:commit) { project.commit(sample_commit.id) }

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
    DraftNotes::PublishService.new(merge_request, user).execute(draft)
  end

  context 'single draft note' do
    let(:commit_id) { nil }
    let!(:drafts) { create_list(:draft_note, 2, merge_request: merge_request, author: user, commit_id: commit_id, position: position) }

    it 'publishes' do
      expect { publish(draft: drafts.first) }.to change { DraftNote.count }.by(-1).and change { Note.count }.by(1)
      expect(DraftNote.count).to eq(1)
    end

    it 'does not skip notification', :sidekiq_might_not_need_inline do
      expect(Notes::CreateService).to receive(:new).with(project, user, drafts.first.publish_params).and_call_original
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
  end

  context 'multiple draft notes' do
    let(:commit_id) { nil }

    before do
      create(:draft_note, merge_request: merge_request, author: user, note: 'first note', commit_id: commit_id, position: position)
      create(:draft_note, merge_request: merge_request, author: user, note: 'second note', commit_id: commit_id, position: position)
    end

    context 'when review fails to create' do
      before do
        expect_next_instance_of(Review) do |review|
          allow(review).to receive(:save!).and_raise(ActiveRecord::RecordInvalid.new(review))
        end
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

    it 'tracks the publish event' do
      expect(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter)
        .to receive(:track_publish_review_action)
        .with(user: user)

      publish
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

      create(:draft_note, merge_request: merge_request,
                          author: user,
                          note: "thanks\n/assign #{other_user.to_reference}")

      expect { publish }.to change { DraftNote.count }.by(-1).and change { Note.count }.by(2)
      expect(merge_request.reload.assignees).to match_array([other_user])
      expect(merge_request.notes.last).to be_system
    end

    it 'does not create a note if it only contains quick actions' do
      create(:draft_note, merge_request: merge_request, author: user, note: "/assign #{user.to_reference}")

      expect { publish }.to change { DraftNote.count }.by(-1).and change { Note.count }.by(1)
      expect(merge_request.reload.assignees).to eq([user])
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
  end
end
