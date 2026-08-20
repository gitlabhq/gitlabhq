# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::Commits::GetCommitTool, feature_category: :mcp_server do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository, :public) }
  let_it_be(:commit) { project.commit }
  let_it_be(:note) do
    create(:note_on_commit, project: project, commit_id: commit.id, author: user, note: 'Looks good')
  end

  let(:params) { { project_id: project.id.to_s, commit_sha: commit.sha } }
  let(:tool) { described_class.new(current_user: user, params: params) }

  before_all do
    project.add_developer(user)
  end

  describe 'versioning' do
    it 'registers version 0.1.0' do
      expect(tool.version).to eq(Mcp::Tools::Concerns::Constants::VERSIONS[:v0_1_0])
    end

    it 'has correct operation name for version 0.1.0' do
      expect(tool.operation_name).to eq('project')
    end

    it 'loads the committed GraphQL operation' do
      expect(tool.graphql_operation).to include('query getCommit')
    end
  end

  describe '#build_variables' do
    it 'builds variables with project full path and commit ref', :aggregate_failures do
      variables = tool.build_variables

      expect(variables[:fullPath]).to eq(project.full_path)
      expect(variables[:ref]).to eq(commit.sha)
    end

    it 'requests no facets by default', :aggregate_failures do
      variables = tool.build_variables

      expect(variables).to include(withStats: false, withPatch: false, withNotes: false)
    end

    context 'when include is [diff] and diff_detail is stats (default)' do
      let(:params) { super().merge(include: ['diff']) }

      it 'requests stats only', :aggregate_failures do
        variables = tool.build_variables

        expect(variables).to include(withStats: true, withPatch: false)
      end
    end

    context 'when include is [diff] and diff_detail is full_patch' do
      let(:params) { super().merge(include: ['diff'], diff_detail: 'full_patch') }

      it 'requests the patch only', :aggregate_failures do
        variables = tool.build_variables

        expect(variables).to include(withStats: false, withPatch: true)
      end
    end

    context 'when include is [notes]' do
      let(:params) { super().merge(include: ['notes']) }

      it 'requests notes' do
        expect(tool.build_variables).to include(withNotes: true)
      end
    end

    context 'when notes pagination parameters are provided' do
      let(:params) { super().merge(include: ['notes'], notes_after: 'cursor1', notes_first: 25) }

      it 'maps them to the notes connection variables', :aggregate_failures do
        variables = tool.build_variables

        expect(variables[:notesAfter]).to eq('cursor1')
        expect(variables[:notesFirst]).to eq(25)
      end
    end
  end

  describe 'integration' do
    it 'executes the query as the current user with the resolved variables' do
      allow(GitlabSchema).to receive(:execute).and_call_original

      tool.execute

      expect(GitlabSchema).to have_received(:execute).with(
        anything,
        variables: hash_including(fullPath: project.full_path, ref: commit.sha),
        context: hash_including(current_user: user)
      )
    end

    it 'returns the commit metadata shaped for agent consumption', :aggregate_failures do
      result = tool.execute

      expect(result[:isError]).to be(false)
      expect(result[:content].first[:type]).to eq('text')
      expect(result[:structuredContent]).to include('sha' => commit.sha)
      expect(result[:structuredContent]).to have_key('authorName')
    end

    context 'with the diff facet and stats detail' do
      let(:params) { super().merge(include: ['diff'], diff_detail: 'stats') }

      it 'includes diff stats and summary but not the patch', :aggregate_failures do
        commit = tool.execute[:structuredContent]

        expect(commit['diffStatsSummary']).to include('additions', 'deletions', 'fileCount')
        expect(commit['diffStats']).to be_an(Array)
        expect(commit).not_to have_key('diffs')
      end
    end

    context 'with the diff facet and full_patch detail' do
      let(:params) { super().merge(include: ['diff'], diff_detail: 'full_patch') }

      it 'includes the patch but not stats', :aggregate_failures do
        commit = tool.execute[:structuredContent]

        expect(commit['diffs']).to be_an(Array)
        expect(commit).not_to have_key('diffStatsSummary')
      end

      it 'exposes the truncation flags on each diff so callers can detect excluded patches' do
        diffs = tool.execute[:structuredContent]['diffs']

        expect(diffs).to all(include('collapsed', 'tooLarge'))
      end
    end

    context 'with the notes facet' do
      let(:params) { super().merge(include: ['notes']) }

      it 'includes the paginated notes connection', :aggregate_failures do
        commit = tool.execute[:structuredContent]

        expect(commit['notes']).to have_key('pageInfo')
        expect(commit['notes']['nodes'].map { |n| n['body'] }).to include('Looks good')
      end
    end

    context 'when the commit does not exist' do
      let(:params) { { project_id: project.id.to_s, commit_sha: Gitlab::Git::SHA1_BLANK_SHA } }

      it 'returns a commit-not-found error', :aggregate_failures do
        result = tool.execute

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('Commit not found')
      end
    end

    context 'when the project in the URL does not exist' do
      let(:params) { { url: "#{Gitlab.config.gitlab.url}/no-such-group/no-such-project/-/commit/#{commit.sha}" } }

      it 'returns a project-not-found error', :aggregate_failures do
        result = tool.execute

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('Project not found')
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

    context 'when the project does not exist' do
      let(:params) { { project_id: non_existing_record_id.to_s, commit_sha: commit.sha } }

      it 'raises before executing GraphQL' do
        expect { tool.execute }.to raise_error(StandardError, /not found or inaccessible/)
      end
    end

    context 'with a commit URL' do
      let(:params) { { url: "#{project.web_url}/-/commit/#{commit.sha}" } }

      it 'resolves the project and commit from the URL', :aggregate_failures do
        variables = tool.build_variables

        expect(variables[:fullPath]).to eq(project.full_path)
        expect(variables[:ref]).to eq(commit.sha)
      end
    end

    context 'with an invalid commit URL' do
      let(:params) { { url: 'https://gitlab.com/not-a-real-path' } }

      it 'raises an ArgumentError' do
        expect { tool.build_variables }.to raise_error(ArgumentError, /Invalid commit URL/)
      end
    end

    context 'when commit_sha is provided without project_id' do
      let(:params) { { commit_sha: commit.sha } }

      it 'raises an ArgumentError' do
        expect { tool.build_variables }.to raise_error(ArgumentError, /Provide either url/)
      end
    end

    context 'when project_id is provided without commit_sha' do
      let(:params) { { project_id: project.id.to_s } }

      it 'raises an ArgumentError' do
        expect { tool.build_variables }.to raise_error(ArgumentError, /Provide either url/)
      end
    end

    context 'when both url and project_id/commit_sha are provided' do
      let(:params) do
        { url: "#{project.web_url}/-/commit/#{commit.sha}", project_id: project.id.to_s, commit_sha: commit.sha }
      end

      it 'raises an ArgumentError' do
        expect { tool.build_variables }.to raise_error(ArgumentError, /not both/)
      end
    end
  end
end
