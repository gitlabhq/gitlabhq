# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::Repositories::AddCommitTool, feature_category: :mcp_server do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public, :repository) }

  let(:params) do
    {
      project_id: project.id.to_s,
      branch: 'feature',
      start_branch: project.default_branch,
      commit_message: 'Update files',
      actions: [
        {
          action: 'move',
          file_path: 'NEW_README.md',
          previous_path: 'README.md',
          content: 'Updated',
          encoding: 'text',
          last_commit_id: 'abc123',
          execute_filemode: false
        }
      ]
    }
  end

  let(:tool) { described_class.new(current_user: user, params: params) }

  describe 'versioning' do
    it 'registers the commitCreate mutation' do
      expect(tool.version).to eq('0.1.0')
      expect(tool.operation_name).to eq('commitCreate')
      expect(tool.graphql_operation).to include('mutation addCommit')
      expect(tool.graphql_operation).to include('commitCreate(input: $input)')
    end
  end

  describe '#build_variables' do
    it 'maps tool arguments to CommitCreateInput' do
      expect(tool.build_variables).to eq({
        input: {
          projectPath: project.full_path,
          branch: 'feature',
          startBranch: project.default_branch,
          message: 'Update files',
          actions: [{
            action: 'MOVE',
            filePath: 'NEW_README.md',
            previousPath: 'README.md',
            content: 'Updated',
            encoding: 'TEXT',
            lastCommitId: 'abc123',
            executeFilemode: false
          }]
        }
      })
    end

    context 'with a project URL' do
      let(:params) { super().except(:project_id).merge(url: Gitlab::UrlBuilder.build(project)) }

      it 'resolves the project path' do
        expect(tool.build_variables.dig(:input, :projectPath)).to eq(project.full_path)
      end
    end

    context 'without a project identifier' do
      let(:params) { super().except(:project_id) }

      it 'raises an argument error' do
        expect { tool.build_variables }.to raise_error(ArgumentError, 'Provide exactly one of project_id or url')
      end
    end

    context 'with both project identifiers' do
      let(:params) { super().merge(url: Gitlab::UrlBuilder.build(project)) }

      it 'raises an argument error' do
        expect { tool.build_variables }.to raise_error(ArgumentError, 'Provide exactly one of project_id or url')
      end
    end

    context 'with a group URL' do
      let_it_be(:group) { create(:group) }
      let(:params) { super().except(:project_id).merge(url: Gitlab::UrlBuilder.build(group)) }

      it 'raises an argument error' do
        expect { tool.build_variables }.to raise_error(ArgumentError, 'URL must identify a project')
      end
    end
  end
end
