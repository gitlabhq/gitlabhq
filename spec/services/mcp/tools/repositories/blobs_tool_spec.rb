# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::Repositories::BlobsTool, feature_category: :mcp_server do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository, developers: user) }

  let(:params) do
    { project_id: project.full_path, paths: ['README.md'], ref: project.default_branch }
  end

  let(:tool) { described_class.new(current_user: user, params: params) }

  describe '#build_variables' do
    it 'builds variables for a project blob read' do
      expect(tool.build_variables).to eq({
        projectPath: project.full_path,
        filePaths: ['README.md'],
        ref: project.default_branch
      })
    end
  end

  describe '#execute' do
    it 'returns blob contents' do
      result = tool.execute

      expect(result[:isError]).to be(false)
      expect(result[:structuredContent].dig('repository', 'blobs', 'nodes', 0)).to include(
        'path' => 'README.md',
        'rawTextBlob' => include('Sample repo')
      )
    end

    context 'when a requested path contains a traversal sequence' do
      let(:params) do
        { project_id: project.full_path, paths: ['docs/../README.md'], ref: project.default_branch }
      end

      it 'returns an error without reading the blob', :aggregate_failures do
        expect(tool).not_to receive(:build_variables)

        result = tool.execute

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('docs/../README.md', 'path traversal sequence')
      end
    end

    context 'when a requested path is absolute' do
      let(:params) do
        { project_id: project.full_path, paths: ['/../README.md'], ref: project.default_branch }
      end

      it 'rejects the leading-slash traversal form' do
        expect(tool.execute[:isError]).to be(true)
      end
    end

    context 'when the caller cannot read the project' do
      let_it_be(:private_project) { create(:project, :private, :repository) }
      let(:params) do
        { project_id: private_project.full_path, paths: ['README.md'], ref: private_project.default_branch }
      end

      it 'raises before executing GraphQL' do
        expect { tool.execute }.to raise_error(StandardError, /not found or inaccessible/)
      end
    end

    context 'when the caller can read the project but not the code' do
      let_it_be(:outsider) { create(:user) }
      let_it_be(:restricted_project) do
        create(:project, :public, :repository, :repository_private)
      end

      let(:params) do
        { project_id: restricted_project.full_path, paths: ['README.md'], ref: restricted_project.default_branch }
      end

      let(:tool) { described_class.new(current_user: outsider, params: params) }

      it 'raises before executing GraphQL' do
        expect { tool.execute }.to raise_error(StandardError, /not found or inaccessible/)
      end
    end
  end
end
