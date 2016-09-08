require 'spec_helper'

describe DiffNote, models: true do
  include RepoHelpers

  let(:project) { create(:project) }
  let(:merge_request) { create(:merge_request, source_project: project) }
  let(:commit) { project.commit(sample_commit.id) }

  let(:path) { "files/ruby/popen.rb" }

  let!(:position) do
    Gitlab::Diff::Position.new(
      old_path: path,
      new_path: path,
      old_line: nil,
      new_line: 14,
      diff_refs: merge_request.diff_refs
    )
  end

  let!(:new_position) do
    Gitlab::Diff::Position.new(
      old_path: path,
      new_path: path,
      old_line: 16,
      new_line: 22,
      diff_refs: merge_request.diff_refs
    )
  end

  subject { create(:diff_note_on_merge_request, project: project, position: position, noteable: merge_request) }

  describe ".resolve!" do
    let(:current_user) { create(:user) }
    let!(:commit_note) { create(:diff_note_on_commit) }
    let!(:resolved_note) { create(:diff_note_on_merge_request, :resolved) }
    let!(:unresolved_note) { create(:diff_note_on_merge_request) }

    before do
      described_class.resolve!(current_user)

      commit_note.reload
      resolved_note.reload
      unresolved_note.reload
    end

    it 'resolves only the resolvable, not yet resolved notes' do
      expect(commit_note.resolved_at).to be_nil
      expect(resolved_note.resolved_by).not_to eq(current_user)
      expect(unresolved_note.resolved_at).not_to be_nil
      expect(unresolved_note.resolved_by).to eq(current_user)
    end
  end

  describe ".unresolve!" do
    let!(:resolved_note) { create(:diff_note_on_merge_request, :resolved) }

    before do
      described_class.unresolve!

      resolved_note.reload
    end

    it 'unresolves the resolved notes' do
      expect(resolved_note.resolved_by).to be_nil
      expect(resolved_note.resolved_at).to be_nil
    end
  end

  describe "#position=" do
    context "when provided a string" do
      it "sets the position" do
        subject.position = new_position.to_json

        expect(subject.position).to eq(new_position)
      end
    end

    context "when provided a hash" do
      it "sets the position" do
        subject.position = new_position.to_h

        expect(subject.position).to eq(new_position)
      end
    end

    context "when provided a position object" do
      it "sets the position" do
        subject.position = new_position

        expect(subject.position).to eq(new_position)
      end
    end
  end

  describe "#diff_file" do
    it "returns the correct diff file" do
      diff_file = subject.diff_file

      expect(diff_file.old_path).to eq(position.old_path)
      expect(diff_file.new_path).to eq(position.new_path)
      expect(diff_file.diff_refs).to eq(position.diff_refs)
    end
  end

  describe "#diff_line" do
    it "returns the correct diff line" do
      diff_line = subject.diff_line

      expect(diff_line.added?).to be true
      expect(diff_line.new_line).to eq(position.new_line)
      expect(diff_line.text).to eq("+    vars = {")
    end
  end

  describe "#line_code" do
    it "returns the correct line code" do
      line_code = Gitlab::Diff::LineCode.generate(position.file_path, position.new_line, 15)

      expect(subject.line_code).to eq(line_code)
    end
  end

  describe "#for_line?" do
    context "when provided the correct diff line" do
      it "returns true" do
        expect(subject.for_line?(subject.diff_line)).to be true
      end
    end

    context "when provided a different diff line" do
      it "returns false" do
        some_line = subject.diff_file.diff_lines.first

        expect(subject.for_line?(some_line)).to be false
      end
    end
  end

  describe "#active?" do
    context "when noteable is a commit" do
      subject { build(:diff_note_on_commit, project: project, position: position) }

      it "returns true" do
        expect(subject.active?).to be true
      end
    end

    context "when noteable is a merge request" do
      context "when the merge request's diff refs match that of the diff note" do
        it "returns true" do
          expect(subject.active?).to be true
        end
      end

      context "when the merge request's diff refs don't match that of the diff note" do
        before do
          allow(subject.noteable).to receive(:diff_sha_refs).and_return(commit.diff_refs)
        end

        it "returns false" do
          expect(subject.active?).to be false
        end
      end
    end
  end

  describe "creation" do
    describe "updating of position" do
      context "when noteable is a commit" do
        let(:diff_note) { create(:diff_note_on_commit, project: project, position: position) }

        it "doesn't use the DiffPositionUpdateService" do
          expect(Notes::DiffPositionUpdateService).not_to receive(:new)

          diff_note
        end

        it "doesn't update the position" do
          diff_note

          expect(diff_note.original_position).to eq(position)
          expect(diff_note.position).to eq(position)
        end
      end

      context "when noteable is a merge request" do
        let(:diff_note) { create(:diff_note_on_merge_request, project: project, position: position, noteable: merge_request) }

        context "when the note is active" do
          it "doesn't use the DiffPositionUpdateService" do
            expect(Notes::DiffPositionUpdateService).not_to receive(:new)

            diff_note
          end

          it "doesn't update the position" do
            diff_note

            expect(diff_note.original_position).to eq(position)
            expect(diff_note.position).to eq(position)
          end
        end

        context "when the note is outdated" do
          before do
            allow(merge_request).to receive(:diff_sha_refs).and_return(commit.diff_refs)
          end

          it "uses the DiffPositionUpdateService" do
            service = instance_double("Notes::DiffPositionUpdateService")
            expect(Notes::DiffPositionUpdateService).to receive(:new).with(
              project,
              nil,
              old_diff_refs: position.diff_refs,
              new_diff_refs: commit.diff_refs,
              paths: [path]
            ).and_return(service)
            expect(service).to receive(:execute)

            diff_note
          end
        end
      end
    end
  end

  describe "#resolvable?" do
    context "when noteable is a commit" do
      subject { create(:diff_note_on_commit, project: project, position: position) }

      it "returns false" do
        expect(subject.resolvable?).to be false
      end
    end

    context "when noteable is a merge request" do
      context "when a system note" do
        before do
          subject.system = true
        end

        it "returns false" do
          expect(subject.resolvable?).to be false
        end
      end

      context "when a regular note" do
        it "returns true" do
          expect(subject.resolvable?).to be true
        end
      end
    end
  end

  describe "#to_be_resolved?" do
    context "when not resolvable" do
      before do
        allow(subject).to receive(:resolvable?).and_return(false)
      end

      it "returns false" do
        expect(subject.to_be_resolved?).to be false
      end
    end

    context "when resolvable" do
      before do
        allow(subject).to receive(:resolvable?).and_return(true)
      end

      context "when resolved" do
        before do
          allow(subject).to receive(:resolved?).and_return(true)
        end

        it "returns false" do
          expect(subject.to_be_resolved?).to be false
        end
      end

      context "when not resolved" do
        before do
          allow(subject).to receive(:resolved?).and_return(false)
        end

        it "returns true" do
          expect(subject.to_be_resolved?).to be true
        end
      end
    end
  end

  describe "#resolve!" do
    let(:current_user) { create(:user) }

    context "when not resolvable" do
      before do
        allow(subject).to receive(:resolvable?).and_return(false)
      end

      it "returns nil" do
        expect(subject.resolve!(current_user)).to be_nil
      end

      it "doesn't set resolved_at" do
        subject.resolve!(current_user)

        expect(subject.resolved_at).to be_nil
      end

      it "doesn't set resolved_by" do
        subject.resolve!(current_user)

        expect(subject.resolved_by).to be_nil
      end

      it "doesn't mark as resolved" do
        subject.resolve!(current_user)

        expect(subject.resolved?).to be false
      end
    end

    context "when resolvable" do
      before do
        allow(subject).to receive(:resolvable?).and_return(true)
      end

      context "when already resolved" do
        let(:user) { create(:user) }

        before do
          subject.resolve!(user)
        end

        it "returns nil" do
          expect(subject.resolve!(current_user)).to be_nil
        end

        it "doesn't change resolved_at" do
          expect(subject.resolved_at).not_to be_nil

          expect { subject.resolve!(current_user) }.not_to change { subject.resolved_at }
        end

        it "doesn't change resolved_by" do
          expect(subject.resolved_by).to eq(user)

          expect { subject.resolve!(current_user) }.not_to change { subject.resolved_by }
        end

        it "doesn't change resolved status" do
          expect(subject.resolved?).to be true

          expect { subject.resolve!(current_user) }.not_to change { subject.resolved? }
        end
      end

      context "when not yet resolved" do
        it "returns true" do
          expect(subject.resolve!(current_user)).to be true
        end

        it "sets resolved_at" do
          subject.resolve!(current_user)

          expect(subject.resolved_at).not_to be_nil
        end

        it "sets resolved_by" do
          subject.resolve!(current_user)

          expect(subject.resolved_by).to eq(current_user)
        end

        it "marks as resolved" do
          subject.resolve!(current_user)

          expect(subject.resolved?).to be true
        end
      end
    end
  end

  describe "#unresolve!" do
    context "when not resolvable" do
      before do
        allow(subject).to receive(:resolvable?).and_return(false)
      end

      it "returns nil" do
        expect(subject.unresolve!).to be_nil
      end
    end

    context "when resolvable" do
      before do
        allow(subject).to receive(:resolvable?).and_return(true)
      end

      context "when resolved" do
        let(:user) { create(:user) }

        before do
          subject.resolve!(user)
        end

        it "returns true" do
          expect(subject.unresolve!).to be true
        end

        it "unsets resolved_at" do
          subject.unresolve!

          expect(subject.resolved_at).to be_nil
        end

        it "unsets resolved_by" do
          subject.unresolve!

          expect(subject.resolved_by).to be_nil
        end

        it "unmarks as resolved" do
          subject.unresolve!

          expect(subject.resolved?).to be false
        end
      end

      context "when not resolved" do
        it "returns nil" do
          expect(subject.unresolve!).to be_nil
        end
      end
    end
  end

  describe "#discussion" do
    context "when not resolvable" do
      before do
        allow(subject).to receive(:resolvable?).and_return(false)
      end

      it "returns nil" do
        expect(subject.discussion).to be_nil
      end
    end

    context "when resolvable" do
      let!(:diff_note2) { create(:diff_note_on_merge_request, project: project, noteable: merge_request, position: subject.position) }
      let!(:diff_note3) { create(:diff_note_on_merge_request, project: project, noteable: merge_request, position: active_position2) }

      let(:active_position2) do
        Gitlab::Diff::Position.new(
          old_path: "files/ruby/popen.rb",
          new_path: "files/ruby/popen.rb",
          old_line: 16,
          new_line: 22,
          diff_refs: merge_request.diff_refs
        )
      end

      it "returns the discussion this note is in" do
        discussion = subject.discussion

        expect(discussion.id).to eq(subject.discussion_id)
        expect(discussion.notes).to eq([subject, diff_note2])
      end
    end
  end

  describe "#discussion_id" do
    let(:note) { create(:diff_note_on_merge_request) }

    context "when it is newly created" do
      it "has a discussion id" do
        expect(note.discussion_id).not_to be_nil
        expect(note.discussion_id).to match(/\A\h{40}\z/)
      end
    end

    context "when it didn't store a discussion id before" do
      before do
        note.update_column(:discussion_id, nil)
      end

      it "has a discussion id" do
        # The discussion_id is set in `after_initialize`, so `reload` won't work
        reloaded_note = Note.find(note.id)

        expect(reloaded_note.discussion_id).not_to be_nil
        expect(reloaded_note.discussion_id).to match(/\A\h{40}\z/)
      end
    end
  end

  describe "#original_discussion_id" do
    let(:note) { create(:diff_note_on_merge_request) }

    context "when it is newly created" do
      it "has a discussion id" do
        expect(note.original_discussion_id).not_to be_nil
        expect(note.original_discussion_id).to match(/\A\h{40}\z/)
      end
    end

    context "when it didn't store a discussion id before" do
      before do
        note.update_column(:original_discussion_id, nil)
      end

      it "has a discussion id" do
        # The original_discussion_id is set in `after_initialize`, so `reload` won't work
        reloaded_note = Note.find(note.id)

        expect(reloaded_note.original_discussion_id).not_to be_nil
        expect(reloaded_note.original_discussion_id).to match(/\A\h{40}\z/)
      end
    end
  end
end
