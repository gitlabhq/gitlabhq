# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::Repositories::Branches::AddBranchService, feature_category: :mcp_server do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository, maintainers: [user]) }

  let(:service_name) { 'add_branch' }
  let(:service) { described_class.new(name: service_name, version: '0.1.0') }
  let(:request) { instance_double(ActionDispatch::Request) }

  before do
    service.set_cred(current_user: user)
  end

  describe 'class configuration' do
    it 'inherits from GraphqlService' do
      expect(described_class.superclass).to eq(Mcp::Tools::Base::GraphqlService)
    end

    it 'registers version 0.1.0' do
      expect(described_class.version_exists?('0.1.0')).to be true
    end

    it 'has correct description' do
      expect(service.description).to include('Add a branch to a GitLab project')
    end

    it 'has readOnlyHint: false annotation' do
      expect(service.annotations[:readOnlyHint]).to be(false)
    end

    it 'has destructiveHint: false annotation' do
      expect(service.annotations[:destructiveHint]).to be(false)
    end
  end

  describe '.tool_aliases' do
    it 'aliases the create_branch tool name' do
      expect(described_class.tool_aliases).to eq(['create_branch'])
    end
  end

  describe '#input_schema' do
    it 'matches the expected contract' do
      expect(service.input_schema).to eq(
        {
          type: 'object',
          properties: {
            url: {
              type: 'string',
              description: 'GitLab URL of the project. Provide this, or project_id.'
            },
            project_id: {
              type: 'string',
              description: 'ID or path of the project. Required if url is not provided.'
            },
            branch: {
              type: 'string',
              description: 'Name of the new branch'
            },
            ref: {
              type: 'string',
              description: 'Branch name or commit SHA to create the new branch from'
            }
          },
          required: %w[branch ref],
          additionalProperties: false
        }
      )
    end
  end

  describe '#graphql_tool_class' do
    it 'returns AddBranchTool class' do
      expect(service.send(:graphql_tool_class)).to eq(Mcp::Tools::Repositories::Branches::AddBranchTool)
    end
  end

  describe '#perform_0_1_0' do
    let(:arguments) { { project_id: project.full_path, branch: 'my-feature', ref: 'master' } }

    it 'executes graphql tool with arguments' do
      expect(service).to receive(:execute_graphql_tool).with(arguments)

      service.send(:perform_0_1_0, arguments)
    end
  end

  describe '#perform_default' do
    let(:arguments) { { project_id: project.full_path, branch: 'my-feature', ref: 'master' } }

    it 'delegates to perform_0_1_0' do
      expect(service).to receive(:perform_0_1_0).with(arguments)

      service.send(:perform_default, arguments)
    end
  end

  describe '#execute' do
    context 'when current_user is not set' do
      it 'returns an error' do
        anonymous_service = described_class.new(name: service_name, version: '0.1.0')

        result = anonymous_service.execute(
          request: request, params: { arguments: { project_id: project.full_path, branch: 'my-feature',
                                                   ref: 'master' } }
        )

        expect(result[:isError]).to be true
        expect(result[:content].first[:text]).to include('current_user is not set')
      end
    end

    context 'when the project does not exist' do
      it 'returns an error' do
        result = service.execute(
          request: request, params: { arguments: { project_id: 'does-not/exist', branch: 'my-feature', ref: 'master' } }
        )

        expect(result[:isError]).to be true
        expect(result[:content].first[:text]).to match(/not found or inaccessible/)
      end
    end

    context 'when using url instead of project_id' do
      it 'creates the branch' do
        result = service.execute(
          request: request,
          params: {
            arguments: {
              url: "https://gitlab.example.com/#{project.full_path}", branch: 'feature-via-url', ref: 'master'
            }
          }
        )

        expect(result[:isError]).to be false
        expect(project.repository.branch_exists?('feature-via-url')).to be true
      end
    end

    context 'when neither url nor project_id is provided' do
      it 'returns an error' do
        result = service.execute(
          request: request, params: { arguments: { branch: 'my-feature', ref: 'master' } }
        )

        expect(result[:isError]).to be true
        expect(result[:content].first[:text]).to include('Provide either url or project_id')
      end
    end

    context 'when url and project_id disagree' do
      it 'returns an error' do
        result = service.execute(
          request: request,
          params: {
            arguments: {
              url: "https://gitlab.example.com/#{project.full_path}", project_id: 'some-other/project',
              branch: 'my-feature', ref: 'master'
            }
          }
        )

        expect(result[:isError]).to be true
        expect(result[:content].first[:text]).to include('Project mismatch')
      end
    end

    context 'when the user cannot push code' do
      let_it_be(:outsider) { create(:user) }

      before do
        service.set_cred(current_user: outsider)
      end

      it 'returns a permission denied error' do
        result = service.execute(
          request: request, params: { arguments: { project_id: project.full_path, branch: 'my-feature',
                                                   ref: 'master' } }
        )

        expect(result[:isError]).to be true
      end
    end

    context 'when the ref does not exist' do
      it 'returns an error' do
        result = service.execute(
          request: request,
          params: { arguments: { project_id: project.full_path, branch: 'ref-does-not-exist-branch',
                                 ref: 'does-not-exist' } }
        )

        expect(result[:isError]).to be true
        expect(result[:content].first[:text]).to include("invalid reference name 'does-not-exist'")
      end
    end

    context 'when the branch already exists' do
      it 'returns an error' do
        result = service.execute(
          request: request,
          params: { arguments: { project_id: project.full_path, branch: project.default_branch, ref: 'master' } }
        )

        expect(result[:isError]).to be true
      end
    end

    context 'when the branch name is invalid' do
      it 'returns an error' do
        result = service.execute(
          request: request,
          params: { arguments: { project_id: project.full_path, branch: 'my branch', ref: 'master' } }
        )

        expect(result[:isError]).to be true
        expect(result[:content].first[:text]).to include('Branch name is invalid')
      end
    end

    context 'with valid arguments' do
      it 'creates the branch', :aggregate_failures do
        result = service.execute(
          request: request, params: { arguments: { project_id: project.full_path, branch: 'my-feature',
                                                   ref: 'master' } }
        )

        expect(result[:isError]).to be false
        expect(result[:structuredContent]['branch']).to eq({
          'name' => 'my-feature',
          'commit' => {
            'id' => "gid://gitlab/Commit/#{project.repository.commit('master').id}",
            'sha' => project.repository.commit('master').id
          }
        })
        expect(project.repository.branch_exists?('my-feature')).to be true
      end
    end

    context 'when called as the create_branch alias' do
      it 'creates the branch' do
        result = service.execute(
          request: request,
          params: {
            name: 'create_branch', arguments: { project_id: project.full_path, branch: 'another-feature',
                                                ref: 'master' }
          }
        )

        expect(result[:isError]).to be false
        expect(project.repository.branch_exists?('another-feature')).to be true
      end
    end
  end
end
