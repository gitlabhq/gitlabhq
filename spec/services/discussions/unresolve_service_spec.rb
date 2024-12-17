# frozen_string_literal: true

require "spec_helper"

RSpec.describe Discussions::UnresolveService, feature_category: :code_review_workflow do
  describe "#execute" do
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:user) { create(:user, developer_of: project) }
    let_it_be(:merge_request) { create(:merge_request, :merge_when_checks_pass, source_project: project) }

    let(:discussion) { create(:diff_note_on_merge_request, noteable: merge_request, project: project).to_discussion }

    let(:service) { described_class.new(discussion, user) }

    before do
      project.add_developer(user)
      discussion.resolve!(user)
    end

    it "unresolves the discussion" do
      service.execute

      expect(discussion).not_to be_resolved
    end

    it "counts the unresolve event" do
      expect(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter)
        .to receive(:track_unresolve_thread_action).with(user: user)

      service.execute
    end

    it "sends GraphQL triggers" do
      expect(GraphqlTriggers).to receive(:merge_request_merge_status_updated).with(discussion.noteable)

      service.execute
    end

    context "when there are existing unresolved discussions" do
      before do
        create(:diff_note_on_merge_request, noteable: merge_request, project: project).to_discussion
      end

      it "does not send a GraphQL triggers" do
        expect(GraphqlTriggers).not_to receive(:merge_request_merge_status_updated)

        service.execute
      end
    end

    context "when the noteable is not a merge request" do
      it "does not send a GraphQL triggers" do
        expect(discussion).to receive(:for_merge_request?).and_return(false)
        expect(GraphqlTriggers).not_to receive(:merge_request_merge_status_updated)

        service.execute
      end
    end
  end
end
