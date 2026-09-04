# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::Projects::GetProjectTool, feature_category: :mcp_server do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public, :repository) }

  let(:params) { { project_id: project.id.to_s } }
  let(:tool) { described_class.new(current_user: user, params: params) }

  before_all do
    project.add_developer(user)
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
    it 'resolves the project from its numeric ID' do
      expect(tool.build_variables).to eq({ fullPath: project.full_path })
    end

    context 'with a full path' do
      let(:params) { { project_id: project.full_path } }

      it 'resolves the project from the path' do
        expect(tool.build_variables[:fullPath]).to eq(project.full_path)
      end
    end

    context 'with a project URL' do
      let(:params) { { url: project.web_url } }

      it 'resolves the project from the URL' do
        expect(tool.build_variables[:fullPath]).to eq(project.full_path)
      end
    end

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
  end

  describe 'integration' do
    it 'executes the query as the current user with the resolved variables' do
      allow(GitlabSchema).to receive(:execute).and_call_original

      tool.execute

      expect(GitlabSchema).to have_received(:execute).with(
        anything,
        variables: { fullPath: project.full_path },
        context: hash_including(current_user: user)
      )
    end

    it 'returns the project metadata shaped for agent consumption', :aggregate_failures do
      result = tool.execute

      expect(result[:isError]).to be(false)
      expect(result[:content].first[:type]).to eq('text')
      expect(result[:structuredContent]).to eq({
        id: project.id,
        path_with_namespace: project.full_path,
        default_branch: project.default_branch,
        visibility: 'public',
        web_url: project.web_url
      })
    end

    it 'unwraps the global ID into a plain numeric ID' do
      expect(tool.execute[:structuredContent][:id]).to be_a(Integer)
    end

    context 'when the project has no repository' do
      let_it_be(:project_without_repository) { create(:project, :public) }

      let(:params) { { project_id: project_without_repository.id.to_s } }

      it 'returns a nil default branch instead of erroring', :aggregate_failures do
        result = tool.execute

        expect(result[:isError]).to be(false)
        expect(result[:structuredContent][:default_branch]).to be_nil
      end
    end

    describe 'authorization' do
      let_it_be(:non_member) { create(:user) }
      let_it_be(:private_project) { create(:project, :private, :repository) }

      let(:params) { { project_id: private_project.id.to_s } }

      context 'when the caller is not a member' do
        let(:tool) { described_class.new(current_user: non_member, params: params) }

        it 'uses the same wording as a missing project so existence cannot be inferred' do
          expect { tool.execute }.to raise_error(StandardError, /not found or inaccessible/)
        end
      end

      context 'when the caller is a member' do
        before_all do
          private_project.add_developer(user)
        end

        it 'returns its metadata' do
          expect(tool.execute[:structuredContent][:visibility]).to eq('private')
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
