# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Noteable, feature_category: :code_review_workflow do
  let!(:active_diff_note1) { create(:diff_note_on_merge_request) }
  let(:project) { active_diff_note1.project }

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
      old_path: 'files/ruby/popen.rb',
      new_path: 'files/ruby/popen.rb',
      old_line: 16,
      new_line: 22,
      diff_refs: subject.diff_refs
    )
  end

  let(:outdated_position) do
    Gitlab::Diff::Position.new(
      old_path: 'files/ruby/popen.rb',
      new_path: 'files/ruby/popen.rb',
      old_line: nil,
      new_line: 9,
      diff_refs: project.commit('874797c3a73b60d2187ed6e2fcabd289ff75171e').diff_refs
    )
  end

  subject { active_diff_note1.noteable }

  describe '#discussions' do
    let(:discussions) { subject.discussions }

    it 'includes discussions for diff notes, commit diff notes, commit notes, and regular notes' do
      expect(discussions).to eq(
        [
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

  # rubocop:disable RSpec/MultipleMemoizedHelpers
  describe '#commenters' do
    shared_examples 'commenters' do
      it 'does not automatically include the noteable author' do
        expect(commenters).not_to include(noteable.author)
      end

      context 'with no user' do
        it 'contains a distinct list of non-internal note authors' do
          expect(commenters).to contain_exactly(commenter, another_commenter)
        end
      end

      context 'with non project member' do
        let(:current_user) { create(:user) }

        it 'contains a distinct list of non-internal note authors' do
          expect(commenters).to contain_exactly(commenter, another_commenter)
        end

        it 'does not include a commenter from another noteable' do
          expect(commenters).not_to include(other_noteable_commenter)
        end
      end
    end

    let_it_be(:commenter) { create(:user) }
    let_it_be(:another_commenter) { create(:user) }
    let_it_be(:internal_commenter) { create(:user) }
    let_it_be(:other_noteable_commenter) { create(:user) }

    let(:current_user) {}
    let(:commenters) { noteable.commenters(user: current_user) }

    let!(:comments) { create_list(:note, 2, author: commenter, noteable: noteable, project: noteable.project) }
    let!(:more_comments) { create_list(:note, 2, author: another_commenter, noteable: noteable, project: noteable.project) }

    context 'when noteable is an issue' do
      let(:noteable) { create(:issue) }

      let!(:internal_comments) { create_list(:note, 2, author: internal_commenter, noteable: noteable, project: noteable.project, internal: true) }
      let!(:other_noteable_comments) { create_list(:note, 2, author: other_noteable_commenter, noteable: create(:issue, project: noteable.project), project: noteable.project) }

      it_behaves_like 'commenters'

      context 'with reporter' do
        let(:current_user) { create(:user) }

        before do
          noteable.project.add_reporter(current_user)
        end

        it 'contains a distinct list of non-internal note authors' do
          expect(commenters).to contain_exactly(commenter, another_commenter, internal_commenter)
        end

        context 'with noteable author' do
          let(:current_user) { noteable.author }

          it 'contains a distinct list of non-internal note authors' do
            expect(commenters).to contain_exactly(commenter, another_commenter, internal_commenter)
          end
        end
      end
    end

    context 'when noteable is a merge request' do
      let(:noteable) { create(:merge_request) }

      let!(:other_noteable_comments) { create_list(:note, 2, author: other_noteable_commenter, noteable: create(:merge_request, source_project: noteable.project, source_branch: 'feat123'), project: noteable.project) }

      it_behaves_like 'commenters'
    end
  end
  # rubocop:enable RSpec/MultipleMemoizedHelpers

  describe '#discussion_ids_relation' do
    it 'returns ordered discussion_ids' do
      discussion_ids = subject.discussion_ids_relation.pluck(:discussion_id)

      expect(discussion_ids).to eq([
        active_diff_note1,
        active_diff_note3,
        outdated_diff_note1,
        discussion_note1,
        note1,
        note2
      ].map(&:discussion_id))
    end
  end

  describe '#discussion_root_note_ids' do
    let!(:label_event) do
      create(:resource_label_event, merge_request: subject).tap do |event|
        # Create an extra label event that should get grouped with the above event so this one should not
        # be included in the resulting root nodes
        create(:resource_label_event, merge_request: subject, user: event.user, created_at: event.created_at)
      end
    end

    let!(:system_note) { create(:system_note, project: project, noteable: subject) }
    let!(:milestone_event) { create(:resource_milestone_event, merge_request: subject) }
    let!(:state_event) { create(:resource_state_event, merge_request: subject) }

    let(:discussions_by_created_asc) do
      [
        a_hash_including(table_name: 'notes', id: active_diff_note1.id),
        a_hash_including(table_name: 'notes', id: active_diff_note3.id),
        a_hash_including(table_name: 'notes', id: outdated_diff_note1.id),
        a_hash_including(table_name: 'notes', id: discussion_note1.id),
        a_hash_including(table_name: 'notes', id: commit_diff_note1.id),
        a_hash_including(table_name: 'notes', id: commit_note1.id),
        a_hash_including(table_name: 'notes', id: commit_note2.id),
        a_hash_including(table_name: 'notes', id: commit_discussion_note1.id),
        a_hash_including(table_name: 'notes', id: commit_discussion_note3.id),
        a_hash_including(table_name: 'notes', id: note1.id),
        a_hash_including(table_name: 'notes', id: note2.id),
        a_hash_including(table_name: 'resource_label_events', id: label_event.id),
        a_hash_including(table_name: 'notes', id: system_note.id),
        a_hash_including(table_name: 'resource_milestone_events', id: milestone_event.id),
        a_hash_including(table_name: 'resource_state_events', id: state_event.id)
      ]
    end

    it 'returns ordered discussion_ids and synthetic note ids' do
      discussions = subject.discussion_root_note_ids(notes_filter: UserPreference::NOTES_FILTERS[:all_notes]).map do |n|
        { table_name: n.table_name, id: n.id }
      end

      expect(discussions).to match(discussions_by_created_asc)
    end

    context 'when sort param is given' do
      it 'returns discussion_ids and synthetic note ids in ascending order' do
        discussions = subject.discussion_root_note_ids(notes_filter: UserPreference::NOTES_FILTERS[:all_notes], sort: :created_asc).map do |n|
          { table_name: n.table_name, id: n.id }
        end

        expect(discussions).to match(discussions_by_created_asc)
      end

      it 'returns discussion_ids and synthetic note ids in descending order' do
        discussions = subject.discussion_root_note_ids(notes_filter: UserPreference::NOTES_FILTERS[:all_notes], sort: :created_desc).map do |n|
          { table_name: n.table_name, id: n.id }
        end

        expect(discussions).to match(discussions_by_created_asc.reverse)
      end

      it 'raises an error when sort param is invalid' do
        expect do
          subject.discussion_root_note_ids(notes_filter: UserPreference::NOTES_FILTERS[:all_notes], sort: :invalid)
        end.to raise_error(ArgumentError, 'Invalid sort order')
      end
    end

    it 'filters by comments only' do
      discussions = subject.discussion_root_note_ids(notes_filter: UserPreference::NOTES_FILTERS[:only_comments]).map do |n|
        { table_name: n.table_name, id: n.id }
      end

      expect(discussions).to match(
        [
          a_hash_including(table_name: 'notes', id: active_diff_note1.id),
          a_hash_including(table_name: 'notes', id: active_diff_note3.id),
          a_hash_including(table_name: 'notes', id: outdated_diff_note1.id),
          a_hash_including(table_name: 'notes', id: discussion_note1.id),
          a_hash_including(table_name: 'notes', id: commit_diff_note1.id),
          a_hash_including(table_name: 'notes', id: commit_note1.id),
          a_hash_including(table_name: 'notes', id: commit_note2.id),
          a_hash_including(table_name: 'notes', id: commit_discussion_note1.id),
          a_hash_including(table_name: 'notes', id: commit_discussion_note3.id),
          a_hash_including(table_name: 'notes', id: note1.id),
          a_hash_including(table_name: 'notes', id: note2.id)
        ])
    end

    it 'filters by system notes only' do
      discussions = subject.discussion_root_note_ids(notes_filter: UserPreference::NOTES_FILTERS[:only_activity]).map do |n|
        { table_name: n.table_name, id: n.id }
      end

      expect(discussions).to match(
        [
          a_hash_including(table_name: 'resource_label_events', id: label_event.id),
          a_hash_including(table_name: 'notes', id: system_note.id),
          a_hash_including(table_name: 'resource_milestone_events', id: milestone_event.id),
          a_hash_including(table_name: 'resource_state_events', id: state_event.id)
        ])
    end
  end

  describe '#grouped_diff_discussions' do
    let(:grouped_diff_discussions) { subject.grouped_diff_discussions }

    it 'includes active discussions' do
      discussions = grouped_diff_discussions.values.flatten

      expect(discussions.count).to eq(2)
      expect(discussions.map(&:id)).to eq([active_diff_note1.discussion_id, active_diff_note3.discussion_id])
      expect(discussions.all?(&:active?)).to be true

      expect(discussions.first.notes).to eq([active_diff_note1, active_diff_note2])
      expect(discussions.last.notes).to eq([active_diff_note3])
    end

    it 'does not include outdated discussions' do
      expect(grouped_diff_discussions.values.flatten.map(&:id)).not_to include(outdated_diff_note1.discussion_id)
    end

    it 'groups the discussions by line code' do
      expect(grouped_diff_discussions[active_diff_note1.line_code].first.id).to eq(active_diff_note1.discussion_id)
      expect(grouped_diff_discussions[active_diff_note3.line_code].first.id).to eq(active_diff_note3.discussion_id)
    end
  end

  context 'discussion status' do
    let(:first_discussion) { build_stubbed(:discussion_note_on_merge_request, noteable: subject, project: project).to_discussion }
    let(:second_discussion) { build_stubbed(:discussion_note_on_merge_request, noteable: subject, project: project).to_discussion }
    let(:third_discussion) { build_stubbed(:discussion_note_on_merge_request, noteable: subject, project: project).to_discussion }

    before do
      allow(subject).to receive(:resolvable_discussions).and_return([first_discussion, second_discussion, third_discussion])
    end

    describe '#discussions_resolvable?' do
      context 'when all discussions are unresolvable' do
        before do
          allow(first_discussion).to receive(:resolvable?).and_return(false)
          allow(second_discussion).to receive(:resolvable?).and_return(false)
          allow(third_discussion).to receive(:resolvable?).and_return(false)
        end

        it 'returns false' do
          expect(subject.discussions_resolvable?).to be false
        end
      end

      context 'when some discussions are unresolvable and some discussions are resolvable' do
        before do
          allow(first_discussion).to receive(:resolvable?).and_return(true)
          allow(second_discussion).to receive(:resolvable?).and_return(false)
          allow(third_discussion).to receive(:resolvable?).and_return(true)
        end

        it 'returns true' do
          expect(subject.discussions_resolvable?).to be true
        end
      end

      context 'when all discussions are resolvable' do
        before do
          allow(first_discussion).to receive(:resolvable?).and_return(true)
          allow(second_discussion).to receive(:resolvable?).and_return(true)
          allow(third_discussion).to receive(:resolvable?).and_return(true)
        end

        it 'returns true' do
          expect(subject.discussions_resolvable?).to be true
        end
      end
    end

    describe '#discussions_resolved?' do
      context 'when discussions are not resolvable' do
        before do
          allow(subject).to receive(:discussions_resolvable?).and_return(false)
        end

        it 'returns false' do
          expect(subject.discussions_resolved?).to be false
        end
      end

      context 'when discussions are resolvable' do
        before do
          allow(subject).to receive(:discussions_resolvable?).and_return(true)

          allow(first_discussion).to receive(:resolvable?).and_return(true)
          allow(second_discussion).to receive(:resolvable?).and_return(false)
          allow(third_discussion).to receive(:resolvable?).and_return(true)
        end

        context 'when all resolvable discussions are resolved' do
          before do
            allow(first_discussion).to receive(:resolved?).and_return(true)
            allow(third_discussion).to receive(:resolved?).and_return(true)
          end

          it 'returns true' do
            expect(subject.discussions_resolved?).to be true
          end
        end

        context 'when some resolvable discussions are not resolved' do
          before do
            allow(first_discussion).to receive(:resolved?).and_return(true)
            allow(third_discussion).to receive(:resolved?).and_return(false)
          end

          it 'returns false' do
            expect(subject.discussions_resolved?).to be false
          end
        end
      end
    end

    describe '#discussions_to_be_resolved' do
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
    it 'exposes the resolvable types' do
      expect(described_class.resolvable_types).to include('Issue', 'MergeRequest', 'DesignManagement::Design')
    end
  end

  describe '.email_creatable_types' do
    it 'exposes the email creatable types' do
      expect(described_class.email_creatable_types).to include('Issue')
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

  describe '#has_any_diff_note_positions?' do
    let(:source_branch) { 'compare-with-merge-head-source' }
    let(:target_branch) { 'compare-with-merge-head-target' }
    let(:merge_request) { create(:merge_request, source_branch: source_branch, target_branch: target_branch) }

    let!(:note) do
      path = 'files/markdown/ruby-style-guide.md'

      position = Gitlab::Diff::Position.new(
        old_path: path,
        new_path: path,
        new_line: 508,
        diff_refs: merge_request.diff_refs
      )

      create(:diff_note_on_merge_request, project: merge_request.project, position: position, noteable: merge_request)
    end

    before do
      MergeRequests::MergeToRefService.new(project: merge_request.project, current_user: merge_request.author).execute(merge_request)
      Discussions::CaptureDiffNotePositionsService.new(merge_request).execute
    end

    it 'returns true when it has diff note positions' do
      expect(merge_request.has_any_diff_note_positions?).to be(true)
    end

    it 'returns false when it has notes but no diff note positions' do
      DiffNotePosition.where(note: note).find_each(&:delete)

      expect(merge_request.has_any_diff_note_positions?).to be(false)
    end

    it 'returns false when it has no notes' do
      merge_request.notes.find_each(&:destroy)

      expect(merge_request.has_any_diff_note_positions?).to be(false)
    end
  end

  describe '#creatable_note_email_address' do
    let_it_be(:user) { create(:user) }
    let_it_be(:source_branch) { 'compare-with-merge-head-source' }

    let(:issue) { create(:issue, project: project) }
    let(:snippet) { build(:personal_snippet) }

    context 'incoming email enabled' do
      before do
        stub_incoming_email_setting(enabled: true, address: "p+%{key}@gl.ab")
      end

      it 'returns the address to create a note' do
        address = "p+#{project.full_path_slug}-#{project.project_id}-#{user.incoming_email_token}-issue-#{issue.iid}@gl.ab"

        expect(issue.creatable_note_email_address(user)).to eq(address)
      end

      it 'returns nil for unsupported types' do
        expect(snippet.creatable_note_email_address(user)).to be_nil
      end
    end

    context 'incoming email disabled' do
      before do
        stub_incoming_email_setting(enabled: false)
      end

      it 'returns nil' do
        expect(issue.creatable_note_email_address(user)).to be_nil
      end
    end
  end
end
