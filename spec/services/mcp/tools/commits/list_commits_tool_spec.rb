# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::Commits::ListCommitsTool, feature_category: :mcp_server do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public, :repository) }

  let(:params) { { project_id: project.id.to_s } }
  let(:tool) { described_class.new(current_user: user, params: params) }

  def result_shas(result)
    result[:structuredContent]['nodes'].map { |node| node['sha'] }
  end

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
    it 'resolves the project and applies the defaults', :aggregate_failures do
      variables = tool.build_variables

      expect(variables[:fullPath]).to eq(project.full_path)
      expect(variables[:ref]).to eq(project.default_branch)
      expect(variables[:first]).to eq(20)
      expect(variables[:withStats]).to be(false)
    end

    it 'omits filters that are not provided', :aggregate_failures do
      variables = tool.build_variables

      expect(variables).not_to have_key(:author)
      expect(variables).not_to have_key(:path)
      expect(variables).not_to have_key(:order)
      expect(variables).not_to have_key(:firstParent)
      expect(variables).not_to have_key(:after)
    end

    context 'with filters and pagination' do
      let(:params) do
        super().merge(
          ref_name: 'feature',
          author: 'Alice',
          path: 'files/ruby/popen.rb',
          since: '2020-01-01',
          until: '2021-01-01',
          order: 'topo',
          first_parent: true,
          first: 25,
          after: 'cursor1'
        )
      end

      it 'maps them to GraphQL variables', :aggregate_failures do
        variables = tool.build_variables

        expect(variables[:ref]).to eq('feature')
        expect(variables[:author]).to eq('Alice')
        expect(variables[:path]).to eq('files/ruby/popen.rb')
        expect(variables[:committedAfter]).to eq('2020-01-01')
        expect(variables[:committedBefore]).to eq('2021-01-01')
        expect(variables[:order]).to eq('TOPO')
        expect(variables[:firstParent]).to be(true)
        expect(variables[:first]).to eq(25)
        expect(variables[:after]).to eq('cursor1')
      end
    end

    describe 'with_stats' do
      let(:stats_limit) do
        ::Types::Repositories::CommitType.fields['diffStatsSummary'].extensions
          .find { |ext| ext.is_a?(::Gitlab::Graphql::Limit::FieldCallCount) }
          .options[:limit]
      end

      it 'derives the page cap from a FieldCallCount limit on diffStatsSummary' do
        extension = ::Types::Repositories::CommitType.fields['diffStatsSummary'].extensions
          .find { |ext| ext.is_a?(::Gitlab::Graphql::Limit::FieldCallCount) }

        expect(extension)
          .to be_present,
            'diffStatsSummary no longer declares a FieldCallCount limit; update the with_stats page cap in ' \
              'ListCommitsTool.stats_max_first'
      end

      context 'when set without an explicit page size' do
        let(:params) { super().merge(with_stats: true) }

        it 'requests stats and keeps the default page within the field limit', :aggregate_failures do
          variables = tool.build_variables

          expect(variables[:withStats]).to be(true)
          expect(variables[:first]).to be <= stats_limit
        end
      end

      context 'when set with a page size within the cap' do
        let(:params) { super().merge(with_stats: true, first: 1) }

        it 'keeps the requested page size' do
          expect(tool.build_variables[:first]).to eq(1)
        end
      end

      context 'when set with a page size above the cap' do
        let(:params) { super().merge(with_stats: true, first: stats_limit + 1) }

        it 'raises rather than exceed the per-request stats limit' do
          expect { tool.build_variables }.to raise_error(ArgumentError, /at most \d+ commits per page/)
        end
      end
    end

    describe 'ref resolution' do
      context 'when no ref_name is given and the project has no default branch' do
        let_it_be(:empty_project) { create(:project, :empty_repo, :public) }

        let(:params) { { project_id: empty_project.id.to_s } }

        it 'raises rather than send a null ref to a required argument' do
          expect { tool.build_variables }.to raise_error(ArgumentError, /no default branch/)
        end
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

    it 'returns the commits connection shaped for agent consumption', :aggregate_failures do
      result = tool.execute

      expect(result[:isError]).to be(false)
      expect(result[:content].first[:type]).to eq('text')
      expect(result[:structuredContent]).to have_key('pageInfo')
      expect(result[:structuredContent]).to have_key('nodes')
      expect(result_shas(result)).to include(project.commit.sha)
      expect(result[:structuredContent]['nodes'].first).to include('authoredDate', 'committedDate')
    end

    describe 'filtering' do
      context 'when filtering by path' do
        let(:params) { super().merge(path: 'files/ruby/popen.rb') }

        it 'returns fewer commits than the unfiltered list', :aggregate_failures do
          filtered = tool.execute[:structuredContent]['nodes']
          unfiltered = described_class.new(current_user: user, params: { project_id: project.id.to_s })
            .execute[:structuredContent]['nodes']

          expect(filtered).not_to be_empty
          expect(filtered.size).to be < unfiltered.size
        end
      end

      context 'when requesting stats' do
        let(:params) { super().merge(with_stats: true, first: 5) }

        it 'includes a per-commit stats summary on each node', :aggregate_failures do
          nodes = tool.execute[:structuredContent]['nodes']

          expect(nodes).not_to be_empty
          expect(nodes.first['diffStatsSummary']).to include('additions', 'deletions', 'fileCount')
        end
      end

      context 'when not requesting stats' do
        it 'omits stats from the nodes' do
          expect(tool.execute[:structuredContent]['nodes'].first).not_to have_key('diffStatsSummary')
        end
      end
    end

    describe 'pagination' do
      let(:params) { super().merge(first: 1) }

      it 'limits the page and reports a next page', :aggregate_failures do
        result = tool.execute

        expect(result[:structuredContent]['nodes'].size).to eq(1)
        expect(result[:structuredContent]['pageInfo']['hasNextPage']).to be(true)
        expect(result[:structuredContent]['pageInfo']['endCursor']).to be_present
      end
    end

    context 'when the ref does not exist' do
      let(:params) { super().merge(ref_name: 'does-not-exist') }

      it 'surfaces the error', :aggregate_failures do
        result = tool.execute

        expect(result[:isError]).to be(true)
      end
    end

    describe 'authorization' do
      let_it_be(:non_member) { create(:user) }
      let_it_be(:private_project) { create(:project, :private, :repository) }

      let(:params) { { project_id: private_project.id.to_s } }

      context 'when the caller is not a member' do
        let(:tool) { described_class.new(current_user: non_member, params: params) }

        it 'denies access rather than listing commits' do
          expect { tool.execute }.to raise_error(StandardError, /not found or inaccessible/)
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
        expect(result[:content].first[:text]).to eq('Project not found or inaccessible')
      end
    end
  end
end
