# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::MergeRequests::AcceptMergeRequestTool, feature_category: :mcp_server do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository, :public, maintainers: [user]) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project) }

  let(:arguments) { { project_id: project.id.to_s, merge_request_iid: merge_request.iid, sha: 'abc123' } }
  let(:tool) { described_class.new(current_user: user, params: arguments, version: '0.1.0') }

  describe 'versioning' do
    it 'targets the mergeRequestAccept mutation', :aggregate_failures do
      expect(tool.operation_name).to eq('mergeRequestAccept')
      expect(tool.graphql_operation).to include('mergeRequestAccept(input: $input)')
    end
  end

  describe '#build_variables' do
    it 'maps identification and passthrough params into the mutation input', :aggregate_failures do
      variables = tool.build_variables

      expect(variables[:input]).to eq(
        projectPath: project.full_path,
        iid: merge_request.iid.to_s,
        sha: 'abc123',
        squash: false
      )
    end

    context 'when squash is omitted on a squash-enabled merge request' do
      let(:merge_request) do
        create(:merge_request, source_project: project, source_branch: 'markdown', squash: true)
      end

      it 'passes the current squash setting through so the mutation default cannot flip it off' do
        expect(tool.build_variables[:input][:squash]).to be(true)
      end
    end

    context 'when squash is explicitly false' do
      let(:arguments) do
        { project_id: project.id.to_s, merge_request_iid: merge_request.iid, sha: 'abc123', squash: false }
      end

      it 'forwards the explicit value' do
        expect(tool.build_variables[:input][:squash]).to be(false)
      end
    end

    context 'with all optional params' do
      let(:arguments) do
        {
          project_id: project.id.to_s,
          merge_request_iid: merge_request.iid,
          sha: 'abc123',
          strategy: 'merge_when_checks_pass',
          squash: true,
          commit_message: 'Merge it',
          squash_commit_message: 'Squash it',
          should_remove_source_branch: true
        }
      end

      it 'upcases the strategy into the GraphQL enum and forwards the rest' do
        expect(tool.build_variables[:input]).to eq(
          projectPath: project.full_path,
          iid: merge_request.iid.to_s,
          sha: 'abc123',
          strategy: 'MERGE_WHEN_CHECKS_PASS',
          squash: true,
          commitMessage: 'Merge it',
          squashCommitMessage: 'Squash it',
          shouldRemoveSourceBranch: true
        )
      end
    end

    context 'with a merge request URL' do
      let(:arguments) { { url: ::Gitlab::UrlBuilder.build(merge_request), sha: 'abc123' } }

      it 'resolves the merge request from the URL' do
        expect(tool.build_variables[:input][:iid]).to eq(merge_request.iid.to_s)
      end
    end

    context 'with both url and project identification' do
      let_it_be(:other_merge_request) do
        create(:merge_request, source_project: project, source_branch: 'markdown')
      end

      let(:arguments) do
        { url: ::Gitlab::UrlBuilder.build(merge_request), project_id: project.id.to_s,
          merge_request_iid: other_merge_request.iid, sha: 'abc123' }
      end

      it 'resolves through the url' do
        expect(tool.build_variables[:input][:iid]).to eq(merge_request.iid.to_s)
      end
    end
  end
end
