# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Notes::ResolveService, feature_category: :team_planning do
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

    context "when noteable is not a MergeRequest" do
      let(:note) { create(:note_on_issue, project: merge_request.project) }

      it "sends notifications if all discussions are resolved" do
        expect(MergeRequests::ResolvedDiscussionNotificationService)
          .not_to receive(:new)

        described_class.new(merge_request.project, user).execute(note)
      end
    end

    context "when noteable is a MergeRequest" do
      it "sends notifications if all discussions are resolved" do
        expect_next_instance_of(MergeRequests::ResolvedDiscussionNotificationService) do |instance|
          expect(instance).to receive(:execute).with(merge_request)
        end

        described_class.new(merge_request.project, user).execute(note)
      end
    end
  end
end
