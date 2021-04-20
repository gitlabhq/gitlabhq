# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SentNotification do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }

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

  shared_examples 'a successful sent notification' do
    it 'creates a new SentNotification' do
      expect { subject }.to change { described_class.count }.by(1)
    end
  end

  describe '.record' do
    let(:issue) { create(:issue) }

    subject { described_class.record(issue, user.id) }

    it_behaves_like 'a successful sent notification'
  end

  describe '.record_note' do
    subject { described_class.record_note(note, note.author.id) }

    context 'for a discussion note' do
      let(:note) { create(:diff_note_on_merge_request) }

      it_behaves_like 'a successful sent notification'

      it 'sets in_reply_to_discussion_id' do
        expect(subject.in_reply_to_discussion_id).to eq(note.discussion_id)
      end
    end

    context 'for an individual note' do
      let(:note) { create(:note_on_merge_request) }

      it_behaves_like 'a successful sent notification'

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

    it_behaves_like 'a non-unsubscribable notification', 'personal snippet' do
      let(:noteable) { create(:personal_snippet, project: project) }
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

    it_behaves_like 'a non-commit notification', 'personal snippet' do
      let(:noteable) { create(:personal_snippet, project: project) }
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

    it_behaves_like 'a snippet notification', 'personal snippet' do
      let(:noteable) { create(:personal_snippet, project: project) }
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

  describe "#position=" do
    subject { build(:sent_notification, noteable: create(:issue)) }

    it "doesn't accept non-hash JSON passed as a string" do
      subject.position = "true"

      expect(subject.attributes_before_type_cast["position"]).to be(nil)
    end

    it "does accept a position hash as a string" do
      subject.position = '{ "base_sha": "test" }'

      expect(subject.position.base_sha).to eq("test")
    end

    it "does accept a hash" do
      subject.position = { "base_sha" => "test" }

      expect(subject.position.base_sha).to eq("test")
    end
  end
end
