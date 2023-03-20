# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::AddContextService, feature_category: :code_review_workflow do
  let(:project) { create(:project, :repository) }
  let(:admin) { create(:admin) }
  let(:merge_request) { create(:merge_request, source_project: project, target_project: project, author: admin) }
  let(:commits) { ["874797c3a73b60d2187ed6e2fcabd289ff75171e"] }
  let(:raw_repository) { project.repository.raw }

  subject(:service) { described_class.new(project: project, current_user: admin, params: { merge_request: merge_request, commits: commits }) }

  describe "#execute" do
    context "when admin mode is enabled", :enable_admin_mode do
      it "adds context commit" do
        service.execute

        expect(merge_request.merge_request_context_commit_diff_files.length).to eq(2)
      end
    end

    context "when admin mode is disabled" do
      it "doesn't add context commit" do
        subject.execute

        expect(merge_request.merge_request_context_commit_diff_files.length).to eq(0)
      end
    end

    context "when user doesn't have permission to update merge request" do
      let(:user) { create(:user) }
      let(:merge_request1) { create(:merge_request, source_project: project, author: user) }

      subject(:service) { described_class.new(project: project, current_user: user, params: { merge_request: merge_request, commits: commits }) }

      it "doesn't add context commit" do
        subject.execute

        expect(merge_request.merge_request_context_commit_diff_files.length).to eq(0)
      end
    end

    context "when the commits array is empty" do
      subject(:service) { described_class.new(project: project, current_user: admin, params: { merge_request: merge_request, commits: [] }) }

      it "doesn't add context commit" do
        subject.execute

        expect(merge_request.merge_request_context_commit_diff_files.length).to eq(0)
      end
    end
  end
end
