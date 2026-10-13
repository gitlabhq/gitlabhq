# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::Commits::GetCommitService, feature_category: :mcp_server do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :small_repo, :public) }
  let_it_be(:commit) { project.commit }

  let(:service) { described_class.new(name: 'get_commit') }
  let(:request) { instance_double(ActionDispatch::Request) }
  let(:params) { { arguments: { project_id: project.id.to_s, commit_sha: commit.sha } } }

  before_all do
    project.add_developer(user)
  end

  before do
    service.set_cred(current_user: user)
  end

  describe 'class configuration' do
    it 'inherits from GraphqlService' do
      expect(described_class.superclass).to eq(Mcp::Tools::Base::GraphqlService)
    end

    it 'registers version 0.1.0' do
      expect(described_class.available_versions).to include('0.1.0')
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
            description: 'GitLab URL of the commit. Provide this, or project_id and commit_sha.'
          },
          project_id: {
            type: 'string',
            description: 'ID or path of the project. Required if url is not provided.'
          },
          commit_sha: {
            type: 'string',
            description: 'Commit to look up. Accepts a full or short SHA, branch name, or tag name. ' \
              'Required if url is not provided.'
          },
          include: {
            type: 'array',
            description: 'Associated facet to fetch inline, one per call. "diff" returns the commit diff ' \
              '(bounded by diff_detail); "notes" returns the commit notes (paginated with ' \
              'notes_after/notes_first).',
            items: {
              type: 'string',
              enum: %w[diff notes]
            },
            maxItems: 1
          },
          diff_detail: {
            type: 'string',
            description: 'Level of diff detail to return. Applies only when "diff" is in include. ' \
              '"stats" returns per-file and summary line counts; "full_patch" returns the patch text. ' \
              'Defaults to "stats".',
            enum: %w[stats full_patch]
          },
          notes_after: {
            type: 'string',
            description: 'Cursor for forward pagination of notes. ' \
              'Use pageInfo.endCursor from a previous response. Applies only when notes is in include.'
          },
          notes_first: {
            type: 'integer',
            description: 'Number of notes to return after the cursor (forward pagination). Max 100. ' \
              'Applies only when notes is in include.',
            minimum: 1,
            maximum: 100
          }
        }
      })
    end
  end

  describe '#execute' do
    it 'returns the commit metadata', :aggregate_failures do
      result = service.execute(request: request, params: params)

      expect(result[:isError]).to be(false)
      expect(result[:structuredContent]).to include('sha' => commit.sha)
    end

    it 'instantiates the tool with the resolved version and arguments' do
      expect(Mcp::Tools::Commits::GetCommitTool).to receive(:new).with(
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

  describe '#governed_containers' do
    it 'governs by the project a commit url names', :aggregate_failures do
      url = "#{::Gitlab.config.gitlab.url}/#{project.full_path}/-/commit/#{commit.sha}"
      resolved = service.governed_containers({ url: url }.with_indifferent_access)

      expect(resolved.containers).to contain_exactly(project)
      expect(resolved.named).to eq(1)
    end

    it 'governs by the project named directly', :aggregate_failures do
      resolved = service.governed_containers({ project_id: project.id.to_s }.with_indifferent_access)

      expect(resolved.containers).to contain_exactly(project)
      expect(resolved.named).to eq(1)
    end

    it 'governs a decoy url by the project the commit is read from as well', :aggregate_failures do
      decoy_project = create(:project)
      url = "#{::Gitlab.config.gitlab.url}/#{decoy_project.full_path}/-/merge_requests/1 " \
        "#{::Gitlab.config.gitlab.url}/#{project.full_path}/-/commit/#{commit.sha}"
      resolved = service.governed_containers({ url: url }.with_indifferent_access)

      expect(resolved.containers).to contain_exactly(decoy_project, project)
      expect(resolved.named).to eq(2)
    end

    it 'keeps a url it cannot read named, so the call is refused', :aggregate_failures do
      resolved = service.governed_containers({ url: 'https://example.com/nope' }.with_indifferent_access)

      expect(resolved.containers).to be_empty
      expect(resolved.named).to eq(1)
    end
  end
end
