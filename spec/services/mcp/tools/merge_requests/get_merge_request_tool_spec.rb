# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::MergeRequests::GetMergeRequestTool, :request_store, feature_category: :mcp_server do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
  let_it_be(:all_notes) do
    [
      create(:note_on_merge_request, noteable: merge_request, project: project, author: user),
      create(:note_on_merge_request, :system, noteable: merge_request, project: project, author: user),
      create(:discussion_note_on_merge_request, noteable: merge_request, project: project, author: user),
      create(:diff_note_on_merge_request, noteable: merge_request, project: project, author: user),
      create(:legacy_diff_note_on_merge_request, noteable: merge_request, project: project, author: user),
      create(:image_diff_note_on_merge_request, noteable: merge_request, project: project, author: user)
    ]
  end

  let(:params) { { project_id: project.id.to_s, merge_request_iid: merge_request.iid } }
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

    it 'exposes the built query as the GraphQL operation for version 0.1.0' do
      expect(tool.graphql_operation).to eq(described_class.build_query)
    end
  end

  describe '#build_variables' do
    it 'resolves the project full path and merge request iid', :aggregate_failures do
      variables = tool.build_variables

      expect(variables[:fullPath]).to eq(project.full_path)
      expect(variables[:iid]).to eq(merge_request.iid.to_s)
    end

    it 'defaults every include facet to false when include is omitted', :aggregate_failures do
      variables = tool.build_variables

      expect(variables[:includeDiffs]).to be(false)
      expect(variables[:includeCommits]).to be(false)
      expect(variables[:includeNotes]).to be(false)
      expect(variables[:includePipelines]).to be(false)
      expect(variables[:includeDiscussions]).to be(false)
    end

    it 'omits notes pagination parameters when not provided', :aggregate_failures do
      variables = tool.build_variables

      expect(variables).not_to have_key(:notesAfter)
      expect(variables).not_to have_key(:notesFirst)
    end

    context 'when a single facet is requested' do
      using RSpec::Parameterized::TableSyntax

      where(:facet, :enabled_key) do
        'diffs'       | :includeDiffs
        'commits'     | :includeCommits
        'notes'       | :includeNotes
        'pipelines'   | :includePipelines
        'discussions' | :includeDiscussions
      end

      with_them do
        let(:params) { super().merge(include: [facet]) }

        it 'enables only the requested facet', :aggregate_failures do
          variables = tool.build_variables
          all_keys = %i[includeDiffs includeCommits includeNotes includePipelines includeDiscussions]

          expect(variables[enabled_key]).to be(true)
          (all_keys - [enabled_key]).each { |key| expect(variables[key]).to be(false) }
        end
      end
    end

    context 'when diffs are requested without detail' do
      let(:params) { super().merge(include: ['diffs']) }

      it 'includes the diff summary and per-file breakdown but not patch text', :aggregate_failures do
        variables = tool.build_variables

        expect(variables[:includeDiffs]).to be(true)
        expect(variables[:includeDiffFiles]).to be(true)
        expect(variables[:includeDiffPatches]).to be(false)
      end
    end

    context 'when diffs are requested with detail none' do
      let(:params) { super().merge(include: ['diffs'], detail: 'none') }

      it 'includes the diff summary but not the per-file breakdown', :aggregate_failures do
        variables = tool.build_variables

        expect(variables[:includeDiffs]).to be(true)
        expect(variables[:includeDiffFiles]).to be(false)
        expect(variables[:includeDiffPatches]).to be(false)
      end
    end

    context 'when diffs are requested with detail stats' do
      let(:params) { super().merge(include: ['diffs'], detail: 'stats') }

      it 'includes both the diff summary and the per-file breakdown', :aggregate_failures do
        variables = tool.build_variables

        expect(variables[:includeDiffs]).to be(true)
        expect(variables[:includeDiffFiles]).to be(true)
        expect(variables[:includeDiffPatches]).to be(false)
      end
    end

    context 'when diffs are requested with detail full_patch' do
      let(:params) { super().merge(include: ['diffs'], detail: 'full_patch') }

      it 'includes the summary, per-file breakdown, and patch text', :aggregate_failures do
        variables = tool.build_variables

        expect(variables[:includeDiffs]).to be(true)
        expect(variables[:includeDiffFiles]).to be(true)
        expect(variables[:includeDiffPatches]).to be(true)
      end
    end

    context 'when detail full_patch is set but diffs are not included' do
      let(:params) { super().merge(detail: 'full_patch') }

      it 'does not enable patch text or the per-file breakdown', :aggregate_failures do
        variables = tool.build_variables

        expect(variables[:includeDiffFiles]).to be(false)
        expect(variables[:includeDiffPatches]).to be(false)
      end
    end

    context 'when notes pagination parameters are provided' do
      let(:params) { super().merge(include: ['notes'], notes_after: 'cursor1', notes_first: 25) }

      it 'includes them in the GraphQL variables', :aggregate_failures do
        variables = tool.build_variables

        expect(variables[:notesAfter]).to eq('cursor1')
        expect(variables[:notesFirst]).to eq(25)
      end
    end

    context 'when diffs pagination parameters are provided' do
      let(:params) { super().merge(include: ['diffs'], detail: 'full_patch', diffs_after: 'cursor2', diffs_first: 10) }

      it 'includes them in the GraphQL variables', :aggregate_failures do
        variables = tool.build_variables

        expect(variables[:diffsAfter]).to eq('cursor2')
        expect(variables[:diffsFirst]).to eq(10)
      end
    end
  end

  describe 'integration' do
    it 'executes the query with the resolved variables' do
      allow(GitlabSchema).to receive(:execute).and_call_original

      tool.execute

      expect(GitlabSchema).to have_received(:execute).with(
        anything,
        variables: hash_including(
          fullPath: project.full_path,
          iid: merge_request.iid.to_s
        ),
        context: hash_including(current_user: user)
      )
    end

    it 'returns the base merge request without any facets by default', :aggregate_failures do
      result = tool.execute

      expect(result[:isError]).to be(false)
      expect(result[:content].first[:type]).to eq('text')
      expect(result[:structuredContent]).to include('iid' => merge_request.iid.to_s)
      expect(result[:structuredContent]).not_to have_key('notes')
      expect(result[:structuredContent]).not_to have_key('commits')
      expect(result[:structuredContent]).not_to have_key('diffStatsSummary')
    end

    context 'when notes are requested' do
      let(:params) { super().merge(include: ['notes']) }

      it 'includes every note type on the merge request', :aggregate_failures do
        result = tool.execute

        expect(result[:isError]).to be(false)
        expect(result[:structuredContent]['notes']).to have_key('nodes')

        returned_ids = result[:structuredContent]['notes']['nodes'].map { |n| n['id'] }
        expect(returned_ids).to include(*all_notes.map { |n| n.to_global_id.to_s })
      end
    end

    context 'when diffs are requested' do
      let(:params) { super().merge(include: ['diffs']) }

      it 'includes the diff summary and per-file stats', :aggregate_failures do
        result = tool.execute

        expect(result[:isError]).to be(false)
        expect(result[:structuredContent]['diffStatsSummary']).to have_key('fileCount')
        expect(result[:structuredContent]['diffStats']).to be_an(Array)
      end
    end

    context 'when diffs are requested with detail full_patch' do
      let(:params) { super().merge(include: ['diffs'], detail: 'full_patch') }

      it 'includes per-file patch text', :aggregate_failures do
        result = tool.execute

        expect(result[:isError]).to be(false)
        nodes = result[:structuredContent].dig('diffs', 'nodes')

        expect(nodes).to be_an(Array)
        expect(nodes.first).to have_key('diff')
        expect(nodes.map { |node| node['diff'] }.join).to include('@@')
        expect(result[:structuredContent].dig('diffs', 'pageInfo')).to have_key('hasNextPage')
      end
    end

    context 'when the merge request does not exist' do
      let(:params) { { project_id: project.id.to_s, merge_request_iid: non_existing_record_iid } }

      it 'returns a merge-request-not-found error', :aggregate_failures do
        result = tool.execute

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('Merge request not found')
      end
    end

    context 'when the project in the URL does not exist' do
      let(:params) do
        { url: Gitlab::UrlBuilder.build(merge_request).sub(project.full_path, 'no-such-group/no-such-project') }
      end

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
      let(:params) { { project_id: non_existing_record_id.to_s, merge_request_iid: merge_request.iid } }

      it 'raises before executing GraphQL' do
        expect { tool.execute }.to raise_error(StandardError, /not found or inaccessible/)
      end
    end

    context 'with a merge request URL' do
      let(:params) { { url: Gitlab::UrlBuilder.build(merge_request) } }

      it 'resolves the merge request from the URL', :aggregate_failures do
        variables = tool.build_variables

        expect(variables[:fullPath]).to eq(project.full_path)
        expect(variables[:iid]).to eq(merge_request.iid.to_s)
      end
    end

    context 'with an invalid merge request URL' do
      let(:params) { { url: 'https://gitlab.com/not-a-real-path' } }

      it 'raises an ArgumentError' do
        expect { tool.build_variables }.to raise_error(ArgumentError, /Invalid merge request URL/)
      end
    end

    context 'when merge_request_iid is provided without project_id' do
      let(:params) { { merge_request_iid: merge_request.iid } }

      it 'raises an ArgumentError' do
        expect { tool.build_variables }.to raise_error(ArgumentError, /Provide either url/)
      end
    end
  end
end
