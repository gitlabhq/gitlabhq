# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::Repositories::Branches::AddBranchTool, feature_category: :mcp_server do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository, maintainers: [user]) }

  let(:params) { { project_id: project.full_path, branch: 'my-feature', ref: 'master' } }
  let(:tool) { described_class.new(current_user: user, params: params) }

  describe 'versioning' do
    it 'registers version using VERSIONS constant' do
      expect(tool.version).to eq(Mcp::Tools::Concerns::Constants::VERSIONS[:v0_1_0])
    end

    it 'has correct operation name for version 0.1.0' do
      expect(tool.operation_name).to eq('createBranch')
    end

    it 'has correct GraphQL operation for version 0.1.0' do
      operation = tool.graphql_operation

      expect(operation).to include('mutation addBranch')
      expect(operation).to include('createBranch(input: $input)')
    end
  end

  describe '#build_variables' do
    it 'builds variables with the project path, branch name, and ref' do
      variables = tool.build_variables

      expect(variables).to eq(
        input: {
          projectPath: project.full_path,
          name: 'my-feature',
          ref: 'master'
        }
      )
    end

    context 'when the project does not exist' do
      let(:params) { { project_id: 'does-not/exist', branch: 'my-feature', ref: 'master' } }

      it 'raises an error' do
        expect { tool.build_variables }.to raise_error(StandardError, /not found or inaccessible/)
      end
    end

    context 'when using url instead of project_id' do
      let(:params) { { url: "https://gitlab.example.com/#{project.full_path}", branch: 'my-feature', ref: 'master' } }

      it 'builds variables using the project resolved from the url' do
        variables = tool.build_variables

        expect(variables).to eq(
          input: {
            projectPath: project.full_path,
            name: 'my-feature',
            ref: 'master'
          }
        )
      end
    end

    context 'when neither url nor project_id is provided' do
      let(:params) { { branch: 'my-feature', ref: 'master' } }

      it 'raises an error' do
        expect { tool.build_variables }.to raise_error(ArgumentError, 'Provide either url or project_id')
      end
    end

    context 'when url and project_id disagree' do
      let(:params) do
        {
          url: "https://gitlab.example.com/#{project.full_path}",
          project_id: 'some-other/project',
          branch: 'my-feature',
          ref: 'master'
        }
      end

      it 'raises an error' do
        expect { tool.build_variables }.to raise_error(
          ArgumentError, "Project mismatch: project_id is 'some-other/project' but url contains '#{project.full_path}'"
        )
      end
    end

    context 'when url and an inaccessible numeric project_id disagree' do
      let_it_be(:inaccessible_project) { create(:project, :private) }

      let(:params) do
        {
          url: "https://gitlab.example.com/#{project.full_path}",
          project_id: inaccessible_project.id.to_s,
          branch: 'my-feature',
          ref: 'master'
        }
      end

      it 'raises an error' do
        expect { tool.build_variables }.to raise_error(
          ArgumentError,
          "Project mismatch: project_id is '#{inaccessible_project.id}' but url contains '#{project.full_path}'"
        )
      end
    end

    context 'when url and project_id agree' do
      let(:params) do
        { url: "https://gitlab.example.com/#{project.full_path}", project_id: project.full_path,
          branch: 'my-feature', ref: 'master' }
      end

      it 'builds variables using the project' do
        variables = tool.build_variables

        expect(variables).to eq(
          input: {
            projectPath: project.full_path,
            name: 'my-feature',
            ref: 'master'
          }
        )
      end
    end

    context 'when url and numeric project_id agree' do
      let(:params) do
        { url: "https://gitlab.example.com/#{project.full_path}", project_id: project.id.to_s,
          branch: 'my-feature', ref: 'master' }
      end

      it 'builds variables using the project' do
        variables = tool.build_variables

        expect(variables).to eq(
          input: {
            projectPath: project.full_path,
            name: 'my-feature',
            ref: 'master'
          }
        )
      end

      context 'when project_id has leading zeros' do
        let(:params) { super().merge(project_id: "0#{project.id}") }

        it 'builds variables using the project' do
          expect(tool.build_variables.dig(:input, :projectPath)).to eq(project.full_path)
        end
      end
    end
  end

  describe 'integration' do
    it 'executes mutation with correct variables' do
      params[:branch] = 'integration-branch'
      allow(GitlabSchema).to receive(:execute).and_call_original

      tool.execute

      expect(GitlabSchema).to have_received(:execute).with(
        anything,
        variables: {
          input: {
            projectPath: project.full_path,
            name: 'integration-branch',
            ref: 'master'
          }
        },
        context: hash_including(current_user: user)
      )
    end

    it 'returns branch data with the full payload shape the tool promises' do
      result = tool.execute

      expect(result[:isError]).to be(false)
      expect(result[:structuredContent].keys).to match_array(%w[branch errors])

      branch = result[:structuredContent]['branch']
      expect(branch.keys).to match_array(%w[name commit web_url])
      expect(branch['name']).to eq('my-feature')
      expect(branch['commit']['sha']).to eq(project.repository.commit('master').id)
      expect(branch['web_url']).to eq(Gitlab::Routing.url_helpers.project_tree_url(project, 'my-feature'))
      expect(project.repository.branch_exists?('my-feature')).to be true

      # Asserted here rather than in a separate example: the repository is shared
      # across examples, so a second execute would hit "branch already exists".
      text = Gitlab::Json::SafeParser.parse(result[:content].first[:text])
      expect(text.dig('branch', 'web_url')).to eq(branch['web_url'])
    end

    # A slash is the shape that could break quietly here: project_tree_url keeps it
    # only because the tree route is a glob. 'feature/foo' itself is unusable in this
    # spec, because the fixture repository already has a 'feature' branch and git
    # cannot nest a ref under an existing one.
    it 'keeps a slash unescaped in the URL of a branch whose name contains one' do
      params[:branch] = 'mcp/feature-foo'

      result = tool.execute

      expect(result[:isError]).to be(false)

      branch = result[:structuredContent]['branch']
      expect(branch['name']).to eq('mcp/feature-foo')
      expect(branch['web_url']).to end_with('/-/tree/mcp/feature-foo')
      expect(branch['web_url'])
        .to eq(Gitlab::Routing.url_helpers.project_tree_url(project, 'mcp/feature-foo'))
    end

    context 'when the user cannot push code' do
      let_it_be(:outsider) { create(:user, reporter_of: project) }
      let(:tool) { described_class.new(current_user: outsider, params: params) }

      it 'returns an error' do
        result = tool.execute

        expect(result[:isError]).to be(true)
      end
    end

    context 'when the ref does not exist' do
      let(:params) { { project_id: project.full_path, branch: 'ref-does-not-exist-branch', ref: 'does-not-exist' } }

      it 'returns an error' do
        result = tool.execute

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include("invalid reference name 'does-not-exist'")
      end
    end

    context 'when the branch already exists' do
      let(:params) { { project_id: project.full_path, branch: project.default_branch, ref: 'master' } }

      it 'returns an error' do
        result = tool.execute

        expect(result[:isError]).to be(true)
      end
    end

    context 'when the branch name is invalid' do
      let(:params) { { project_id: project.full_path, branch: 'my branch', ref: 'master' } }

      it 'returns an error' do
        result = tool.execute

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('Branch name is invalid')
      end
    end

    # Without the early return, the nil branch would be assigned into and raise
    # NoMethodError instead of passing the mutation's own payload back.
    context 'when the mutation reports no error but returns no branch' do
      it 'passes the payload through without adding a URL' do
        allow(GitlabSchema).to receive(:execute)
          .and_return({ 'data' => { 'createBranch' => { 'branch' => nil, 'errors' => [] } } })

        result = tool.execute

        expect(result[:isError]).to be(false)
        expect(result[:structuredContent]).to eq({ 'branch' => nil, 'errors' => [] })
      end
    end
  end
end
