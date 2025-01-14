# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::SystemNotes::IssuablesService, feature_category: :team_planning do
  include ProjectForksHelper

  let_it_be(:group)   { create(:group) }
  let_it_be(:project) { create(:project, :repository, group: group) }
  let_it_be(:author)  { create(:user) }

  let(:noteable)      { create(:issue, project: project) }
  let(:issue)         { noteable }

  let(:service) { described_class.new(noteable: noteable, container: project, author: author) }

  before_all do
    # Ensure support bot user is created so creation doesn't count towards query limit
    # and we don't try to obtain an exclusive lease within a transaction.
    # See https://gitlab.com/gitlab-org/gitlab/-/issues/509629
    Users::Internal.support_bot_id
  end

  describe '#relate_issuable' do
    let_it_be(:issue1) { create(:issue, project: project) }
    let_it_be(:issue2) { create(:issue, project: project) }

    let(:noteable_ref) { issue1 }

    subject(:system_note) { service.relate_issuable(noteable_ref) }

    context 'when issue marks another as related' do
      it_behaves_like 'a system note' do
        let(:action) { 'relate' }
      end

      it 'sets the note text' do
        expect(system_note.note).to eq "marked this issue as related to #{issue1.to_reference(project)}"
      end
    end

    context 'when issue marks several other issues as related' do
      let(:noteable_ref) { [issue1, issue2] }

      it_behaves_like 'a system note' do
        let(:action) { 'relate' }
      end

      it 'sets the note text' do
        expect(system_note.note).to eq(
          "marked this issue as related to #{issue1.to_reference(project)} and #{issue2.to_reference(project)}"
        )
      end
    end

    context 'with work items' do
      let_it_be(:noteable) { create(:work_item, :task, project: project) }

      it 'sets the note text with the correct work item type' do
        expect(subject.note).to eq "marked this task as related to #{noteable_ref.to_reference(project)}"
      end
    end
  end

  describe '#unrelate_issuable' do
    let(:noteable_ref) { create(:issue) }

    subject { service.unrelate_issuable(noteable_ref) }

    it_behaves_like 'a system note' do
      let(:action) { 'unrelate' }
    end

    context 'when issue relation is removed' do
      it 'sets the note text' do
        expect(subject.note).to eq "removed the relation with #{noteable_ref.to_reference(project)}"
      end
    end
  end

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

  describe '#change_issuable_reviewers' do
    subject { service.change_issuable_reviewers([reviewer]) }

    let_it_be(:noteable) { create(:merge_request, :simple, source_project: project) }
    let_it_be(:reviewer) { create(:user) }
    let_it_be(:reviewer1) { create(:user) }
    let_it_be(:reviewer2) { create(:user) }
    let_it_be(:reviewer3) { create(:user) }

    it_behaves_like 'a system note' do
      let(:action) { 'reviewer' }
    end

    def build_note(old_reviewers, new_reviewers)
      noteable.reviewers = new_reviewers
      service.change_issuable_reviewers(old_reviewers).note
    end

    it 'builds a correct phrase when a reviewer is added to a non-assigned merge request' do
      expect(build_note([], [reviewer1])).to eq "requested review from @#{reviewer1.username}"
    end

    it 'builds a correct phrase when reviewer is removed' do
      expect(build_note([reviewer], [])).to eq "removed review request for @#{reviewer.username}"
    end

    it 'builds a correct phrase when reviewers changed' do
      expect(build_note([reviewer1], [reviewer2])).to(
        eq("requested review from @#{reviewer2.username} and removed review request for @#{reviewer1.username}")
      )
    end

    it 'builds a correct phrase when three reviewers removed and one added' do
      expect(build_note([reviewer, reviewer1, reviewer2], [reviewer3])).to(
        eq("requested review from @#{reviewer3.username} and removed review request for @#{reviewer.username}, @#{reviewer1.username}, and @#{reviewer2.username}")
      )
    end

    it 'builds a correct phrase when one reviewer is changed from a set' do
      expect(build_note([reviewer, reviewer1], [reviewer, reviewer2])).to(
        eq("requested review from @#{reviewer2.username} and removed review request for @#{reviewer1.username}")
      )
    end

    it 'builds a correct phrase when one reviewer removed from a set' do
      expect(build_note([reviewer, reviewer1, reviewer2], [reviewer, reviewer1])).to(
        eq("removed review request for @#{reviewer2.username}")
      )
    end

    it 'builds a correct phrase when the locale is different' do
      Gitlab::I18n.with_locale('pt-BR') do
        expect(build_note([reviewer, reviewer1, reviewer2], [reviewer3])).to(
          eq("requested review from @#{reviewer3.username} and removed review request for @#{reviewer.username}, @#{reviewer1.username}, and @#{reviewer2.username}")
        )
      end
    end
  end

  describe '#request_review' do
    subject(:request_review) { service.request_review(reviewer, unapproved) }

    let_it_be(:reviewer) { create(:user) }
    let_it_be(:noteable) { create(:merge_request, :simple, source_project: project, reviewers: [reviewer]) }
    let(:unapproved) { false }

    it_behaves_like 'a system note' do
      let(:action) { 'reviewer' }
    end

    it 'builds a correct phrase when a review has been requested from a reviewer' do
      expect(request_review.note).to eq "requested review from #{reviewer.to_reference}"
    end

    context 'when unapproving' do
      let(:unapproved) { true }

      it 'builds a correct phrase when a review has been requested from a reviewer and the reviewer has been unapproved' do
        expect(request_review.note).to eq "requested review from #{reviewer.to_reference} and removed approval"
      end
    end
  end

  describe '#change_issuable_contacts' do
    subject { service.change_issuable_contacts(1, 1) }

    let_it_be(:noteable) { create(:issue, project: project) }

    it_behaves_like 'a system note' do
      let(:action) { 'contact' }
    end

    def build_note(added_count, removed_count)
      service.change_issuable_contacts(added_count, removed_count).note
    end

    it 'builds a correct phrase when one contact is added' do
      expect(build_note(1, 0)).to eq "added 1 contact"
    end

    it 'builds a correct phrase when one contact is removed' do
      expect(build_note(0, 1)).to eq "removed 1 contact"
    end

    it 'builds a correct phrase when one contact is added and one contact is removed' do
      expect(build_note(1, 1)).to(
        eq("added 1 contact and removed 1 contact")
      )
    end

    it 'builds a correct phrase when three contacts are added and one removed' do
      expect(build_note(3, 1)).to(
        eq("added 3 contacts and removed 1 contact")
      )
    end

    it 'builds a correct phrase when three contacts are removed and one added' do
      expect(build_note(1, 3)).to(
        eq("added 1 contact and removed 3 contacts")
      )
    end

    it 'builds a correct phrase when the locale is different' do
      Gitlab::I18n.with_locale('pt-BR') do
        expect(build_note(1, 3)).to(
          eq("added 1 contact and removed 3 contacts")
        )
      end
    end
  end

  describe '#change_status' do
    subject { service.change_status(status, source) }

    let(:status) { 'reopened' }
    let(:source) { nil }

    it 'creates a resource state event' do
      expect { subject }.to change { ResourceStateEvent.count }.by(1)
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

    let(:mentioned_in) { create(:issue, project: project) }

    subject { service.cross_reference(mentioned_in) }

    it_behaves_like 'a system note' do
      let(:action) { 'cross_reference' }
    end

    context 'when cross-reference disallowed' do
      before do
        expect_next_instance_of(described_class) do |instance|
          expect(instance).to receive(:cross_reference_disallowed?).and_return(true)
        end
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
        expect_next_instance_of(described_class) do |instance|
          expect(instance).to receive(:cross_reference_disallowed?).and_return(false)
        end
      end

      it_behaves_like 'a system note' do
        let(:action) { 'cross_reference' }
      end

      it_behaves_like 'a note with overridable created_at'

      describe 'note_body' do
        context 'cross-project' do
          let(:project2) { create(:project, :repository) }
          let(:mentioned_in) { create(:issue, :task, project: project2) }

          context 'from Commit' do
            let(:mentioned_in) { project2.repository.commit }

            it 'references the mentioning commit' do
              expect(subject.note).to eq "mentioned in commit #{mentioned_in.to_reference(project)}"
            end
          end

          context 'from non-Commit' do
            it 'references the mentioning object' do
              expect(subject.note).to eq "mentioned in task #{mentioned_in.to_reference(project)}"
            end
          end
        end

        context 'within the same project' do
          context 'from Commit' do
            let(:mentioned_in) { project.repository.commit }

            it 'references the mentioning commit' do
              expect(subject.note).to eq "mentioned in commit #{mentioned_in.to_reference}"
            end
          end

          context 'from non-Commit' do
            it 'references the mentioning object' do
              expect(subject.note).to eq "mentioned in issue #{mentioned_in.to_reference}"
            end
          end
        end
      end

      describe 'note_date' do
        let(:mentioned_in) { project.repository.commit }

        it 'uses commit date with USE_COMMIT_DATE_FOR_CROSS_REFERENCE_NOTE' do
          stub_const("#{described_class}::USE_COMMIT_DATE_FOR_CROSS_REFERENCE_NOTE", true)

          note = service.cross_reference(mentioned_in)

          expect(note.created_at).to be_like_time(mentioned_in.created_at)
        end
      end

      context 'with external issue' do
        let(:noteable) { ExternalIssue.new('JIRA-123', project) }
        let(:mentioned_in) { project.commit }

        it 'queues a background worker' do
          expect(Integrations::CreateExternalCrossReferenceWorker).to receive(:perform_async).with(
            project.id,
            'JIRA-123',
            'Commit',
            mentioned_in.id,
            author.id
          )

          subject
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
          system_note.update!(note: system_note.note.capitalize)
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
          system_note.update!(note: system_note.note.capitalize)
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
          system_note.update!(note: system_note.note.capitalize)
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

    it "posts the 'marked the checklist item as complete' system note" do
      expect(subject.note).to eq("marked the checklist item **task** as completed")
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

  describe '#noteable_cloned' do
    let_it_be(:new_project) { create(:project) }
    let_it_be(:new_noteable) { create(:issue, project: new_project) }

    subject do
      service.noteable_cloned(new_noteable, direction)
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

    context 'cloned to' do
      let(:direction) { :to }

      it_behaves_like 'cross project mentionable'

      it_behaves_like 'a system note' do
        let(:action) { 'cloned' }
      end

      it 'notifies about noteable being cloned to' do
        expect(subject.note).to match('cloned to')
      end
    end

    context 'cloned from' do
      let(:direction) { :from }

      it_behaves_like 'cross project mentionable'

      it_behaves_like 'a system note' do
        let(:action) { 'cloned' }
      end

      it 'notifies about noteable being cloned from' do
        expect(subject.note).to match('cloned from')
      end
    end

    context 'invalid direction' do
      let(:direction) { :invalid }

      it 'raises error' do
        expect { subject }.to raise_error StandardError, /Invalid direction/
      end
    end

    context 'custom created timestamp' do
      let(:direction) { :from }

      it 'allows setting of custom created_at value' do
        timestamp = 1.day.ago

        note = service.noteable_cloned(new_noteable, direction, created_at: timestamp)

        expect(note.created_at).to be_like_time(timestamp)
      end

      it 'defaults to current time when created_at is not given', :freeze_time do
        expect(subject.created_at).to be_like_time(Time.current)
      end
    end

    context 'metrics', :clean_gitlab_redis_shared_state do
      context 'cloned from' do
        let(:direction) { :from }

        it 'does not track usage' do
          expect { subject }
            .to not_trigger_internal_events(Gitlab::UsageDataCounters::IssueActivityUniqueCounter::ISSUE_CLONED)
            .and not_increment_usage_metrics(
              'redis_hll_counters.issues_edit.g_project_management_issue_cloned_monthly',
              'redis_hll_counters.issues_edit.g_project_management_issue_cloned_weekly'
            )
        end
      end

      context 'cloned to' do
        let(:direction) { :to }

        it 'tracks internal events and increments usage metrics' do
          expect { subject }
            .to trigger_internal_events(Gitlab::UsageDataCounters::IssueActivityUniqueCounter::ISSUE_CLONED)
              .with(project: project, user: author, category: 'InternalEventTracking')
            .and increment_usage_metrics(
              'redis_hll_counters.issues_edit.g_project_management_issue_cloned_monthly',
              'redis_hll_counters.issues_edit.g_project_management_issue_cloned_weekly'
            ).by(1)
            .and increment_usage_metrics(
              # Cloner and original issue author are two unique users
              # --> Not great that we're tracking the original author as an active user...
              'redis_hll_counters.issues_edit.issues_edit_total_unique_counts_monthly',
              'redis_hll_counters.issues_edit.issues_edit_total_unique_counts_weekly'
            ).by(2)
        end
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

  describe '#email_participants' do
    let(:body) { "added user@example.com" }

    subject(:system_note) { service.email_participants(body) }

    it { expect(system_note.note).to eq(body) }
  end

  describe '#discussion_lock' do
    subject { service.discussion_lock }

    context 'discussion unlocked' do
      it_behaves_like 'a system note' do
        let(:action) { 'unlocked' }
      end

      it 'creates the note text correctly' do
        [:issue, :merge_request].each do |type|
          issuable = create(type) # rubocop:disable Rails/SaveBang

          service = described_class.new(noteable: issuable, author: author)
          expect(service.discussion_lock.note)
            .to eq("unlocked the discussion in this #{type.to_s.titleize.downcase}")
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
            .to eq("locked the discussion in this #{type.to_s.titleize.downcase}")
        end
      end
    end
  end

  describe '#cross_reference_disallowed?' do
    context 'when mentioned_in is not a MergeRequest' do
      it 'is falsey' do
        mentioned_in = noteable.dup

        expect(service.cross_reference_disallowed?(mentioned_in)).to be_falsey
      end
    end

    context 'when mentioned_in is a MergeRequest' do
      let(:mentioned_in) { create(:merge_request, :simple, source_project: project) }
      let(:noteable) { project.commit }

      it 'is truthy when noteable is in commits' do
        expect(mentioned_in).to receive(:commits).and_return([noteable])

        expect(service.cross_reference_disallowed?(mentioned_in)).to be_truthy
      end

      it 'is falsey when noteable is not in commits' do
        expect(mentioned_in).to receive(:commits).and_return([])

        expect(service.cross_reference_disallowed?(mentioned_in)).to be_falsey
      end
    end

    context 'when notable is an ExternalIssue' do
      let(:project) { create(:project) }
      let(:noteable) { ExternalIssue.new('EXT-1234', project) }

      it 'is false with issue tracker supporting referencing' do
        create(:jira_integration, project: project)
        project.reload

        expect(service.cross_reference_disallowed?(noteable)).to be_falsey
      end

      it 'is true with issue tracker not supporting referencing' do
        create(:bugzilla_integration, project: project)
        project.reload

        expect(service.cross_reference_disallowed?(noteable)).to be_truthy
      end

      it 'is true without issue tracker' do
        expect(service.cross_reference_disallowed?(noteable)).to be_truthy
      end
    end
  end

  describe '#close_after_error_tracking_resolve' do
    subject { service.close_after_error_tracking_resolve }

    it 'creates the expected state event' do
      subject

      event = ResourceStateEvent.last

      expect(event.close_after_error_tracking_resolve).to eq(true)
      expect(event.state).to eq('closed')
    end
  end

  describe '#auto_resolve_prometheus_alert' do
    subject { service.auto_resolve_prometheus_alert }

    it 'creates the expected state event' do
      subject

      event = ResourceStateEvent.last

      expect(event.close_auto_resolve_prometheus_alert).to eq(true)
      expect(event.state).to eq('closed')
    end
  end

  describe '#change_issue_type' do
    context 'with issue' do
      let_it_be_with_reload(:noteable) { create(:issue, project: project) }

      subject { service.change_issue_type('incident') }

      it_behaves_like 'a system note' do
        let(:action) { 'issue_type' }
      end

      it { expect(subject.note).to eq "changed type from incident to issue" }
    end

    context 'with work item' do
      let_it_be_with_reload(:noteable) { create(:work_item, project: project) }

      subject { service.change_issue_type('task') }

      it_behaves_like 'a system note' do
        let(:action) { 'issue_type' }
      end

      it { expect(subject.note).to eq "changed type from task to issue" }
    end
  end

  describe '#hierarchy_changed' do
    let_it_be_with_reload(:work_item) { create(:work_item, project: project) }
    let_it_be_with_reload(:task) { create(:work_item, :task, project: project) }

    let(:service) { described_class.new(noteable: work_item, container: project, author: author) }

    subject { service.hierarchy_changed(task, hierarchy_change_action) }

    context 'when task is added as a child' do
      let(:hierarchy_change_action) { 'relate' }

      it_behaves_like 'a system note' do
        let(:expected_noteable) { task }
        let(:action) { 'relate_to_parent' }
      end

      it 'sets the correct note text' do
        expect { subject }.to change { Note.system.count }.by(2)
        expect(work_item.notes.last.note).to eq("added ##{task.iid} as child task")
        expect(task.notes.last.note).to eq("added ##{work_item.iid} as parent issue")
      end

      context 'when the parent belongs to a different namespace' do
        let(:work_item) { create(:work_item, :group_level, namespace: group) }

        it 'uses full references on the system notes' do
          expect { subject }.to change { Note.system.count }.by(2)
          expect(work_item.notes.last.note).to eq("added #{task.namespace.full_path}##{task.iid} as child task")
          expect(task.notes.last.note).to eq("added #{work_item.namespace.full_path}##{work_item.iid} as parent issue")
        end
      end
    end

    context 'when child task is removed' do
      let(:hierarchy_change_action) { 'unrelate' }

      it_behaves_like 'a system note' do
        let(:expected_noteable) { task }
        let(:action) { 'unrelate_from_parent' }
      end

      it 'sets the correct note text' do
        expect { subject }.to change { Note.system.count }.by(2)
        expect(work_item.notes.last.note).to eq("removed child task ##{task.iid}")
        expect(task.notes.last.note).to eq("removed parent issue ##{work_item.iid}")
      end

      context 'when the parent belongs to a different namespace' do
        let(:work_item) { create(:work_item, :group_level, namespace: group) }

        it 'uses full references on the system notes' do
          expect { subject }.to change { Note.system.count }.by(2)
          expect(work_item.notes.last.note).to eq("removed child task #{task.namespace.full_path}##{task.iid}")
          expect(task.notes.last.note).to eq("removed parent issue #{work_item.namespace.full_path}##{work_item.iid}")
        end
      end
    end
  end
end
