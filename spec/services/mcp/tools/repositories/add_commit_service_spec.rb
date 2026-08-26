# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::Repositories::AddCommitService, feature_category: :mcp_server do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public, :repository) }

  let(:service) { described_class.new(name: 'add_commit') }

  before_all do
    project.add_developer(user)
  end

  before do
    service.set_cred(current_user: user)
  end

  describe 'class configuration' do
    it 'registers version 0.1.0' do
      expect(described_class.available_versions).to contain_exactly('0.1.0')
    end

    it 'identifies the tool as a destructive write operation' do
      expect(service.annotations).to eq({ readOnlyHint: false, destructiveHint: true })
    end

    it 'keeps the tool it replaces working through an alias' do
      expect(described_class.tool_aliases).to contain_exactly('create_commit')
    end

    it 'is resolvable by its alias through the manager' do
      expect(Mcp::Tools::Manager.new.get_tool(name: 'create_commit')).to be_a(described_class)
    end
  end

  describe 'input schema' do
    it 'locks the full input schema for version 0.1.0' do
      expect(described_class.version_metadata('0.1.0')[:input_schema]).to eq({
        type: 'object',
        properties: {
          url: { type: 'string', description: 'GitLab URL of the project. Provide this or project_id.' },
          project_id: { type: 'string', description: 'ID or path of the project. Provide this or url.' },
          branch: { type: 'string', description: 'Name of the branch to commit into.' },
          start_branch: {
            type: 'string',
            description: 'Name of the branch from which to create a new branch. ' \
              'Required when branch does not exist yet.'
          },
          commit_message: { type: 'string', description: 'Commit message.' },
          actions: {
            type: 'array',
            description: 'File actions to commit as a single batch.',
            minItems: 1,
            maxItems: 100,
            items: {
              type: 'object',
              properties: {
                action: {
                  type: 'string',
                  enum: %w[create update delete move chmod],
                  description: 'Action to perform.'
                },
                file_path: { type: 'string', description: 'Full path to the file.' },
                content: {
                  type: 'string',
                  description: 'File content for create, update, or move actions. ' \
                    'Mutually exclusive with old_str and new_str.'
                },
                old_str: {
                  type: 'string',
                  description: 'Existing text to replace in an update action. Requires new_str.'
                },
                new_str: { type: 'string', description: 'Replacement text for old_str in an update action.' },
                previous_path: { type: 'string', description: 'Original file path for a move action.' },
                encoding: {
                  type: 'string',
                  enum: %w[text base64],
                  description: 'Encoding of the file content. Defaults to text.'
                },
                last_commit_id: {
                  type: 'string',
                  description: 'Last commit that touched the file, used for optimistic concurrency.'
                },
                execute_filemode: { type: 'boolean', description: 'Whether the file is executable.' }
              },
              required: %w[action file_path],
              additionalProperties: false
            }
          }
        },
        required: %w[branch commit_message actions]
      })
    end
  end

  describe '#execute' do
    let(:params) do
      {
        arguments: {
          project_id: project.full_path,
          branch: project.default_branch,
          commit_message: 'Add MCP test file',
          actions: [{ action: 'create', file_path: 'mcp-test.txt', content: 'Test content' }]
        }
      }
    end

    it 'creates a commit through the GraphQL mutation' do
      result = service.execute(params: params)

      expect(result[:isError]).to be(false)
      expect(result[:structuredContent].dig('commit', 'sha')).to be_present
      expect(project.repository.blob_at_branch(project.default_branch, 'mcp-test.txt').data).to eq('Test content')
    end

    context 'when current_user is not set' do
      before do
        service.set_cred(current_user: nil)
      end

      it 'returns an error response' do
        result = service.execute(params: params)

        expect(result[:isError]).to be(true)
        expect(result.dig(:content, 0, :text)).to include('current_user is not set')
      end
    end

    context 'with a partial edit' do
      let(:params) do
        {
          arguments: {
            project_id: project.full_path,
            branch: project.default_branch,
            commit_message: 'Update README',
            actions: [{ action: 'update', file_path: 'README.md', old_str: 'Sample repo', new_str: 'MCP' }]
          }
        }
      end

      it 'expands and commits the partial edit' do
        result = service.execute(params: params)

        expect(result[:isError]).to be(false)
        expect(project.repository.blob_at_branch(project.default_branch, 'README.md').data).to include('MCP')
      end
    end
  end

  describe 'partial edit expansion' do
    let(:base_arguments) do
      {
        project_id: project.full_path,
        branch: project.default_branch,
        commit_message: 'Partial edit',
        actions: [{ action: 'update', file_path: 'README.md', old_str: 'old', new_str: 'new' }]
      }
    end

    let(:blob_content) { 'before old after' }
    let(:blob_result) do
      Mcp::Tools::Base::Response.success([], {
        'repository' => {
          'blobs' => { 'nodes' => [{ 'path' => 'README.md', 'rawTextBlob' => blob_content }] }
        }
      })
    end

    before do
      blobs_tool = instance_double(Mcp::Tools::Repositories::BlobsTool, execute: blob_result)
      allow(Mcp::Tools::Repositories::BlobsTool).to receive(:new).and_return(blobs_tool)
    end

    it 'expands a unique match and preserves replacement backslashes' do
      base_arguments[:actions][0][:new_str] = '\\1 replacement'

      expect(service).to receive(:execute_graphql_tool).with(hash_including(
        actions: [hash_including(content: 'before \\1 replacement after')]
      )).and_return(Mcp::Tools::Base::Response.success([]))

      service.send(:perform_v0_1_0, base_arguments)
    end

    it 'returns an error when old_str is not found' do
      base_arguments[:actions][0][:old_str] = 'missing'

      result = service.send(:perform_v0_1_0, base_arguments)

      expect(result[:content].first[:text]).to include('old_str was not found')
    end

    it 'returns an error when old_str is ambiguous' do
      base_arguments[:actions][0][:old_str] = 'old'
      allow(service).to receive(:read_blobs).and_return(
        Mcp::Tools::Base::Response.success([], {
          'repository' => { 'blobs' => { 'nodes' => [{ 'path' => 'README.md', 'rawTextBlob' => 'old old' }] } }
        })
      )

      result = service.send(:perform_v0_1_0, base_arguments)

      expect(result[:content].first[:text]).to include('old_str is ambiguous')
    end

    where(:changes, :error) do
      [
        [{ content: 'complete' }, 'Provide either content'],
        [{ action: 'create' }, 'only supported for update'],
        [{ encoding: 'base64' }, 'require text encoding']
      ]
    end

    with_them do
      it 'rejects an invalid partial edit' do
        base_arguments[:actions][0].merge!(changes)

        result = service.send(:perform_v0_1_0, base_arguments)

        expect(result[:content].first[:text]).to include(error)
      end
    end

    it 'returns an error for a binary file' do
      allow(service).to receive(:read_blobs).and_return(
        Mcp::Tools::Base::Response.success([], {
          'repository' => { 'blobs' => { 'nodes' => [{ 'path' => 'README.md', 'rawTextBlob' => nil }] } }
        })
      )

      result = service.send(:perform_v0_1_0, base_arguments)

      expect(result[:content].first[:text]).to include('is binary')
    end

    it 'applies multiple edits to the same path in sequence' do
      base_arguments[:actions] << {
        action: 'update', file_path: 'README.md', old_str: 'new', new_str: 'newest'
      }

      expect(service).to receive(:execute_graphql_tool).with(hash_including(
        actions: [hash_including(content: 'before new after'), hash_including(content: 'before newest after')]
      )).and_return(Mcp::Tools::Base::Response.success([]))

      service.send(:perform_v0_1_0, base_arguments)
    end

    it 'handles non-ASCII fragments' do
      allow(service).to receive(:read_blobs).and_return(
        Mcp::Tools::Base::Response.success([], {
          'repository' => { 'blobs' => { 'nodes' => [{ 'path' => 'README.md', 'rawTextBlob' => 'héllo' }] } }
        })
      )
      base_arguments[:actions][0].merge!(old_str: 'héllo', new_str: 'नमस्ते')

      expect(service).to receive(:execute_graphql_tool).with(hash_including(
        actions: [hash_including(content: 'नमस्ते')]
      )).and_return(Mcp::Tools::Base::Response.success([]))

      service.send(:perform_v0_1_0, base_arguments)
    end

    it 'wraps a blob read error with partial edit context' do
      allow(service).to receive(:read_blobs).and_return(
        Mcp::Tools::Base::Response.error('Max blobs size limit exceeded')
      )

      result = service.send(:perform_v0_1_0, base_arguments)

      expect(result[:isError]).to be(true)
      expect(result[:content].first[:text]).to include(
        'Could not read the file(s) needed to expand the partial edit',
        'Max blobs size limit exceeded'
      )
    end

    it 'does not swallow an unrelated ArgumentError raised while running the mutation' do
      allow(service).to receive(:execute_graphql_tool).and_raise(ArgumentError, 'URL must identify a project')

      expect { service.send(:perform_v0_1_0, base_arguments) }
        .to raise_error(ArgumentError, 'URL must identify a project')
    end

    it 'reads from branch, not start_branch, when branch already exists' do
      base_arguments[:start_branch] = 'nonexistent-start-branch'

      expect(Mcp::Tools::Repositories::BlobsTool).to receive(:new)
        .with(hash_including(params: hash_including(ref: project.default_branch)))
        .and_return(instance_double(Mcp::Tools::Repositories::BlobsTool, execute: blob_result))
      expect(service).to receive(:execute_graphql_tool).and_return(Mcp::Tools::Base::Response.success([]))

      service.send(:perform_v0_1_0, base_arguments)
    end

    it 'reads from start_branch when branch does not exist yet' do
      base_arguments[:branch] = 'brand-new-feature-branch'
      base_arguments[:start_branch] = project.default_branch

      expect(Mcp::Tools::Repositories::BlobsTool).to receive(:new)
        .with(hash_including(params: hash_including(ref: project.default_branch)))
        .and_return(instance_double(Mcp::Tools::Repositories::BlobsTool, execute: blob_result))
      expect(service).to receive(:execute_graphql_tool).and_return(Mcp::Tools::Base::Response.success([]))

      service.send(:perform_v0_1_0, base_arguments)
    end
  end
end
