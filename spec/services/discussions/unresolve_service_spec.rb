# frozen_string_literal: true

require "spec_helper"

RSpec.describe Discussions::UnresolveService do
  describe "#execute" do
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:user) { create(:user, developer_projects: [project]) }
    let_it_be(:merge_request) { create(:merge_request, :merge_when_pipeline_succeeds, source_project: project) }

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
  end
end
