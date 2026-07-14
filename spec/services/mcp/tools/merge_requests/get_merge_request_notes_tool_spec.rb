# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::MergeRequests::GetMergeRequestNotesTool, feature_category: :mcp_server do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
  let_it_be(:note1) { create(:note_on_merge_request, noteable: merge_request, project: project, author: user) }
  let_it_be(:note2) { create(:note_on_merge_request, noteable: merge_request, project: project, author: user) }
  let_it_be(:resolved_discussion_note) do
    create(:discussion_note_on_merge_request, noteable: merge_request, project: project, author: user)
  end

  let_it_be(:system_note) do
    create(:system_note, noteable: merge_request, project: project, note: 'changed the description')
  end

  let(:params) { { project_id: project.id.to_s, merge_request_iid: merge_request.iid } }
  let(:tool) { described_class.new(current_user: user, params: params) }

  before_all do
    project.add_developer(user)
    resolved_discussion_note.discussion.resolve!(user)
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
    it 'builds variables with project full path and merge request iid', :aggregate_failures do
      variables = tool.build_variables

      expect(variables[:fullPath]).to eq(project.full_path)
      expect(variables[:iid]).to eq(merge_request.iid.to_s)
    end

    it 'omits pagination parameters when not provided', :aggregate_failures do
      variables = tool.build_variables

      expect(variables).not_to have_key(:after)
      expect(variables).not_to have_key(:before)
      expect(variables).not_to have_key(:first)
      expect(variables).not_to have_key(:last)
    end

    context 'when pagination parameters are provided' do
      let(:params) { super().merge(after: 'cursor1', first: 25) }

      it 'includes them in the GraphQL variables', :aggregate_failures do
        variables = tool.build_variables

        expect(variables[:after]).to eq('cursor1')
        expect(variables[:first]).to eq(25)
      end
    end
  end

  describe 'integration' do
    it 'executes query with correct variables' do
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

    it 'returns notes and resolution data shaped for agent consumption', :aggregate_failures do
      result = tool.execute

      expect(result[:isError]).to be(false)
      expect(result[:content].first[:type]).to eq('text')
      expect(result[:structuredContent]).to have_key('resolvedDiscussionsCount')
      expect(result[:structuredContent]).to have_key('resolvableDiscussionsCount')
      expect(result[:structuredContent]['notes']).to have_key('pageInfo')
      expect(result[:structuredContent]['notes']).to have_key('count')
      expect(result[:structuredContent]['notes']).to have_key('nodes')

      nodes = result[:structuredContent]['notes']['nodes']
      note = nodes.first

      expect(note.keys).to match_array(
        %w[id webUrl body system internal createdAt updatedAt author position discussion]
      )
      expect(note['discussion'].keys).to match_array(%w[id resolvable resolved resolvedBy])
      expect(note['webUrl']).to include("#note_#{note['id'].split('/').last}")

      resolved_note = nodes.find { |n| n.dig('discussion', 'resolved') }

      expect(resolved_note).not_to be_nil
      expect(resolved_note['discussion']['resolvedBy'].keys).to match_array(%w[id username name])
      expect(resolved_note['discussion']['resolvedBy']['username']).to eq(user.username)

      expect(nodes.map { |n| n['body'] }).to include('changed the description')
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

      it 'returns the notes connection', :aggregate_failures do
        result = tool.execute

        expect(result[:isError]).to be(false)
        expect(result[:structuredContent]['notes']).to have_key('nodes')
      end
    end

    context 'with a merge request URL in a nested subgroup' do
      let_it_be(:nested_group) { create(:group, :nested) }
      let_it_be(:nested_project) { create(:project, :public, group: nested_group) }
      let_it_be(:nested_merge_request) do
        create(:merge_request, source_project: nested_project, target_project: nested_project)
      end

      let(:params) { { url: Gitlab::UrlBuilder.build(nested_merge_request) } }

      before_all do
        nested_project.add_developer(user)
      end

      it 'resolves the full nested path from the URL', :aggregate_failures do
        variables = tool.build_variables

        expect(variables[:fullPath]).to eq(nested_project.full_path)
        expect(variables[:fullPath].count('/')).to be >= 2
        expect(variables[:iid]).to eq(nested_merge_request.iid.to_s)
      end

      it 'resolves the correct merge request' do
        result = tool.execute

        expect(result[:isError]).to be(false)
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

    context 'when project_id is provided without merge_request_iid' do
      let(:params) { { project_id: project.id.to_s } }

      it 'raises an ArgumentError' do
        expect { tool.build_variables }.to raise_error(ArgumentError, /Provide either url/)
      end
    end
  end
end
