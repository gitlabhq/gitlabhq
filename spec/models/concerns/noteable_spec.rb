# frozen_string_literal: true

require 'spec_helper'

describe Noteable do
  let!(:active_diff_note1) { create(:diff_note_on_merge_request) }
  let(:project) { active_diff_note1.project }
  subject { active_diff_note1.noteable }

  let!(:active_diff_note2) { create(:diff_note_on_merge_request, project: project, noteable: subject, in_reply_to: active_diff_note1) }
  let!(:active_diff_note3) { create(:diff_note_on_merge_request, project: project, noteable: subject, position: active_position2) }
  let!(:outdated_diff_note1) { create(:diff_note_on_merge_request, project: project, noteable: subject, position: outdated_position) }
  let!(:outdated_diff_note2) { create(:diff_note_on_merge_request, project: project, noteable: subject, in_reply_to: outdated_diff_note1) }
  let!(:discussion_note1) { create(:discussion_note_on_merge_request, project: project, noteable: subject) }
  let!(:discussion_note2) { create(:discussion_note_on_merge_request, in_reply_to: discussion_note1) }
  let!(:commit_diff_note1) { create(:diff_note_on_commit, project: project) }
  let!(:commit_diff_note2) { create(:diff_note_on_commit, project: project, in_reply_to: commit_diff_note1) }
  let!(:commit_note1) { create(:note_on_commit, project: project) }
  let!(:commit_note2) { create(:note_on_commit, project: project) }
  let!(:commit_discussion_note1) { create(:discussion_note_on_commit, project: project) }
  let!(:commit_discussion_note2) { create(:discussion_note_on_commit, in_reply_to: commit_discussion_note1) }
  let!(:commit_discussion_note3) { create(:discussion_note_on_commit, project: project) }
  let!(:note1) { create(:note, project: project, noteable: subject) }
  let!(:note2) { create(:note, project: project, noteable: subject) }

  let(:active_position2) do
    Gitlab::Diff::Position.new(
      old_path: "files/ruby/popen.rb",
      new_path: "files/ruby/popen.rb",
      old_line: 16,
      new_line: 22,
      diff_refs: subject.diff_refs
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
    let(:discussions) { subject.discussions }

    it 'includes discussions for diff notes, commit diff notes, commit notes, and regular notes' do
      expect(discussions).to eq([
        DiffDiscussion.new([active_diff_note1, active_diff_note2], subject),
        DiffDiscussion.new([active_diff_note3], subject),
        DiffDiscussion.new([outdated_diff_note1, outdated_diff_note2], subject),
        Discussion.new([discussion_note1, discussion_note2], subject),
        DiffDiscussion.new([commit_diff_note1, commit_diff_note2], subject),
        OutOfContextDiscussion.new([commit_note1, commit_note2], subject),
        Discussion.new([commit_discussion_note1, commit_discussion_note2], subject),
        Discussion.new([commit_discussion_note3], subject),
        IndividualNoteDiscussion.new([note1], subject),
        IndividualNoteDiscussion.new([note2], subject)
      ])
    end
  end

  describe '#grouped_diff_discussions' do
    let(:grouped_diff_discussions) { subject.grouped_diff_discussions }

    it "includes active discussions" do
      discussions = grouped_diff_discussions.values.flatten

      expect(discussions.count).to eq(2)
      expect(discussions.map(&:id)).to eq([active_diff_note1.discussion_id, active_diff_note3.discussion_id])
      expect(discussions.all?(&:active?)).to be true

      expect(discussions.first.notes).to eq([active_diff_note1, active_diff_note2])
      expect(discussions.last.notes).to eq([active_diff_note3])
    end

    it "doesn't include outdated discussions" do
      expect(grouped_diff_discussions.values.flatten.map(&:id)).not_to include(outdated_diff_note1.discussion_id)
    end

    it "groups the discussions by line code" do
      expect(grouped_diff_discussions[active_diff_note1.line_code].first.id).to eq(active_diff_note1.discussion_id)
      expect(grouped_diff_discussions[active_diff_note3.line_code].first.id).to eq(active_diff_note3.discussion_id)
    end
  end

  context "discussion status" do
    let(:first_discussion) { build_stubbed(:discussion_note_on_merge_request, noteable: subject, project: project).to_discussion }
    let(:second_discussion) { build_stubbed(:discussion_note_on_merge_request, noteable: subject, project: project).to_discussion }
    let(:third_discussion) { build_stubbed(:discussion_note_on_merge_request, noteable: subject, project: project).to_discussion }

    before do
      allow(subject).to receive(:resolvable_discussions).and_return([first_discussion, second_discussion, third_discussion])
    end

    describe "#discussions_resolvable?" do
      context "when all discussions are unresolvable" do
        before do
          allow(first_discussion).to receive(:resolvable?).and_return(false)
          allow(second_discussion).to receive(:resolvable?).and_return(false)
          allow(third_discussion).to receive(:resolvable?).and_return(false)
        end

        it "returns false" do
          expect(subject.discussions_resolvable?).to be false
        end
      end

      context "when some discussions are unresolvable and some discussions are resolvable" do
        before do
          allow(first_discussion).to receive(:resolvable?).and_return(true)
          allow(second_discussion).to receive(:resolvable?).and_return(false)
          allow(third_discussion).to receive(:resolvable?).and_return(true)
        end

        it "returns true" do
          expect(subject.discussions_resolvable?).to be true
        end
      end

      context "when all discussions are resolvable" do
        before do
          allow(first_discussion).to receive(:resolvable?).and_return(true)
          allow(second_discussion).to receive(:resolvable?).and_return(true)
          allow(third_discussion).to receive(:resolvable?).and_return(true)
        end

        it "returns true" do
          expect(subject.discussions_resolvable?).to be true
        end
      end
    end

    describe "#discussions_resolved?" do
      context "when discussions are not resolvable" do
        before do
          allow(subject).to receive(:discussions_resolvable?).and_return(false)
        end

        it "returns false" do
          expect(subject.discussions_resolved?).to be false
        end
      end

      context "when discussions are resolvable" do
        before do
          allow(subject).to receive(:discussions_resolvable?).and_return(true)

          allow(first_discussion).to receive(:resolvable?).and_return(true)
          allow(second_discussion).to receive(:resolvable?).and_return(false)
          allow(third_discussion).to receive(:resolvable?).and_return(true)
        end

        context "when all resolvable discussions are resolved" do
          before do
            allow(first_discussion).to receive(:resolved?).and_return(true)
            allow(third_discussion).to receive(:resolved?).and_return(true)
          end

          it "returns true" do
            expect(subject.discussions_resolved?).to be true
          end
        end

        context "when some resolvable discussions are not resolved" do
          before do
            allow(first_discussion).to receive(:resolved?).and_return(true)
            allow(third_discussion).to receive(:resolved?).and_return(false)
          end

          it "returns false" do
            expect(subject.discussions_resolved?).to be false
          end
        end
      end
    end

    describe "#discussions_to_be_resolved" do
      before do
        allow(first_discussion).to receive(:to_be_resolved?).and_return(true)
        allow(second_discussion).to receive(:to_be_resolved?).and_return(false)
        allow(third_discussion).to receive(:to_be_resolved?).and_return(false)
      end

      it 'includes only discussions that need to be resolved' do
        expect(subject.discussions_to_be_resolved).to eq([first_discussion])
      end
    end

    describe '#discussions_can_be_resolved_by?' do
      let(:user) { build(:user) }

      context 'all discussions can be resolved by the user' do
        before do
          allow(first_discussion).to receive(:can_resolve?).with(user).and_return(true)
          allow(second_discussion).to receive(:can_resolve?).with(user).and_return(true)
          allow(third_discussion).to receive(:can_resolve?).with(user).and_return(true)
        end

        it 'allows a user to resolve the discussions' do
          expect(subject.discussions_can_be_resolved_by?(user)).to be(true)
        end
      end

      context 'one discussion cannot be resolved by the user' do
        before do
          allow(first_discussion).to receive(:can_resolve?).with(user).and_return(true)
          allow(second_discussion).to receive(:can_resolve?).with(user).and_return(true)
          allow(third_discussion).to receive(:can_resolve?).with(user).and_return(false)
        end

        it 'allows a user to resolve the discussions' do
          expect(subject.discussions_can_be_resolved_by?(user)).to be(false)
        end
      end
    end
  end

  describe '.replyable_types' do
    it 'exposes the replyable types' do
      expect(described_class.replyable_types).to include('Issue', 'MergeRequest')
    end
  end

  describe '.resolvable_types' do
    it 'exposes the replyable types' do
      expect(described_class.resolvable_types).to include('MergeRequest')
    end
  end

  describe '#capped_notes_count' do
    context 'notes number < 10' do
      it 'the number of notes is returned' do
        expect(subject.capped_notes_count(10)).to eq(9)
      end
    end

    context 'notes number > 10' do
      before do
        create_list(:note, 2, project: project, noteable: subject)
      end

      it '10 is returned' do
        expect(subject.capped_notes_count(10)).to eq(10)
      end
    end
  end
end
