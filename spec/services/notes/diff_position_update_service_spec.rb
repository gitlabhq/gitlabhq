require 'spec_helper'

describe Notes::DiffPositionUpdateService, services: true do
  let(:project) { create(:project) }
  let(:create_commit) { project.commit("913c66a37b4a45b9769037c55c2d238bd0942d2e") }
  let(:modify_commit) { project.commit("874797c3a73b60d2187ed6e2fcabd289ff75171e") }
  let(:edit_commit) { project.commit("570e7b2abdd848b95f2f578043fc23bd6f6fd24d") }

  let(:path) { "files/ruby/popen.rb" }

  let(:old_diff_refs) do
    Gitlab::Diff::DiffRefs.new(
      base_sha: create_commit.parent_id,
      head_sha: modify_commit.sha
    )
  end

  let(:new_diff_refs) do
    Gitlab::Diff::DiffRefs.new(
      base_sha: create_commit.parent_id,
      head_sha: edit_commit.sha
    )
  end

  subject do
    described_class.new(
      project,
      nil,
      old_diff_refs: old_diff_refs,
      new_diff_refs: new_diff_refs,
      paths: [path]
    )
  end

  describe "#execute" do
    let(:note) { create(:diff_note_on_merge_request, project: project, position: old_position) }

    let(:old_position) do
      Gitlab::Diff::Position.new(
        old_path: path,
        new_path: path,
        old_line: nil,
        new_line: line,
        diff_refs: old_diff_refs
      )
    end

    context "when the diff line is the same" do
      let(:line) { 16 }

      it "updates the position" do
        subject.execute(note)

        expect(note.original_position).to eq(old_position)
        expect(note.position).not_to eq(old_position)
        expect(note.position.new_line).to eq(22)
      end
    end

    context "when the diff line has changed" do
      let(:line) { 9 }

      it "doesn't update the position" do
        subject.execute(note)

        expect(note.original_position).to eq(old_position)
        expect(note.position).to eq(old_position)
      end
    end
  end
end
