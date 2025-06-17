# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SentNotification, :request_store, feature_category: :shared do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :repository, group: group) }

  describe 'validation' do
    describe 'note validity' do
      context "when the project doesn't match the noteable's project" do
        subject { build(:sent_notification, noteable: create(:issue)) }

        it "is invalid" do
          expect(subject).not_to be_valid
        end
      end

      context "when the project doesn't match the discussion project" do
        let(:discussion_id) { create(:note).discussion_id }

        subject { build(:sent_notification, in_reply_to_discussion_id: discussion_id) }

        it "is invalid" do
          expect(subject).not_to be_valid
        end
      end

      context "when the noteable project and discussion project match" do
        let(:project) { create(:project, :repository) }
        let(:issue) { create(:issue, project: project) }
        let(:discussion_id) { create(:note, project: project, noteable: issue).discussion_id }

        subject { build(:sent_notification, project: project, noteable: issue, in_reply_to_discussion_id: discussion_id) }

        it "is valid" do
          expect(subject).to be_valid
        end
      end
    end
  end

  describe ' associations' do
    subject { build(:sent_notification) }

    it { is_expected.to belong_to(:issue_email_participant) }
  end

  describe 'callbacks' do
    describe '#ensure_sharding_key' do
      let(:additional_args) { {} }

      subject(:notification_namespace_id) do
        record = described_class.new(noteable: noteable, **additional_args)
        record.valid?

        record.namespace_id
      end

      context 'when noteable is a DesignManagement::Design' do
        let(:noteable) { create(:design, issue: create(:issue, project: project)).reload }

        # Using project.namespace_id here instead of project.project_namespace_id as that's the value the trigger
        # sets for design_management_designs records in the DB. That shouls also be a valid sharding key.
        it { is_expected.to eq(project.namespace_id) }
      end

      context 'when noteable is a Issue' do
        let(:noteable) { create(:issue, project: project) }

        it { is_expected.to eq(noteable.namespace_id) }
      end

      context 'when noteable is a MergeRequest' do
        let(:noteable) { create(:merge_request, source_project: project) }

        it { is_expected.to eq(project.project_namespace_id) }
      end

      context 'when noteable is a ProjectSnippet' do
        let(:noteable) { create(:project_snippet, project: project) }

        it { is_expected.to eq(project.project_namespace_id) }
      end

      context 'when noteable is a Commit' do
        let(:commit) { create(:commit, project: project) }
        let(:noteable) { nil }
        let(:additional_args) { { project: project, noteable_type: commit.class.name, commit_id: commit.id } }

        it { is_expected.to eq(project.project_namespace_id) }
      end

      context 'when noteable type is not supported' do
        let(:noteable) { create(:personal_snippet) }

        it 'raises an error' do
          expect do
            notification_namespace_id
          end.to raise_error(SentNotification::INVALID_NOTEABLE)
        end
      end
    end
  end

  shared_examples 'a successful sent notification' do
    it 'creates a new SentNotification' do
      expect { subject }.to change { described_class.count }.by(1)
    end
  end

  shared_examples 'a non-sticky write' do
    it 'writes without sticking to primary' do
      subject

      Gitlab::Database::LoadBalancing.each_load_balancer do |lb|
        expect(Gitlab::Database::LoadBalancing::SessionMap.current(lb).use_primary?).to be false
      end
    end
  end

  describe '.record' do
    let_it_be(:issue) { create(:issue) }

    subject { described_class.record(issue, user.id) }

    it_behaves_like 'a successful sent notification'
    it_behaves_like 'a non-sticky write'

    context 'with issue email participant' do
      let!(:issue_email_participant) { create(:issue_email_participant, issue: issue) }

      subject(:sent_notification) do
        described_class.record(issue, user.id, described_class.reply_key, {
          issue_email_participant: issue_email_participant
        })
      end

      it 'saves the issue_email_participant' do
        expect(sent_notification.issue_email_participant).to eq(issue_email_participant)
      end
    end
  end

  describe '.record_note' do
    subject { described_class.record_note(note, note.author.id) }

    context 'for a discussion note' do
      let_it_be(:note) { create(:diff_note_on_merge_request) }

      it_behaves_like 'a successful sent notification'
      it_behaves_like 'a non-sticky write'

      it 'sets in_reply_to_discussion_id' do
        expect(subject.in_reply_to_discussion_id).to eq(note.discussion_id)
      end
    end

    context 'for an individual note' do
      let_it_be(:note) { create(:note_on_merge_request) }

      it_behaves_like 'a successful sent notification'
      it_behaves_like 'a non-sticky write'

      it 'sets in_reply_to_discussion_id' do
        expect(subject.in_reply_to_discussion_id).to eq(note.discussion_id)
      end
    end
  end

  describe '#unsubscribable?' do
    shared_examples 'an unsubscribable notification' do |noteable_type|
      subject { described_class.record(noteable, user.id) }

      context "for #{noteable_type}" do
        it { expect(subject).to be_unsubscribable }
      end
    end

    shared_examples 'a non-unsubscribable notification' do |noteable_type|
      subject { described_class.record(noteable, user.id) }

      context "for a #{noteable_type}" do
        it { expect(subject).not_to be_unsubscribable }
      end
    end

    it_behaves_like 'an unsubscribable notification', 'issue' do
      let(:noteable) { create(:issue, project: project) }
    end

    it_behaves_like 'an unsubscribable notification', 'merge request' do
      let(:noteable) { create(:merge_request, source_project: project) }
    end

    it_behaves_like 'a non-unsubscribable notification', 'commit' do
      let(:project) { create(:project, :repository) }
      let(:noteable) { project.commit }
    end

    it_behaves_like 'a non-unsubscribable notification', 'project snippet' do
      let(:noteable) { create(:project_snippet, project: project) }
    end
  end

  describe '#for_commit?' do
    shared_examples 'a commit notification' do |noteable_type|
      subject { described_class.record(noteable, user.id) }

      context "for #{noteable_type}" do
        it { expect(subject).to be_for_commit }
      end
    end

    shared_examples 'a non-commit notification' do |noteable_type|
      subject { described_class.record(noteable, user.id) }

      context "for a #{noteable_type}" do
        it { expect(subject).not_to be_for_commit }
      end
    end

    it_behaves_like 'a non-commit notification', 'issue' do
      let(:noteable) { create(:issue, project: project) }
    end

    it_behaves_like 'a non-commit notification', 'merge request' do
      let(:noteable) { create(:merge_request, source_project: project) }
    end

    it_behaves_like 'a commit notification', 'commit' do
      let(:project) { create(:project, :repository) }
      let(:noteable) { project.commit }
    end

    it_behaves_like 'a non-commit notification', 'project snippet' do
      let(:noteable) { create(:project_snippet, project: project) }
    end
  end

  describe '#for_snippet?' do
    shared_examples 'a snippet notification' do |noteable_type|
      subject { described_class.record(noteable, user.id) }

      context "for #{noteable_type}" do
        it { expect(subject).to be_for_snippet }
      end
    end

    shared_examples 'a non-snippet notification' do |noteable_type|
      subject { described_class.record(noteable, user.id) }

      context "for a #{noteable_type}" do
        it { expect(subject).not_to be_for_snippet }
      end
    end

    it_behaves_like 'a non-snippet notification', 'issue' do
      let(:noteable) { create(:issue, project: project) }
    end

    it_behaves_like 'a non-snippet notification', 'merge request' do
      let(:noteable) { create(:merge_request, source_project: project) }
    end

    it_behaves_like 'a non-snippet notification', 'commit' do
      let(:project) { create(:project, :repository) }
      let(:noteable) { project.commit }
    end

    it_behaves_like 'a snippet notification', 'project snippet' do
      let(:noteable) { create(:project_snippet, project: project) }
    end
  end

  describe '#create_reply' do
    context 'for issue' do
      let(:issue) { create(:issue) }

      subject { described_class.record(issue, issue.author.id) }

      it 'creates a comment on the issue' do
        note = subject.create_reply('Test')
        expect(note.in_reply_to?(issue)).to be_truthy
      end
    end

    context 'for issue comment' do
      let(:note) { create(:note_on_issue) }

      subject { described_class.record_note(note, note.author.id) }

      it 'converts the comment to a discussion on the issue' do
        new_note = subject.create_reply('Test')
        expect(new_note.in_reply_to?(note)).to be_truthy
        expect(new_note.discussion_id).to eq(note.discussion_id)
      end
    end

    context 'for issue discussion' do
      let(:note) { create(:discussion_note_on_issue) }

      subject { described_class.record_note(note, note.author.id) }

      it 'creates a reply on the discussion' do
        new_note = subject.create_reply('Test')
        expect(new_note.in_reply_to?(note)).to be_truthy
        expect(new_note.discussion_id).to eq(note.discussion_id)
      end
    end

    context 'for merge request' do
      let(:merge_request) { create(:merge_request) }

      subject { described_class.record(merge_request, merge_request.author.id) }

      it 'creates a comment on the merge_request' do
        note = subject.create_reply('Test')
        expect(note.in_reply_to?(merge_request)).to be_truthy
      end
    end

    context 'for merge request comment' do
      let(:note) { create(:note_on_merge_request) }

      subject { described_class.record_note(note, note.author.id) }

      it 'converts the comment to a discussion on the merge request' do
        new_note = subject.create_reply('Test')
        expect(new_note.in_reply_to?(note)).to be_truthy
        expect(new_note.discussion_id).to eq(note.discussion_id)
      end
    end

    context 'for merge request diff discussion' do
      let(:note) { create(:diff_note_on_merge_request) }

      subject { described_class.record_note(note, note.author.id) }

      it 'creates a reply on the discussion' do
        new_note = subject.create_reply('Test')
        expect(new_note.in_reply_to?(note)).to be_truthy
        expect(new_note.discussion_id).to eq(note.discussion_id)
      end
    end

    context 'for merge request non-diff discussion' do
      let(:note) { create(:discussion_note_on_merge_request) }

      subject { described_class.record_note(note, note.author.id) }

      it 'creates a reply on the discussion' do
        new_note = subject.create_reply('Test')
        expect(new_note.in_reply_to?(note)).to be_truthy
        expect(new_note.discussion_id).to eq(note.discussion_id)
      end
    end

    context 'for commit' do
      let(:project) { create(:project, :repository) }
      let(:commit) { project.commit }

      subject { described_class.record(commit, project.creator.id) }

      it 'creates a comment on the commit' do
        note = subject.create_reply('Test')
        expect(note.in_reply_to?(commit)).to be_truthy
      end
    end

    context 'for commit comment' do
      let(:note) { create(:note_on_commit) }

      subject { described_class.record_note(note, note.author.id) }

      it 'creates a comment on the commit' do
        new_note = subject.create_reply('Test')
        expect(new_note.in_reply_to?(note)).to be_truthy
        expect(new_note.discussion_id).not_to eq(note.discussion_id)
      end
    end

    context 'for commit diff discussion' do
      let(:note) { create(:diff_note_on_commit) }

      subject { described_class.record_note(note, note.author.id) }

      it 'creates a reply on the discussion' do
        new_note = subject.create_reply('Test')
        expect(new_note.in_reply_to?(note)).to be_truthy
        expect(new_note.discussion_id).to eq(note.discussion_id)
      end
    end

    context 'for commit non-diff discussion' do
      let(:note) { create(:discussion_note_on_commit) }

      subject { described_class.record_note(note, note.author.id) }

      it 'creates a reply on the discussion' do
        new_note = subject.create_reply('Test')
        expect(new_note.in_reply_to?(note)).to be_truthy
        expect(new_note.discussion_id).to eq(note.discussion_id)
      end
    end
  end
end
