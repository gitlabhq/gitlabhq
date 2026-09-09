# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::Repositories::AddCommitService, feature_category: :mcp_server do
  include ProjectForksHelper

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
          start_sha: {
            type: 'string',
            description: 'SHA of the commit to start a new branch from. ' \
              'Mutually exclusive with start_branch.'
          },
          start_project: {
            type: 'string',
            description: 'Full path of the project to start the commit from. Must be the ' \
              'project itself or a project it was forked from.'
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

    context 'when starting a new branch from a sha' do
      let(:start_sha) { project.repository.commit("#{project.default_branch}~1").sha }
      let(:params) do
        {
          arguments: {
            project_id: project.full_path,
            branch: 'from-sha-branch',
            start_sha: start_sha,
            commit_message: 'Commit from sha',
            actions: [{ action: 'create', file_path: 'from-sha.txt', content: 'x' }]
          }
        }
      end

      it 'creates the branch from the given sha', :aggregate_failures do
        result = service.execute(params: params)

        expect(result[:isError]).to be(false)
        expect(project.repository.commit('from-sha-branch').parent_ids).to contain_exactly(start_sha)
      end

      context 'with start_branch as well' do
        let(:params) do
          super().tap { |p| p[:arguments][:start_branch] = project.default_branch }
        end

        it 'surfaces the mutual-exclusion error', :aggregate_failures do
          result = service.execute(params: params)

          expect(result[:isError]).to be(true)
          expect(result.dig(:content, 0, :text)).to include('Only one of [startBranch, startSha] arguments is allowed')
        end
      end
    end

    context 'when a partial edit seeds a new branch from a sha' do
      let(:start_sha) { project.repository.commit(project.default_branch).sha }
      let(:params) do
        {
          arguments: {
            project_id: project.full_path,
            branch: 'partial-from-sha',
            start_sha: start_sha,
            commit_message: 'Partial edit from sha',
            actions: [{ action: 'update', file_path: 'README.md', old_str: 'Sample repo', new_str: 'MCP' }]
          }
        }
      end

      it 'reads the file at the sha instead of the not-yet-existing branch', :aggregate_failures do
        result = service.execute(params: params)

        expect(result[:isError]).to be(false)
        expect(project.repository.commit('partial-from-sha').parent_ids).to contain_exactly(start_sha)
        expect(project.repository.blob_at_branch('partial-from-sha', 'README.md').data).to include('MCP')
      end
    end

    context 'when a partial edit is combined with start_project' do
      let(:params) do
        {
          arguments: {
            project_id: project.full_path,
            branch: 'partial-start-project',
            start_sha: project.repository.commit(project.default_branch).sha,
            start_project: project.full_path,
            commit_message: 'x',
            actions: [{ action: 'update', file_path: 'README.md', old_str: 'a', new_str: 'b' }]
          }
        }
      end

      it 'rejects the combination with a self-correcting error', :aggregate_failures do
        result = service.execute(params: params)

        expect(result[:isError]).to be(true)
        expect(result.dig(:content, 0, :text)).to include('not supported with start_project')
      end
    end

    context 'when starting from a forked project' do
      let_it_be(:forked_project) { fork_project(project, nil, repository: true) }

      let(:start_sha) { project.repository.commit(project.default_branch).sha }
      let(:params) do
        {
          arguments: {
            project_id: forked_project.full_path,
            branch: 'from-upstream',
            start_sha: start_sha,
            start_project: project.full_path,
            commit_message: 'Commit from upstream',
            actions: [{ action: 'create', file_path: 'from-upstream.txt', content: 'x' }]
          }
        }
      end

      before_all do
        forked_project.add_developer(user)
      end

      it 'creates the branch starting from the upstream project', :aggregate_failures do
        result = service.execute(params: params)

        expect(result[:isError]).to be(false)
        expect(forked_project.repository.commit('from-upstream')).to be_present
      end

      context 'when the start project is outside the fork network' do
        let_it_be(:unrelated) { create(:project, :public, :repository) }

        let(:params) do
          super().tap { |p| p[:arguments][:start_project] = unrelated.full_path }
        end

        it 'rejects it with the uniform fork-network error', :aggregate_failures do
          result = service.execute(params: params)

          expect(result[:isError]).to be(true)
          expect(result.dig(:content, 0, :text)).to include('fork network')
        end
      end
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

      # The truncation guard fails closed, so size dropping out of the shared
      # get_repository_file query would reject every partial edit.
      it 'gets a blob size back from the shared query' do
        nodes = service.send(:read_blobs, params[:arguments].with_indifferent_access, ['README.md'])
          .dig(:structuredContent, 'repository', 'blobs', 'nodes')

        expect(nodes.first['size']).to be_present
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
    let(:lfs_pointer) do
      "version https://git-lfs.github.com/spec/v1\noid sha256:#{'a' * 64}\nsize 1024\n"
    end

    let(:blob_result) do
      Mcp::Tools::Base::Response.success([], {
        'repository' => {
          'blobs' => { 'nodes' => [{
            'path' => 'README.md', 'size' => blob_content.bytesize, 'rawTextBlob' => blob_content
          }] }
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
          'repository' => {
            'blobs' => { 'nodes' => [{ 'path' => 'README.md', 'size' => 7, 'rawTextBlob' => 'old old' }] }
          }
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
          'repository' => {
            'blobs' => { 'nodes' => [{ 'path' => 'README.md', 'size' => 1024, 'rawTextBlob' => nil }] }
          }
        })
      )

      result = service.send(:perform_v0_1_0, base_arguments)

      expect(result[:content].first[:text]).to include('is binary')
    end

    it 'returns an error for a file stored in LFS', :aggregate_failures do
      allow(service).to receive(:read_blobs).and_return(
        Mcp::Tools::Base::Response.success([], {
          'repository' => {
            'blobs' => { 'nodes' => [{
              'path' => 'data.csv', 'size' => '134', 'rawTextBlob' => lfs_pointer,
              'storedExternally' => true, 'externalStorage' => 'lfs'
            }] }
          }
        })
      )
      base_arguments[:actions][0].merge!(file_path: 'data.csv', old_str: 'size 1024', new_str: 'size 2048')

      result = service.send(:perform_v0_1_0, base_arguments)

      expect(result[:isError]).to be(true)
      expect(result[:content].first[:text]).to include("File 'data.csv' is stored in LFS (lfs)")
    end

    it 'returns an error for a file larger than the display limit', :aggregate_failures do
      # A string, because the GraphQL size field is a BigInt and serializes that way.
      oversized = (Gitlab::Git::Blob::MAX_DATA_DISPLAY_SIZE + 1).to_s
      allow(service).to receive(:read_blobs).and_return(
        Mcp::Tools::Base::Response.success([], {
          'repository' => {
            'blobs' => { 'nodes' => [{ 'path' => 'README.md', 'size' => oversized, 'rawTextBlob' => 'old' }] }
          }
        })
      )

      result = service.send(:perform_v0_1_0, base_arguments)

      expect(result[:isError]).to be(true)
      expect(result[:content].first[:text]).to include('exceeds the 10 MiB partial-edit size limit')
    end

    it 'returns an error when the blob size is unknown', :aggregate_failures do
      allow(service).to receive(:read_blobs).and_return(
        Mcp::Tools::Base::Response.success([], {
          'repository' => {
            'blobs' => { 'nodes' => [{ 'path' => 'README.md', 'size' => nil, 'rawTextBlob' => 'before old after' }] }
          }
        })
      )

      result = service.send(:perform_v0_1_0, base_arguments)

      expect(result[:isError]).to be(true)
      expect(result[:content].first[:text]).to include('has an unknown size')
    end

    it 'accepts a file exactly at the display limit', :aggregate_failures do
      # truncated? reads only size, never the content length, so a fixture claiming the
      # full limit while carrying 16 bytes costs nothing and pins the > (not >=) boundary.
      # Real 10 MiB content would allocate 10 MiB per run and cover no extra branch.
      at_limit = Gitlab::Git::Blob::MAX_DATA_DISPLAY_SIZE
      allow(service).to receive(:read_blobs).and_return(
        Mcp::Tools::Base::Response.success([], {
          'repository' => {
            'blobs' => { 'nodes' => [{
              'path' => 'README.md', 'size' => at_limit, 'rawTextBlob' => 'before old after'
            }] }
          }
        })
      )

      expect(service).to receive(:execute_graphql_tool).with(hash_including(
        actions: [hash_including(content: 'before new after')]
      )).and_return(Mcp::Tools::Base::Response.success([]))

      result = service.send(:perform_v0_1_0, base_arguments)

      expect(result[:isError]).to be(false)
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
          'repository' => {
            'blobs' => { 'nodes' => [{ 'path' => 'README.md', 'size' => 'héllo'.bytesize, 'rawTextBlob' => 'héllo' }] }
          }
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
