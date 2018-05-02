require 'spec_helper'

describe Notes::ResolveService do
  let(:merge_request) { create(:merge_request) }
  let(:note) { create(:diff_note_on_merge_request, noteable: merge_request, project: merge_request.project) }
  let(:user) { merge_request.author }

  describe '#execute' do
    it "resolves the note" do
      described_class.new(merge_request.project, user).execute(note)
      note.reload

      expect(note.resolved?).to be true
      expect(note.resolved_by).to eq(user)
    end

    it "sends notifications if all discussions are resolved" do
      expect_any_instance_of(MergeRequests::ResolvedDiscussionNotificationService).to receive(:execute).with(merge_request)

      described_class.new(merge_request.project, user).execute(note)
    end
  end
end
