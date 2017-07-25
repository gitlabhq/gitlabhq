require 'spec_helper'

describe SentNotification do
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
        let(:project) { create(:project) }
        let(:issue) { create(:issue, project: project) }
        let(:discussion_id) { create(:note, project: project, noteable: issue).discussion_id }
        subject { build(:sent_notification, project: project, noteable: issue, in_reply_to_discussion_id: discussion_id) }

        it "is valid" do
          expect(subject).to be_valid
        end
      end
    end
  end

  describe '.record' do
    let(:user) { create(:user) }
    let(:issue) { create(:issue) }

    it 'creates a new SentNotification' do
      expect { described_class.record(issue, user.id) }.to change { described_class.count }.by(1)
    end
  end

  describe '.record_note' do
    let(:user) { create(:user) }
    let(:note) { create(:diff_note_on_merge_request) }

    it 'creates a new SentNotification' do
      expect { described_class.record_note(note, user.id) }.to change { described_class.count }.by(1)
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

      it 'creates a comment on the issue' do
        new_note = subject.create_reply('Test')
        expect(new_note.in_reply_to?(note)).to be_truthy
        expect(new_note.discussion_id).not_to eq(note.discussion_id)
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

      it 'creates a comment on the merge request' do
        new_note = subject.create_reply('Test')
        expect(new_note.in_reply_to?(note)).to be_truthy
        expect(new_note.discussion_id).not_to eq(note.discussion_id)
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
      let(:project) { create(:project) }
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
