# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::Repositories::ListRepositoryTreeTool, feature_category: :mcp_server do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) do
    create(:project, :public, :custom_repo, files: {
      'README.md' => 'readme',
      'app/models/user.rb' => 'class User; end',
      'app/models/group.rb' => 'class Group; end'
    })
  end

  let(:params) { { project_id: project.id.to_s } }
  let(:tool) { described_class.new(current_user: user, params: params) }

  def result_entries(result)
    result[:structuredContent]['entries']
  end

  def result_paths(result)
    result_entries(result).map { |entry| entry['path'] }
  end

  describe 'versioning' do
    it 'registers version 0.1.0' do
      expect(tool.version).to eq(Mcp::Tools::Concerns::Constants::VERSIONS[:v0_1_0])
    end

    it 'reads the project root field' do
      expect(tool.operation_name).to eq('project')
    end
  end

  describe '#build_variables' do
    it 'resolves the project and omits optional arguments that are not provided', :aggregate_failures do
      variables = tool.build_variables

      expect(variables[:fullPath]).to eq(project.full_path)
      expect(variables.keys).to contain_exactly(:fullPath)
    end

    context 'with all optional arguments' do
      let(:params) do
        super().merge(path: 'app', ref: 'master', recursive: true, after: 'cursor1')
      end

      it 'maps them to GraphQL variables', :aggregate_failures do
        variables = tool.build_variables

        expect(variables[:path]).to eq('app')
        expect(variables[:ref]).to eq('master')
        expect(variables[:recursive]).to be(true)
        expect(variables[:after]).to eq('cursor1')
      end
    end

    describe 'project identification' do
      context 'when no project is provided' do
        let(:params) { {} }

        it 'raises an ArgumentError' do
          expect { tool.build_variables }.to raise_error(ArgumentError, /Provide exactly one of/)
        end
      end

      context 'when both url and project_id are provided' do
        let(:params) { { url: project.web_url, project_id: project.id.to_s } }

        it 'raises an ArgumentError rather than silently picking one' do
          expect { tool.build_variables }.to raise_error(ArgumentError, /Provide exactly one of/)
        end
      end

      context 'with a project URL' do
        let(:params) { { url: project.web_url } }

        it 'resolves the project from the URL' do
          expect(tool.build_variables[:fullPath]).to eq(project.full_path)
        end
      end

      context 'with a full path' do
        let(:params) { { project_id: project.full_path } }

        it 'resolves the project from the path' do
          expect(tool.build_variables[:fullPath]).to eq(project.full_path)
        end
      end
    end
  end

  describe 'integration' do
    it 'executes the query as the current user with the resolved variables' do
      allow(GitlabSchema).to receive(:execute).and_call_original

      tool.execute

      expect(GitlabSchema).to have_received(:execute).with(
        anything,
        variables: hash_including(fullPath: project.full_path),
        context: hash_including(current_user: user)
      )
    end

    it 'returns the root entries merged into a flat list', :aggregate_failures do
      result = tool.execute

      expect(result[:isError]).to be(false)
      expect(result[:content].first[:type]).to eq('text')
      expect(result[:structuredContent]).to have_key('pageInfo')
      expect(result_entries(result)).to contain_exactly(
        a_hash_including('name' => 'app', 'type' => 'tree', 'path' => 'app'),
        a_hash_including('name' => 'README.md', 'type' => 'blob', 'path' => 'README.md', 'mode' => '100644')
      )
    end

    it 'returns the Git object ID of each entry rather than a GraphQL global ID' do
      readme = result_entries(tool.execute).find { |entry| entry['path'] == 'README.md' }

      expect(readme['id']).to eq(project.repository.blob_at(project.default_branch, 'README.md').id)
    end

    context 'with a subdirectory path' do
      let(:params) { super().merge(path: 'app/models') }

      it 'returns only that directory\'s entries' do
        expect(result_paths(tool.execute)).to contain_exactly('app/models/group.rb', 'app/models/user.rb')
      end
    end

    context 'with a leading slash in the path' do
      let(:params) { super().merge(path: '/app/models') }

      it 'resolves it relative to the repository root' do
        expect(result_paths(tool.execute)).to contain_exactly('app/models/group.rb', 'app/models/user.rb')
      end
    end

    context 'with multiple leading slashes in the path' do
      let(:params) { super().merge(path: '//app/models') }

      it 'resolves it relative to the repository root' do
        expect(result_paths(tool.execute)).to contain_exactly('app/models/group.rb', 'app/models/user.rb')
      end
    end

    context 'with recursive listing' do
      let(:params) { super().merge(recursive: true) }

      it 'returns entries of all subdirectories' do
        expect(result_paths(tool.execute)).to contain_exactly(
          'README.md', 'app', 'app/models', 'app/models/group.rb', 'app/models/user.rb'
        )
      end
    end

    describe 'pagination' do
      let_it_be(:big_project) do
        create(:project, :empty_repo).tap do |big_project|
          actions = (1..101).map do |i|
            { action: :create, file_path: format('file-%03d.txt', i), content: '' }
          end

          big_project.repository.commit_files(
            big_project.creator, branch_name: 'master', message: 'Add files', actions: actions
          )
        end
      end

      let(:params) { { project_id: big_project.full_path } }

      before_all do
        big_project.add_developer(user)
      end

      it 'pages through all entries without skipping any', :aggregate_failures do
        first_page = tool.execute

        expect(result_entries(first_page).size).to eq(100)
        expect(first_page[:structuredContent]['pageInfo']['hasNextPage']).to be(true)

        cursor = first_page[:structuredContent]['pageInfo']['endCursor']
        second_page = described_class.new(current_user: user, params: params.merge(after: cursor)).execute

        expect(second_page[:structuredContent]['pageInfo']['hasNextPage']).to be(false)
        expect(result_paths(first_page) + result_paths(second_page)).to match_array(
          (1..101).map { |i| format('file-%03d.txt', i) }
        )
      end

      context 'when a continuation page comes back empty' do
        let(:params) { { project_id: project.id.to_s, after: 'some-cursor' } }

        before do
          allow(GitlabSchema).to receive(:execute).and_return(
            { 'data' => { 'project' => { 'id' => project.to_global_id.to_s, 'repository' => {
              'paginatedTree' => { 'nodes' => [], 'pageInfo' => { 'hasNextPage' => false, 'endCursor' => nil } }
            } } } }
          )
        end

        it 'returns an empty result rather than a not-found error', :aggregate_failures do
          result = tool.execute

          expect(result[:isError]).to be(false)
          expect(result_entries(result)).to be_empty
        end
      end
    end

    context 'with an empty repository' do
      let_it_be(:empty_project) { create(:project, :public, :empty_repo) }

      let(:params) { { project_id: empty_project.full_path } }

      it 'returns no entries rather than an error', :aggregate_failures do
        result = tool.execute

        expect(result[:isError]).to be(false)
        expect(result_entries(result)).to be_empty
        expect(result[:structuredContent]['pageInfo']).to eq({ 'hasNextPage' => false, 'endCursor' => nil })
      end
    end

    describe 'misses' do
      context 'when the ref does not exist' do
        let(:params) { super().merge(ref: 'no-such-ref') }

        it 'says the ref was not found', :aggregate_failures do
          result = tool.execute

          expect(result[:isError]).to be(true)
          expect(result[:content].first[:text]).to include("Ref 'no-such-ref' not found")
        end
      end

      context 'when the path does not exist' do
        let(:params) { super().merge(path: 'no/such/dir') }

        it 'says the path was not found', :aggregate_failures do
          result = tool.execute

          expect(result[:isError]).to be(true)
          expect(result[:content].first[:text]).to include("Path 'no/such/dir' not found at ref 'HEAD'")
        end
      end

      context 'when the path is a file' do
        let(:params) { super().merge(path: 'README.md') }

        it 'says the path was not found' do
          expect(tool.execute[:content].first[:text]).to include("Path 'README.md' not found")
        end
      end
    end

    describe 'authorization' do
      let_it_be(:private_project) { create(:project, :private, :small_repo) }

      let(:params) { { project_id: private_project.full_path } }

      context 'when the caller is not a member' do
        it 'uses the same wording as a missing project so existence cannot be inferred' do
          expect { tool.execute }.to raise_error(::Gitlab::Access::AccessDeniedError, /not found or inaccessible/)
        end
      end

      context 'when the caller is a guest without code access' do
        before_all do
          private_project.add_guest(user)
        end

        it 'returns a permission error rather than an empty tree', :aggregate_failures do
          result = tool.execute

          expect(result[:isError]).to be(true)
          expect(result[:content].first[:text]).to include('repository', 'is not available')
        end
      end

      context 'when the caller is a member with code access' do
        let_it_be(:member) { create(:user) }

        let(:tool) { described_class.new(current_user: member, params: params) }

        before_all do
          private_project.add_developer(member)
        end

        it 'returns the entries' do
          expect(result_paths(tool.execute)).to contain_exactly('test.txt')
        end
      end

      context 'when the project does not exist' do
        let(:params) { { project_id: non_existing_record_id.to_s } }

        it 'raises before executing GraphQL' do
          expect { tool.execute }.to raise_error(StandardError, /not found or inaccessible/)
        end
      end
    end

    context 'when GraphQL returns errors' do
      before do
        allow(GitlabSchema).to receive(:execute).and_return({ 'errors' => [{ 'message' => 'Boom' }] })
      end

      it 'surfaces the error message', :aggregate_failures do
        result = tool.execute

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('Boom')
      end
    end

    context 'when the project resolves but the query returns no data' do
      before do
        allow(GitlabSchema).to receive(:execute).and_return({ 'data' => { 'project' => nil } })
      end

      it 'returns a project-not-found error', :aggregate_failures do
        result = tool.execute

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('Project not found')
      end
    end
  end
end
