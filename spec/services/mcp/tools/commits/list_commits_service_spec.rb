# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::Commits::ListCommitsService, feature_category: :mcp_server do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public, :repository) }

  let(:service) { described_class.new(name: 'list_commits') }

  before_all do
    project.add_developer(user)
  end

  before do
    service.set_cred(current_user: user)
  end

  describe 'class configuration' do
    it 'registers version 0.1.0' do
      expect(described_class.available_versions).to include('0.1.0')
    end

    it 'is registered in the manager' do
      expect(Mcp::Tools::Manager.new.get_tool(name: 'list_commits')).to be_a(described_class)
    end

    it 'locks the description' do
      expect(described_class.version_metadata('0.1.0')[:description]).to eq(
        'List commits in a GitLab project, filtered by ref, author, path, or date. ' \
          'Identify the project with exactly one of url or project_id. Returns compact commit ' \
          'metadata; use get_commit for a single commit\'s diff or notes.'
      )
    end
  end

  describe 'input schema' do
    it 'locks the full input schema for version 0.1.0' do
      expect(described_class.version_metadata('0.1.0')[:input_schema]).to eq({
        type: 'object',
        required: [],
        properties: {
          url: {
            type: 'string',
            description: 'GitLab URL of the project.'
          },
          project_id: {
            type: 'string',
            description: 'ID or full path of the project.'
          },
          ref_name: {
            type: 'string',
            description: 'Branch or tag to list commits from. Defaults to the project default branch.'
          },
          author: {
            type: 'string',
            description: 'Filter by commit author name or email.'
          },
          path: {
            type: 'string',
            description: 'Only return commits that touch this file path.'
          },
          since: {
            type: 'string',
            description: 'Only return commits with a committed date after this ISO 8601 date or time.'
          },
          until: {
            type: 'string',
            description: 'Only return commits with a committed date before this ISO 8601 date or time.'
          },
          order: {
            type: 'string',
            description: 'Ordering strategy. Defaults to reverse chronological when omitted.',
            enum: %w[topo date]
          },
          first_parent: {
            type: 'boolean',
            description: 'Follow only the first parent of merge commits.'
          },
          with_stats: {
            type: 'boolean',
            description: 'Include per-commit line-count stats (additions, deletions, files changed). ' \
              'Each commit costs a Gitaly call, so the page is capped at ' \
              "#{Mcp::Tools::Commits::ListCommitsTool.stats_max_first} when set: first defaults to " \
              "#{Mcp::Tools::Commits::ListCommitsTool.stats_max_first} and must not exceed " \
              "#{Mcp::Tools::Commits::ListCommitsTool.stats_max_first}."
          },
          after: {
            type: 'string',
            description: 'Cursor for forward pagination. Use endCursor from the previous response.'
          },
          first: {
            type: 'integer',
            description: 'Number of commits to return (forward pagination, default 20, max 100). ' \
              "A maximum of #{Mcp::Tools::Commits::ListCommitsTool.stats_max_first} applies when " \
              'with_stats is set.',
            minimum: 1,
            maximum: 100
          }
        }
      })
    end
  end

  describe 'schema validation' do
    it 'rejects unknown arguments' do
      expect(service.input_schema[:additionalProperties]).to be(false)
    end
  end

  describe 'order enum' do
    it 'stays in sync with the CommitOrder GraphQL enum' do
      schema_values = described_class.version_metadata('0.1.0')[:input_schema][:properties][:order][:enum]
      graphql_values = ::Types::Repositories::CommitOrderEnum.values.values.map(&:value)

      expect(schema_values).to match_array(graphql_values)
    end
  end

  describe '#execute' do
    let(:request) { instance_double(ActionDispatch::Request) }
    let(:params) { { arguments: { project_id: project.id.to_s } } }

    it 'returns the commits connection', :aggregate_failures do
      result = service.execute(request: request, params: params)

      expect(result[:isError]).to be(false)
      expect(result[:structuredContent]).to have_key('nodes')
      expect(result[:structuredContent]).to have_key('pageInfo')
    end

    it 'instantiates the tool with the resolved version and arguments' do
      expect(Mcp::Tools::Commits::ListCommitsTool).to receive(:new).with(
        current_user: user,
        params: params[:arguments],
        version: '0.1.0'
      ).and_call_original

      service.execute(request: request, params: params)
    end

    context 'when current_user is not set' do
      before do
        service.set_cred(current_user: nil)
      end

      it 'returns an error response', :aggregate_failures do
        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('current_user is not set')
      end
    end
  end
end
