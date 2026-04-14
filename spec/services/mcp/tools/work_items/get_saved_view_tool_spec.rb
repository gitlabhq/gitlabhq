# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::WorkItems::GetSavedViewTool, feature_category: :mcp_server do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }

  let(:saved_view_id) { 'gid://gitlab/WorkItems::SavedViews::SavedView/1' }
  let(:params) { { group_id: group.id.to_s, saved_view_id: saved_view_id } }
  let(:tool) { described_class.new(current_user: user, params: params) }

  before_all do
    group.add_developer(user)
  end

  describe 'class methods' do
    describe '.build_query' do
      it 'returns the saved view GraphQL query string' do
        query = described_class.build_query

        expect(query).to include('query GetNamespaceSavedView')
        expect(query).to include('$fullPath: ID!')
        expect(query).to include('$id: WorkItemsSavedViewsSavedViewID!')
        expect(query).to include('namespace(fullPath: $fullPath)')
        expect(query).to include('savedViews(id: $id)')
      end

      it 'includes saved view fields' do
        query = described_class.build_query

        saved_view_fields = %w[name description filters sort]
        saved_view_fields.each { |field| expect(query).to include(field) }
      end
    end
  end

  describe 'versioning' do
    it 'registers version 0.1.0' do
      expect(tool.version).to eq(Mcp::Tools::Concerns::Constants::VERSIONS[:v0_1_0])
    end

    it 'has correct operation name for version 0.1.0' do
      expect(tool.operation_name).to eq('namespace')
    end

    it 'has correct GraphQL operation for version 0.1.0' do
      operation = tool.graphql_operation

      expect(operation).to include('query GetNamespaceSavedView')
      expect(operation).to include('namespace(fullPath: $fullPath)')
    end
  end

  describe '#build_variables' do
    it 'builds variables with full path and saved view ID' do
      variables = tool.build_variables

      expect(variables[:fullPath]).to eq(group.full_path)
      expect(variables[:id]).to eq(saved_view_id)
    end
  end

  describe 'integration', :aggregate_failures do
    let_it_be(:saved_view) do
      create(:saved_view,
        namespace: group,
        author: user,
        name: 'Open Bugs',
        description: 'All open bugs',
        filter_data: { state: 'opened' },
        sort: :created_desc
      )
    end

    let(:saved_view_gid) { saved_view.to_global_id.to_s }
    let(:params) { { group_id: group.id.to_s, saved_view_id: saved_view_gid } }

    it 'executes query with correct variables' do
      allow(GitlabSchema).to receive(:execute).and_call_original

      tool.execute

      expect(GitlabSchema).to have_received(:execute).with(
        a_string_including('GetNamespaceSavedView'),
        variables: hash_including(
          fullPath: group.full_path,
          id: saved_view_gid
        ),
        context: hash_including(current_user: user)
      )
    end

    it 'returns saved view data with proper formatting' do
      result = tool.execute

      expect(result[:isError]).to be(false)
      expect(result[:content]).to be_an(Array)
      expect(result[:content].first[:type]).to eq('text')
      expect(result[:structuredContent]).to be_a(Hash)
      expect(result[:structuredContent]['name']).to eq('Open Bugs')
      expect(result[:structuredContent]['description']).to eq('All open bugs')
      expect(result[:structuredContent]).to have_key('filters')
      expect(result[:structuredContent]).to have_key('sort')
    end

    context 'when saved view does not exist' do
      let(:params) do
        {
          group_id: group.id.to_s,
          saved_view_id: "gid://gitlab/WorkItems::SavedViews::SavedView/#{non_existing_record_id}"
        }
      end

      it 'returns error response' do
        result = tool.execute

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('Saved view not found or inaccessible')
      end
    end

    context 'when savedViews nodes is nil' do
      before do
        allow(GitlabSchema).to receive(:execute).and_return(
          { 'data' => { 'namespace' => { 'id' => group.to_global_id.to_s, 'savedViews' => { 'nodes' => nil } } } }
        )
      end

      it 'returns error response' do
        result = tool.execute

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('Saved view not found or inaccessible')
      end
    end

    context 'when GraphQL returns errors' do
      before do
        allow(GitlabSchema).to receive(:execute).and_return(
          { 'errors' => [{ 'message' => 'Some error occurred' }] }
        )
      end

      it 'returns error response' do
        result = tool.execute

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('Some error occurred')
      end
    end
  end
end
