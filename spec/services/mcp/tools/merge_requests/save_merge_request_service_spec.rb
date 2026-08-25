# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::MergeRequests::SaveMergeRequestService, feature_category: :mcp_server do
  let(:create_tool) { instance_double(Mcp::Tools::Base::ApiTool, name: :create_merge_request) }
  let(:update_tool) { instance_double(Mcp::Tools::Base::ApiTool, name: :update_merge_request) }
  let(:tools) { [create_tool, update_tool] }
  let(:service) { described_class.new(tools: tools) }

  describe '.tool_name' do
    it 'returns the aggregated tool name' do
      expect(described_class.tool_name).to eq('save_merge_request')
    end
  end

  describe '.tool_aliases' do
    it 'preserves the folded create and update tool names' do
      expect(described_class.tool_aliases).to contain_exactly('create_merge_request', 'update_merge_request')
    end
  end

  describe '#annotations' do
    it 'is a non-destructive write tool' do
      expect(service.annotations).to eq({ readOnlyHint: false, destructiveHint: false })
    end
  end

  describe '#input_schema' do
    it 'matches the advertised contract' do
      expect(service.input_schema).to eq(
        {
          type: 'object',
          properties: {
            project_id: {
              type: 'string',
              description: 'ID or full path of the project.'
            },
            merge_request_iid: {
              type: 'integer',
              description: 'Internal ID of the merge request. Provide to update an existing ' \
                'merge request; omit to create a new one.'
            },
            title: {
              type: 'string',
              description: 'Title of the merge request. Required when creating.'
            },
            description: {
              type: 'string',
              description: 'Description of the merge request.'
            },
            source_branch: {
              type: 'string',
              description: 'Source branch. Required when creating.'
            },
            target_branch: {
              type: 'string',
              description: 'Target branch. Required when creating.'
            },
            target_project_id: {
              type: 'integer',
              description: 'Target project ID. Defaults to the source project. Applies when creating.'
            },
            labels: {
              type: 'array',
              items: { type: 'string' },
              description: 'Label names. Replaces all existing labels.'
            },
            add_labels: {
              type: 'array',
              items: { type: 'string' },
              description: 'Label names to add. Applies when updating.'
            },
            remove_labels: {
              type: 'array',
              items: { type: 'string' },
              description: 'Label names to remove. Applies when updating.'
            },
            assignees: {
              type: 'array',
              items: { type: 'string' },
              description: 'Usernames to assign. Alternative to assignee_ids; provide one. ' \
                'Pass an empty array to remove all assignees.'
            },
            assignee_ids: {
              type: 'array',
              items: { type: 'integer' },
              description: 'User IDs to assign. Alternative to assignees; provide one.'
            },
            reviewers: {
              type: 'array',
              items: { type: 'string' },
              description: 'Usernames to request review from. Alternative to reviewer_ids; provide one. ' \
                'Pass an empty array to remove all reviewers.'
            },
            reviewer_ids: {
              type: 'array',
              items: { type: 'integer' },
              description: 'User IDs to request review from. Alternative to reviewers; provide one.'
            },
            milestone_id: {
              type: 'integer',
              description: 'Milestone ID to assign.'
            },
            milestone: {
              type: 'string',
              description: 'Title of a project or ancestor-group milestone to assign. ' \
                'Mutually exclusive with milestone_id.'
            },
            remove_source_branch: {
              type: 'boolean',
              description: 'Remove the source branch when the merge request is merged.'
            },
            squash: {
              type: 'boolean',
              description: 'Squash commits into a single commit when merging.'
            },
            state_event: {
              type: 'string',
              enum: %w[close reopen],
              description: 'State transition to perform. Applies when updating.'
            },
            discussion_locked: {
              type: 'boolean',
              description: 'Lock the merge request discussion. Applies when updating.'
            },
            allow_collaboration: {
              type: 'boolean',
              description: 'Allow commits from members who can merge to the target branch. Applies when updating.'
            }
          },
          required: ['project_id'],
          additionalProperties: false
        }
      )
    end

    it 'advertises only properties that reach a route allowlist after transforms' do
      route_params = (
        ::API::Helpers::MergeRequestsHelpers.create_merge_request_mcp_params +
        ::API::Helpers::MergeRequestsHelpers.update_merge_request_mcp_params
      ).uniq

      forwarded = service.input_schema[:properties].keys.map do |key|
        described_class::FORWARDED_KEY.fetch(key, key)
      end

      expect(forwarded - route_params).to be_empty
    end
  end

  describe '#execute' do
    let(:request) { nil }
    let(:params) { { arguments: arguments } }
    let(:mock_response) do
      {
        content: [{ type: 'text', text: '{"iid":1,"state":"opened"}' }],
        structuredContent: { iid: 1, state: 'opened' },
        isError: false
      }
    end

    context 'when merge_request_iid is absent' do
      let(:arguments) do
        { project_id: 'group/project', title: 'Add feature', source_branch: 'feature', target_branch: 'master' }
      end

      it 'routes to the create tool and tags the response as a create', :aggregate_failures do
        expect(create_tool).to receive(:execute).with(request: request, params: params).and_return(mock_response)

        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be false
        expect(result[:structuredContent][:_meta]).to eq({
          operation: 'create',
          tool: 'create_merge_request',
          aggregator: 'save_merge_request'
        })
        expect(result[:content].first[:text]).to include('Merge request created successfully via save_merge_request')
      end

      it 'passes project_id to the REST route as id', :aggregate_failures do
        allow(create_tool).to receive(:execute).and_return(mock_response)

        service.execute(request: request, params: params)

        expect(params[:arguments]).to include(id: 'group/project')
        expect(params[:arguments]).not_to have_key(:project_id)
      end
    end

    context 'when merge_request_iid is present' do
      let(:arguments) { { project_id: 'group/project', merge_request_iid: 42, title: 'Updated title' } }

      it 'routes to the update tool and tags the response as an update', :aggregate_failures do
        expect(update_tool).to receive(:execute).with(request: request, params: params).and_return(mock_response)

        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be false
        expect(result[:structuredContent][:_meta]).to eq({
          operation: 'update',
          tool: 'update_merge_request',
          aggregator: 'save_merge_request'
        })
        expect(result[:content].first[:text]).to include('Merge request updated successfully via save_merge_request')
      end
    end

    context 'with assignees and reviewers as usernames' do
      let_it_be(:alice) { create(:user) }
      let_it_be(:bob) { create(:user) }

      let(:arguments) do
        { project_id: 'group/project', merge_request_iid: 7, assignees: [alice.username], reviewers: [bob.username] }
      end

      it 'resolves usernames to ids before the REST call', :aggregate_failures do
        allow(update_tool).to receive(:execute).and_return(mock_response)

        service.execute(request: request, params: params)

        expect(params[:arguments]).to include(assignee_ids: [alice.id], reviewer_ids: [bob.id])
        expect(params[:arguments]).not_to have_key(:assignees)
        expect(params[:arguments]).not_to have_key(:reviewers)
      end

      context 'when a username does not exist' do
        let(:arguments) { { project_id: 'group/project', merge_request_iid: 7, assignees: ['ghost'] } }

        it 'returns a generic error that does not name the username', :aggregate_failures do
          result = service.execute(request: request, params: params)

          expect(result[:isError]).to be true
          expect(result[:content].first[:text]).to include('One or more usernames could not be resolved')
          expect(result[:content].first[:text]).not_to include('ghost')
        end
      end
    end

    context 'when update-only fields are given without merge_request_iid' do
      let(:arguments) do
        { project_id: 'group/project', title: 'x', source_branch: 'y', state_event: 'close' }
      end

      it 'refuses to create rather than dropping the fields', :aggregate_failures do
        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be true
        expect(result[:content].first[:text]).to include('These fields only apply when updating: state_event')
      end
    end

    context 'when invoked via the update_merge_request alias' do
      context 'without merge_request_iid' do
        let(:params) { { name: 'update_merge_request', arguments: arguments } }
        let(:arguments) do
          { project_id: 'group/project', title: 'x', source_branch: 'y', target_branch: 'z' }
        end

        it 'refuses to create rather than dispatching to create', :aggregate_failures do
          expect(create_tool).not_to receive(:execute)

          result = service.execute(request: request, params: params)

          expect(result[:isError]).to be true
          expect(result[:content].first[:text]).to include('update_merge_request requires merge_request_iid')
        end
      end

      context 'with merge_request_iid' do
        let(:params) { { name: 'update_merge_request', arguments: arguments } }
        let(:arguments) { { project_id: 'group/project', merge_request_iid: 5, title: 'x' } }

        it 'routes to the update tool' do
          expect(update_tool).to receive(:execute).with(request: request, params: params).and_return(mock_response)

          service.execute(request: request, params: params)
        end
      end
    end

    context 'when invoked via the create_merge_request alias' do
      context 'without merge_request_iid' do
        let(:params) { { name: 'create_merge_request', arguments: arguments } }
        let(:arguments) do
          { project_id: 'group/project', title: 'x', source_branch: 'y', target_branch: 'z' }
        end

        it 'routes to the create tool' do
          expect(create_tool).to receive(:execute).with(request: request, params: params).and_return(mock_response)

          service.execute(request: request, params: params)
        end
      end

      context 'with merge_request_iid' do
        let(:params) { { name: 'create_merge_request', arguments: arguments } }
        let(:arguments) { { project_id: 'group/project', merge_request_iid: 5, title: 'x' } }

        it 'refuses to update rather than dispatching to update', :aggregate_failures do
          expect(update_tool).not_to receive(:execute)

          result = service.execute(request: request, params: params)

          expect(result[:isError]).to be true
          expect(result[:content].first[:text]).to include('create_merge_request does not accept merge_request_iid')
        end
      end
    end

    context 'when an update includes create-only params' do
      let(:arguments) { { project_id: 'group/project', merge_request_iid: 9, title: 'x', source_branch: 'feature' } }

      it 'notes the ignored params in the response text' do
        allow(update_tool).to receive(:execute).and_return(mock_response)

        result = service.execute(request: request, params: params)

        expect(result[:content].first[:text]).to include('Ignored params not valid for update: source_branch')
      end
    end

    context 'when assignee_ids are passed instead of usernames' do
      let(:arguments) { { project_id: 'group/project', merge_request_iid: 7, assignee_ids: [1, 2] } }

      it 'forwards them unchanged for backward compatibility' do
        allow(update_tool).to receive(:execute).and_return(mock_response)

        service.execute(request: request, params: params)

        expect(params[:arguments]).to include(assignee_ids: [1, 2])
      end
    end

    context 'when both assignees and assignee_ids are given' do
      let(:arguments) do
        { project_id: 'group/project', merge_request_iid: 7, assignees: ['alice'], assignee_ids: [1] }
      end

      it 'rejects the ambiguous input', :aggregate_failures do
        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be true
        expect(result[:content].first[:text]).to include('Provide assignees or assignee_ids, not both')
      end
    end

    context 'when creating without the required title and source_branch' do
      let(:arguments) { { project_id: 'group/project', target_branch: 'master' } }

      it 'returns a validation error instead of guessing the operation', :aggregate_failures do
        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be true
        expect(result[:content].first[:text]).to include('Validation error: Cannot determine operation')
      end
    end

    context 'when creating without target_branch' do
      let(:arguments) { { project_id: 'group/project', title: 'x', source_branch: 'feature' } }

      it 'requires target_branch rather than deferring to a downstream REST error', :aggregate_failures do
        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be true
        expect(result[:content].first[:text]).to include('target_branch')
      end
    end

    context 'with string-keyed arguments as delivered over MCP transport' do
      let(:params) { { arguments: arguments.with_indifferent_access } }

      context 'when update-only fields are given without merge_request_iid' do
        let(:arguments) do
          { 'project_id' => 'group/project', 'title' => 'x', 'source_branch' => 'y',
            'target_branch' => 'z', 'state_event' => 'close' }
        end

        it 'still fires the guard rather than silently creating', :aggregate_failures do
          expect(create_tool).not_to receive(:execute)

          result = service.execute(request: request, params: params)

          expect(result[:isError]).to be true
          expect(result[:content].first[:text]).to include('These fields only apply when updating: state_event')
        end
      end

      context 'when a valid create is requested' do
        let(:arguments) do
          { 'project_id' => 'group/project', 'title' => 'Add feature',
            'source_branch' => 'feature', 'target_branch' => 'master' }
        end

        it 'creates without reporting valid params as ignored', :aggregate_failures do
          allow(create_tool).to receive(:execute).and_return(mock_response)

          result = service.execute(request: request, params: params)

          expect(result[:isError]).to be false
          expect(result[:content].first[:text]).not_to include('Ignored params')
        end
      end

      context 'when an update includes create-only params' do
        let(:arguments) do
          { 'project_id' => 'group/project', 'merge_request_iid' => 9,
            'title' => 'x', 'source_branch' => 'feature' }
        end

        it 'reports only the create-only param as ignored', :aggregate_failures do
          allow(update_tool).to receive(:execute).and_return(mock_response)

          result = service.execute(request: request, params: params)

          expect(result[:content].first[:text]).to include('Ignored params not valid for update: source_branch')
          expect(result[:content].first[:text]).not_to include('project_id')
        end
      end
    end

    context 'when the matching tool is not registered' do
      let(:arguments) { { project_id: 'group/project', merge_request_iid: 42, title: 'Updated title' } }
      let(:service) { described_class.new(tools: []) }

      it 'returns a tool-not-found error', :aggregate_failures do
        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be true
        expect(result[:content].first[:text]).to eq("Tool execution failed: Tool 'save_merge_request' not found.")
      end
    end
  end
end
