# frozen_string_literal: true

require 'spec_helper'

describe MergeRequests::ResolvedDiscussionNotificationService do
  let(:merge_request) { create(:merge_request) }
  let(:user) { create(:user) }
  let(:project) { merge_request.project }

  subject { described_class.new(project, user) }

  describe "#execute" do
    context "when not all discussions are resolved" do
      before do
        allow(merge_request).to receive(:discussions_resolved?).and_return(false)
      end

      it "doesn't add a system note" do
        expect(SystemNoteService).not_to receive(:resolve_all_discussions)

        subject.execute(merge_request)
      end

      it "doesn't send a notification email" do
        expect_any_instance_of(NotificationService).not_to receive(:resolve_all_discussions)

        subject.execute(merge_request)
      end
    end

    context "when all discussions are resolved" do
      before do
        allow(merge_request).to receive(:discussions_resolved?).and_return(true)
      end

      it "adds a system note" do
        expect(SystemNoteService).to receive(:resolve_all_discussions).with(merge_request, project, user)

        subject.execute(merge_request)
      end

      it "sends a notification email", :sidekiq_might_not_need_inline do
        expect_any_instance_of(NotificationService).to receive(:resolve_all_discussions).with(merge_request, user)

        subject.execute(merge_request)
      end
    end
  end
end
