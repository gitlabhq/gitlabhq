# frozen_string_literal: true

require 'spec_helper'

describe ::SystemNotes::IssuablesService do
  include ProjectForksHelper

  let_it_be(:group)   { create(:group) }
  let_it_be(:project) { create(:project, :repository, group: group) }
  let_it_be(:author)  { create(:user) }
  let(:noteable)      { create(:issue, project: project) }
  let(:issue)         { noteable }

  let(:service) { described_class.new(noteable: noteable, project: project, author: author) }

  describe '#change_assignee' do
    subject { service.change_assignee(assignee) }

    let(:assignee) { create(:user) }

    it_behaves_like 'a system note' do
      let(:action) { 'assignee' }
    end

    context 'when assignee added' do
      it_behaves_like 'a note with overridable created_at'

      it 'sets the note text' do
        expect(subject.note).to eq "assigned to @#{assignee.username}"
      end
    end

    context 'when assignee removed' do
      let(:assignee) { nil }

      it_behaves_like 'a note with overridable created_at'

      it 'sets the note text' do
        expect(subject.note).to eq 'removed assignee'
      end
    end
  end

  describe '#change_issuable_assignees' do
    subject { service.change_issuable_assignees([assignee]) }

    let(:assignee) { create(:user) }
    let(:assignee1) { create(:user) }
    let(:assignee2) { create(:user) }
    let(:assignee3) { create(:user) }

    it_behaves_like 'a system note' do
      let(:action) { 'assignee' }
    end

    def build_note(old_assignees, new_assignees)
      issue.assignees = new_assignees
      service.change_issuable_assignees(old_assignees).note
    end

    it_behaves_like 'a note with overridable created_at'

    it 'builds a correct phrase when an assignee is added to a non-assigned issue' do
      expect(build_note([], [assignee1])).to eq "assigned to @#{assignee1.username}"
    end

    it 'builds a correct phrase when assignee removed' do
      expect(build_note([assignee1], [])).to eq "unassigned @#{assignee1.username}"
    end

    it 'builds a correct phrase when assignees changed' do
      expect(build_note([assignee1], [assignee2])).to eq \
        "assigned to @#{assignee2.username} and unassigned @#{assignee1.username}"
    end

    it 'builds a correct phrase when three assignees removed and one added' do
      expect(build_note([assignee, assignee1, assignee2], [assignee3])).to eq \
        "assigned to @#{assignee3.username} and unassigned @#{assignee.username}, @#{assignee1.username}, and @#{assignee2.username}"
    end

    it 'builds a correct phrase when one assignee changed from a set' do
      expect(build_note([assignee, assignee1], [assignee, assignee2])).to eq \
        "assigned to @#{assignee2.username} and unassigned @#{assignee1.username}"
    end

    it 'builds a correct phrase when one assignee removed from a set' do
      expect(build_note([assignee, assignee1, assignee2], [assignee, assignee1])).to eq \
        "unassigned @#{assignee2.username}"
    end

    it 'builds a correct phrase when the locale is different' do
      Gitlab::I18n.with_locale('pt-BR') do
        expect(build_note([assignee, assignee1, assignee2], [assignee3])).to eq \
          "assigned to @#{assignee3.username} and unassigned @#{assignee.username}, @#{assignee1.username}, and @#{assignee2.username}"
      end
    end
  end

  describe '#change_milestone' do
    subject { service.change_milestone(milestone) }

    context 'for a project milestone' do
      let(:milestone) { create(:milestone, project: project) }

      it_behaves_like 'a system note' do
        let(:action) { 'milestone' }
      end

      context 'when milestone added' do
        it 'sets the note text' do
          reference = milestone.to_reference(format: :iid)

          expect(subject.note).to eq "changed milestone to #{reference}"
        end

        it_behaves_like 'a note with overridable created_at'
      end

      context 'when milestone removed' do
        let(:milestone) { nil }

        it 'sets the note text' do
          expect(subject.note).to eq 'removed milestone'
        end

        it_behaves_like 'a note with overridable created_at'
      end
    end

    context 'for a group milestone' do
      let(:milestone) { create(:milestone, group: group) }

      it_behaves_like 'a system note' do
        let(:action) { 'milestone' }
      end

      context 'when milestone added' do
        it 'sets the note text to use the milestone name' do
          expect(subject.note).to eq "changed milestone to #{milestone.to_reference(format: :name)}"
        end

        it_behaves_like 'a note with overridable created_at'
      end

      context 'when milestone removed' do
        let(:milestone) { nil }

        it 'sets the note text' do
          expect(subject.note).to eq 'removed milestone'
        end

        it_behaves_like 'a note with overridable created_at'
      end
    end
  end

  describe '#change_status' do
    subject { service.change_status(status, source) }

    context 'with status reopened' do
      let(:status) { 'reopened' }
      let(:source) { nil }

      it_behaves_like 'a note with overridable created_at'

      it_behaves_like 'a system note' do
        let(:action) { 'opened' }
      end
    end

    context 'with a source' do
      let(:status) { 'opened' }
      let(:source) { double('commit', gfm_reference: 'commit 123456') }

      it_behaves_like 'a note with overridable created_at'

      it 'sets the note text' do
        expect(subject.note).to eq "#{status} via commit 123456"
      end
    end
  end

  describe '#change_title' do
    let(:noteable) { create(:issue, project: project, title: 'Lorem ipsum') }

    subject { service.change_title('Old title') }

    context 'when noteable responds to `title`' do
      it_behaves_like 'a system note' do
        let(:action) { 'title' }
      end

      it_behaves_like 'a note with overridable created_at'

      it 'sets the note text' do
        expect(subject.note)
          .to eq "changed title from **{-Old title-}** to **{+Lorem ipsum+}**"
      end
    end
  end

  describe '#change_description' do
    subject { service.change_description }

    context 'when noteable responds to `description`' do
      it_behaves_like 'a system note' do
        let(:action) { 'description' }
      end

      it_behaves_like 'a note with overridable created_at'

      it 'sets the note text' do
        expect(subject.note).to eq('changed the description')
      end

      it 'associates the related description version' do
        noteable.update!(description: 'New description')

        description_version_id = subject.system_note_metadata.description_version_id

        expect(description_version_id).not_to be_nil
        expect(description_version_id).to eq(noteable.saved_description_version.id)
      end
    end
  end

  describe '#change_issue_confidentiality' do
    subject { service.change_issue_confidentiality }

    context 'issue has been made confidential' do
      before do
        noteable.update_attribute(:confidential, true)
      end

      it_behaves_like 'a system note' do
        let(:action) { 'confidential' }
      end

      it 'sets the note text' do
        expect(subject.note).to eq 'made the issue confidential'
      end
    end

    context 'issue has been made visible' do
      it_behaves_like 'a system note' do
        let(:action) { 'visible' }
      end

      it 'sets the note text' do
        expect(subject.note).to eq 'made the issue visible to everyone'
      end
    end
  end

  describe '#cross_reference' do
    let(:service) { described_class.new(noteable: noteable, author: author) }

    let(:mentioner) { create(:issue, project: project) }

    subject { service.cross_reference(mentioner) }

    it_behaves_like 'a system note' do
      let(:action) { 'cross_reference' }
    end

    context 'when cross-reference disallowed' do
      before do
        expect_any_instance_of(described_class).to receive(:cross_reference_disallowed?).and_return(true)
      end

      it 'returns nil' do
        expect(subject).to be_nil
      end

      it 'does not create a system note metadata record' do
        expect { subject }.not_to change { SystemNoteMetadata.count }
      end
    end

    context 'when cross-reference allowed' do
      before do
        expect_any_instance_of(described_class).to receive(:cross_reference_disallowed?).and_return(false)
      end

      it_behaves_like 'a system note' do
        let(:action) { 'cross_reference' }
      end

      it_behaves_like 'a note with overridable created_at'

      describe 'note_body' do
        context 'cross-project' do
          let(:project2) { create(:project, :repository) }
          let(:mentioner) { create(:issue, project: project2) }

          context 'from Commit' do
            let(:mentioner) { project2.repository.commit }

            it 'references the mentioning commit' do
              expect(subject.note).to eq "mentioned in commit #{mentioner.to_reference(project)}"
            end
          end

          context 'from non-Commit' do
            it 'references the mentioning object' do
              expect(subject.note).to eq "mentioned in issue #{mentioner.to_reference(project)}"
            end
          end
        end

        context 'within the same project' do
          context 'from Commit' do
            let(:mentioner) { project.repository.commit }

            it 'references the mentioning commit' do
              expect(subject.note).to eq "mentioned in commit #{mentioner.to_reference}"
            end
          end

          context 'from non-Commit' do
            it 'references the mentioning object' do
              expect(subject.note).to eq "mentioned in issue #{mentioner.to_reference}"
            end
          end
        end
      end
    end
  end

  describe '#cross_reference_exists?' do
    let(:commit0) { project.commit }
    let(:commit1) { project.commit('HEAD~2') }

    context 'issue from commit' do
      before do
        # Mention issue (noteable) from commit0
        service.cross_reference(commit0)
      end

      it 'is truthy when already mentioned' do
        expect(service.cross_reference_exists?(commit0))
          .to be_truthy
      end

      it 'is falsey when not already mentioned' do
        expect(service.cross_reference_exists?(commit1))
          .to be_falsey
      end

      context 'legacy capitalized cross reference' do
        before do
          # Mention issue (noteable) from commit0
          system_note = service.cross_reference(commit0)
          system_note.update(note: system_note.note.capitalize)
        end

        it 'is truthy when already mentioned' do
          expect(service.cross_reference_exists?(commit0))
            .to be_truthy
        end
      end
    end

    context 'commit from commit' do
      let(:service) { described_class.new(noteable: commit0, author: author) }

      before do
        # Mention commit1 from commit0
        service.cross_reference(commit1)
      end

      it 'is truthy when already mentioned' do
        expect(service.cross_reference_exists?(commit1))
          .to be_truthy
      end

      it 'is falsey when not already mentioned' do
        service = described_class.new(noteable: commit1, author: author)

        expect(service.cross_reference_exists?(commit0))
          .to be_falsey
      end

      context 'legacy capitalized cross reference' do
        before do
          # Mention commit1 from commit0
          system_note = service.cross_reference(commit1)
          system_note.update(note: system_note.note.capitalize)
        end

        it 'is truthy when already mentioned' do
          expect(service.cross_reference_exists?(commit1))
            .to be_truthy
        end
      end
    end

    context 'commit with cross-reference from fork', :sidekiq_might_not_need_inline do
      let(:author2) { create(:project_member, :reporter, user: create(:user), project: project).user }
      let(:forked_project) { fork_project(project, author2, repository: true) }
      let(:commit2) { forked_project.commit }

      let(:service) { described_class.new(noteable: noteable, author: author2) }

      before do
        service.cross_reference(commit0)
      end

      it 'is true when a fork mentions an external issue' do
        expect(service.cross_reference_exists?(commit2))
            .to be true
      end

      context 'legacy capitalized cross reference' do
        before do
          system_note = service.cross_reference(commit0)
          system_note.update(note: system_note.note.capitalize)
        end

        it 'is true when a fork mentions an external issue' do
          expect(service.cross_reference_exists?(commit2))
              .to be true
        end
      end
    end
  end

  describe '#change_task_status' do
    let(:noteable) { create(:issue, project: project) }
    let(:task)     { double(:task, complete?: true, source: 'task') }

    subject { service.change_task_status(task) }

    it_behaves_like 'a system note' do
      let(:action) { 'task' }
    end

    it "posts the 'marked the task as complete' system note" do
      expect(subject.note).to eq("marked the task **task** as completed")
    end
  end

  describe '#noteable_moved' do
    let(:new_project) { create(:project) }
    let(:new_noteable) { create(:issue, project: new_project) }

    subject do
      # service = described_class.new(noteable: noteable, project: project, author: author)
      service.noteable_moved(new_noteable, direction)
    end

    shared_examples 'cross project mentionable' do
      include MarkupHelper

      it 'contains cross reference to new noteable' do
        expect(subject.note).to include cross_project_reference(new_project, new_noteable)
      end

      it 'mentions referenced noteable' do
        expect(subject.note).to include new_noteable.to_reference
      end

      it 'mentions referenced project' do
        expect(subject.note).to include new_project.full_path
      end
    end

    context 'moved to' do
      let(:direction) { :to }

      it_behaves_like 'cross project mentionable'
      it_behaves_like 'a system note' do
        let(:action) { 'moved' }
      end

      it 'notifies about noteable being moved to' do
        expect(subject.note).to match('moved to')
      end
    end

    context 'moved from' do
      let(:direction) { :from }

      it_behaves_like 'cross project mentionable'
      it_behaves_like 'a system note' do
        let(:action) { 'moved' }
      end

      it 'notifies about noteable being moved from' do
        expect(subject.note).to match('moved from')
      end
    end

    context 'invalid direction' do
      let(:direction) { :invalid }

      it 'raises error' do
        expect { subject }.to raise_error StandardError, /Invalid direction/
      end
    end
  end

  describe '#mark_duplicate_issue' do
    subject { service.mark_duplicate_issue(canonical_issue) }

    context 'within the same project' do
      let(:canonical_issue) { create(:issue, project: project) }

      it_behaves_like 'a system note' do
        let(:action) { 'duplicate' }
      end

      it { expect(subject.note).to eq "marked this issue as a duplicate of #{canonical_issue.to_reference}" }
    end

    context 'across different projects' do
      let(:other_project) { create(:project) }
      let(:canonical_issue) { create(:issue, project: other_project) }

      it_behaves_like 'a system note' do
        let(:action) { 'duplicate' }
      end

      it { expect(subject.note).to eq "marked this issue as a duplicate of #{canonical_issue.to_reference(project)}" }
    end
  end

  describe '#mark_canonical_issue_of_duplicate' do
    subject { service.mark_canonical_issue_of_duplicate(duplicate_issue) }

    context 'within the same project' do
      let(:duplicate_issue) { create(:issue, project: project) }

      it_behaves_like 'a system note' do
        let(:action) { 'duplicate' }
      end

      it { expect(subject.note).to eq "marked #{duplicate_issue.to_reference} as a duplicate of this issue" }
    end

    context 'across different projects' do
      let(:other_project) { create(:project) }
      let(:duplicate_issue) { create(:issue, project: other_project) }

      it_behaves_like 'a system note' do
        let(:action) { 'duplicate' }
      end

      it { expect(subject.note).to eq "marked #{duplicate_issue.to_reference(project)} as a duplicate of this issue" }
    end
  end

  describe '#discussion_lock' do
    subject { service.discussion_lock }

    context 'discussion unlocked' do
      it_behaves_like 'a system note' do
        let(:action) { 'unlocked' }
      end

      it 'creates the note text correctly' do
        [:issue, :merge_request].each do |type|
          issuable = create(type)

          service = described_class.new(noteable: issuable, author: author)
          expect(service.discussion_lock.note)
            .to eq("unlocked this #{type.to_s.titleize.downcase}")
        end
      end
    end

    context 'discussion locked' do
      before do
        noteable.update_attribute(:discussion_locked, true)
      end

      it_behaves_like 'a system note' do
        let(:action) { 'locked' }
      end

      it 'creates the note text correctly' do
        [:issue, :merge_request].each do |type|
          issuable = create(type, discussion_locked: true)

          service = described_class.new(noteable: issuable, author: author)
          expect(service.discussion_lock.note)
            .to eq("locked this #{type.to_s.titleize.downcase}")
        end
      end
    end
  end

  describe '#cross_reference_disallowed?' do
    context 'when mentioner is not a MergeRequest' do
      it 'is falsey' do
        mentioner = noteable.dup
        expect(service.cross_reference_disallowed?(mentioner))
          .to be_falsey
      end
    end

    context 'when mentioner is a MergeRequest' do
      let(:mentioner) { create(:merge_request, :simple, source_project: project) }
      let(:noteable)  { project.commit }

      it 'is truthy when noteable is in commits' do
        expect(mentioner).to receive(:commits).and_return([noteable])
        expect(service.cross_reference_disallowed?(mentioner))
          .to be_truthy
      end

      it 'is falsey when noteable is not in commits' do
        expect(mentioner).to receive(:commits).and_return([])
        expect(service.cross_reference_disallowed?(mentioner))
          .to be_falsey
      end
    end

    context 'when notable is an ExternalIssue' do
      let(:noteable) { ExternalIssue.new('EXT-1234', project) }

      it 'is truthy' do
        mentioner = noteable.dup
        expect(service.cross_reference_disallowed?(mentioner))
          .to be_truthy
      end
    end
  end
end
