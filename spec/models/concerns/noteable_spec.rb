require 'spec_helper'

describe MergeRequest, Noteable, model: true do
  let(:merge_request) { create(:merge_request) }
  let(:project) { merge_request.project }
  let!(:active_diff_note1) { create(:diff_note_on_merge_request, project: project, noteable: merge_request) }
  let!(:active_diff_note2) { create(:diff_note_on_merge_request, project: project, noteable: merge_request) }
  let!(:active_diff_note3) { create(:diff_note_on_merge_request, project: project, noteable: merge_request, position: active_position2) }
  let!(:outdated_diff_note1) { create(:diff_note_on_merge_request, project: project, noteable: merge_request, position: outdated_position) }
  let!(:outdated_diff_note2) { create(:diff_note_on_merge_request, project: project, noteable: merge_request, position: outdated_position) }
  let!(:discussion_note1) { create(:discussion_note_on_merge_request, project: project, noteable: merge_request) }
  let!(:discussion_note2) { create(:discussion_note_on_merge_request, in_reply_to: discussion_note1) }
  let!(:commit_diff_note1) { create(:diff_note_on_commit, project: project) }
  let!(:commit_diff_note2) { create(:diff_note_on_commit, project: project) }
  let!(:commit_note1) { create(:note_on_commit, project: project) }
  let!(:commit_note2) { create(:note_on_commit, project: project) }
  let!(:commit_discussion_note1) { create(:discussion_note_on_commit, project: project) }
  let!(:commit_discussion_note2) { create(:discussion_note_on_commit, in_reply_to: commit_discussion_note1) }
  let!(:commit_discussion_note3) { create(:discussion_note_on_commit, project: project) }
  let!(:note1) { create(:note, project: project, noteable: merge_request) }
  let!(:note2) { create(:note, project: project, noteable: merge_request) }

  let(:active_position2) do
    Gitlab::Diff::Position.new(
      old_path: "files/ruby/popen.rb",
      new_path: "files/ruby/popen.rb",
      old_line: 16,
      new_line: 22,
      diff_refs: merge_request.diff_refs
    )
  end

  let(:outdated_position) do
    Gitlab::Diff::Position.new(
      old_path: "files/ruby/popen.rb",
      new_path: "files/ruby/popen.rb",
      old_line: nil,
      new_line: 9,
      diff_refs: project.commit("874797c3a73b60d2187ed6e2fcabd289ff75171e").diff_refs
    )
  end

  describe '#discussions' do
    subject { merge_request.discussions }

    it 'includes discussions for diff notes, commit diff notes, commit notes, and regular notes' do
      expect(subject).to eq([
        DiffDiscussion.new([active_diff_note1, active_diff_note2], merge_request),
        DiffDiscussion.new([active_diff_note3], merge_request),
        DiffDiscussion.new([outdated_diff_note1, outdated_diff_note2], merge_request),
        SimpleDiscussion.new([discussion_note1, discussion_note2], merge_request),
        DiffDiscussion.new([commit_diff_note1, commit_diff_note2], merge_request),
        OutOfContextDiscussion.new([commit_note1, commit_note2], merge_request),
        SimpleDiscussion.new([commit_discussion_note1, commit_discussion_note2], merge_request),
        SimpleDiscussion.new([commit_discussion_note3], merge_request),
        IndividualNoteDiscussion.new([note1], merge_request),
        IndividualNoteDiscussion.new([note2], merge_request)
      ])
    end
  end

  describe '#grouped_diff_discussions' do
    subject { merge_request.grouped_diff_discussions }

    it "includes active discussions" do
      discussions = subject.values

      expect(discussions.count).to eq(2)
      expect(discussions.map(&:id)).to eq([active_diff_note1.discussion_id, active_diff_note3.discussion_id])
      expect(discussions.all?(&:active?)).to be true

      expect(discussions.first.notes).to eq([active_diff_note1, active_diff_note2])
      expect(discussions.last.notes).to eq([active_diff_note3])
    end

    it "doesn't include outdated discussions" do
      expect(subject.values.map(&:id)).not_to include(outdated_diff_note1.discussion_id)
    end

    it "groups the discussions by line code" do
      expect(subject[active_diff_note1.line_code].id).to eq(active_diff_note1.discussion_id)
      expect(subject[active_diff_note3.line_code].id).to eq(active_diff_note3.discussion_id)
    end
  end
end
