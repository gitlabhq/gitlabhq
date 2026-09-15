# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::MergeRequests::AcceptMergeRequestService, feature_category: :mcp_server do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository, :public, maintainers: [user]) }

  let(:merge_request) { create(:merge_request, source_project: project) }
  let(:service) { described_class.new(name: 'accept_merge_request') }
  let(:request) { instance_double(ActionDispatch::Request) }
  let(:identification) { { project_id: project.id.to_s, merge_request_iid: merge_request.iid } }

  before do
    service.set_cred(current_user: user)
  end

  describe 'class configuration' do
    it 'registers version 0.1.0' do
      expect(described_class.available_versions).to include('0.1.0')
    end

    it 'is a write, destructive tool', :aggregate_failures do
      expect(service.annotations[:readOnlyHint]).to be(false)
      expect(service.annotations[:destructiveHint]).to be(true)
    end
  end

  describe 'input schema' do
    it 'locks the full input schema for version 0.1.0' do
      expect(described_class.version_metadata('0.1.0')[:input_schema]).to eq({
        type: 'object',
        properties: {
          url: {
            type: 'string',
            description: 'GitLab URL of the merge request. Provide this, or project_id and merge_request_iid.'
          },
          project_id: {
            type: 'string',
            description: 'ID or path of the project. Required if url is not provided.'
          },
          merge_request_iid: {
            type: 'integer',
            description: 'Internal ID of the merge request. Required if url is not provided.'
          },
          sha: {
            type: 'string',
            description: 'Head SHA guard. When it no longer matches the merge request head, the ' \
              'merge is refused instead of merging content you have not seen. Pass the ' \
              'diff_head_sha returned by get_merge_request.'
          },
          strategy: {
            type: 'string',
            enum: ::AutoMergeService.all_strategies_ordered_by_preference,
            description: 'Auto-merge strategy. When given, arms auto-merge instead of merging ' \
              'immediately.'
          },
          squash: {
            type: 'boolean',
            description: 'Squash the commits into a single commit on merge.'
          },
          commit_message: {
            type: 'string',
            description: 'Custom merge commit message.'
          },
          squash_commit_message: {
            type: 'string',
            description: 'Custom squash commit message. Applies when squash is true.'
          },
          should_remove_source_branch: {
            type: 'boolean',
            description: 'Remove the source branch after merging.'
          }
        },
        required: %w[sha]
      })
    end

    it 'always offers the CE auto-merge strategy' do
      enum = described_class.version_metadata('0.1.0')[:input_schema][:properties][:strategy][:enum]

      expect(enum).to include('merge_when_checks_pass')
    end
  end

  describe '#execute' do
    context 'when merging immediately' do
      let(:params) { { arguments: identification.merge(sha: merge_request.diff_head_sha) } }

      it 'schedules the merge and reports the async status', :aggregate_failures do
        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be(false)
        expect(result[:structuredContent]['status']).to eq('merging')
        expect(result[:structuredContent]['merge_request_url']).to include(merge_request.iid.to_s)
        expect(merge_request.reload.merge_jid).to be_present
      end
    end

    context 'when the merge request is already merged' do
      let(:merge_request) { create(:merge_request, :merged, source_project: project, source_branch: 'markdown') }
      let(:params) { { arguments: identification.merge(sha: 'irrelevant') } }

      it 'succeeds idempotently without invoking the mutation', :aggregate_failures do
        expect(GitlabSchema).not_to receive(:execute)

        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be(false)
        expect(result[:structuredContent]['status']).to eq('already_merged')
      end
    end

    context 'when the sha does not match the merge request head' do
      let(:params) { { arguments: identification.merge(sha: 'deadbeef') } }

      it 'refuses the merge', :aggregate_failures do
        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('The merge-head is not at the anticipated SHA')
        expect(merge_request.reload.merge_jid).to be_nil
      end
    end

    context 'when the merge request is a draft' do
      let(:merge_request) { create(:merge_request, source_project: project, title: 'Draft: not ready') }
      let(:params) { { arguments: identification.merge(sha: merge_request.diff_head_sha) } }

      it 'passes the not-mergeable error through', :aggregate_failures do
        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('This branch cannot be merged')
      end
    end

    context 'when a strategy is requested but auto-merge is not available' do
      let(:params) do
        { arguments: identification.merge(sha: merge_request.diff_head_sha, strategy: 'merge_when_checks_pass') }
      end

      it 'enriches the generic merge-failed error', :aggregate_failures do
        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('The merge failed')
        expect(result[:content].first[:text]).to include('Omit strategy to merge immediately.')
      end
    end

    context 'when a strategy is requested and auto-merge arms' do
      let(:params) do
        { arguments: identification.merge(sha: merge_request.diff_head_sha, strategy: 'merge_when_checks_pass') }
      end

      before do
        pipeline = create(:ci_pipeline, :running, project: project,
          sha: merge_request.diff_head_sha, ref: merge_request.source_branch)
        merge_request.update!(head_pipeline: pipeline)
      end

      it 'arms auto-merge and reports the scheduled status', :aggregate_failures do
        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be(false)
        expect(result[:structuredContent]['status']).to eq('auto_merge_scheduled')
        expect(result[:structuredContent]['auto_merge_strategy']).to eq('merge_when_checks_pass')
        expect(merge_request.reset.auto_merge_enabled).to be(true)
      end
    end

    context 'when auto-merge is already scheduled' do
      before do
        merge_request.update!(auto_merge_enabled: true, merge_user: user,
          auto_merge_strategy: ::AutoMergeService::STRATEGY_MERGE_WHEN_CHECKS_PASS)
      end

      context 'and a strategy is requested' do
        let(:params) do
          { arguments: identification.merge(sha: merge_request.diff_head_sha, strategy: 'merge_when_checks_pass') }
        end

        it 'succeeds idempotently', :aggregate_failures do
          result = service.execute(request: request, params: params)

          expect(result[:isError]).to be(false)
          expect(result[:structuredContent]['status']).to eq('already_scheduled')
          expect(result[:structuredContent]['auto_merge_strategy']).to eq('merge_when_checks_pass')
        end

        context 'and the sha is stale' do
          let(:params) do
            { arguments: identification.merge(sha: 'deadbeef', strategy: 'merge_when_checks_pass') }
          end

          it 'refuses instead of reading as a confirmed auto-merge', :aggregate_failures do
            result = service.execute(request: request, params: params)

            expect(result[:isError]).to be(true)
            expect(result[:content].first[:text]).to include('head no longer matches the provided sha')
          end
        end
      end

      context 'and an immediate merge is requested' do
        let(:params) { { arguments: identification.merge(sha: merge_request.diff_head_sha) } }

        it 'reports the conflict between the armed auto-merge and the immediate request', :aggregate_failures do
          result = service.execute(request: request, params: params)

          expect(result[:isError]).to be(true)
          expect(result[:content].first[:text]).to include('already scheduled to be merged')
        end
      end
    end

    context 'when the user cannot merge' do
      let(:params) { { arguments: identification.merge(sha: merge_request.diff_head_sha) } }

      before do
        service.set_cred(current_user: create(:user))
      end

      it 'returns the authorization error', :aggregate_failures do
        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include("does not exist or you don't have permission")
      end
    end

    context 'without identification' do
      let(:params) { { arguments: { sha: 'abc123' } } }

      it 'rejects the call', :aggregate_failures do
        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('Provide either url, or project_id and merge_request_iid')
      end
    end

    context 'without sha' do
      let(:params) { { arguments: identification } }

      it 'fails schema validation' do
        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be(true)
      end
    end

    context 'when current_user is not set' do
      let(:params) { { arguments: identification.merge(sha: 'abc123') } }

      before do
        service.set_cred(current_user: nil)
      end

      it 'returns an error' do
        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('current_user is not set')
      end
    end
  end
end
