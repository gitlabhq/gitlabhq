# frozen_string_literal: true

require "spec_helper"

RSpec.describe Issuable::CreateReminderWorker, feature_category: :code_review_workflow do
  let_it_be(:user) { create(:user) }
  let_it_be(:merge_request) { create(:merge_request, author: user) }
  let(:job_args) { [merge_request.id, "MergeRequest", user.id] }
  let(:service) { double }

  subject(:worker_perform) { described_class.new.perform(*job_args) }

  include_examples "an idempotent worker"

  describe "#perform" do
    context "when the user does not exist" do
      before do
        allow(User).to receive(:find).at_least(:once).with(user.id).and_return(nil)
      end

      it "does not call TodoService#mark_todo" do
        expect(TodoService).not_to receive(:new)

        worker_perform
      end
    end

    context "when the merge request does not exist" do
      before do
        allow(MergeRequest).to receive(:find).at_least(:once).with(merge_request.id).and_return(nil)
      end

      it "does not call TodoService#mark_todo" do
        expect(TodoService).not_to receive(:new)

        worker_perform
      end
    end

    context "when MR and user exist" do
      it "creates a new instance of TodoService" do
        expect(TodoService).to receive(:new).at_least(:once).and_call_original

        worker_perform
      end

      it "calls TodoService#mark_todo" do
        expect(TodoService).to receive(:new).at_least(:once).and_return(service)
        expect(service).to receive(:mark_todo).at_least(:once)

        worker_perform
      end
    end
  end
end
