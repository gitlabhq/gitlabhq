# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::Labels::SearchTool, feature_category: :mcp_server do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:label) { create(:label, project: project, title: 'label') }
  let(:params) { { full_path: project.full_path, is_project: true, search: 'label' } }
  let(:tool) { described_class.new(current_user: user, params: params) }

  before_all do
    project.add_developer(user)
    group.add_developer(user)
  end

  describe 'class methods' do
    describe '.build_query' do
      it 'returns the GraphQL query string' do
        query = described_class.build_query

        expect(query).to include('query searchLabels')
        expect(query).to include('searchTerm: $search')
        expect(query).to include('labels')
        expect(query).to include('$fullPath: ID!')
        expect(query).to include('searchTerm: $search')
      end

      it 'includes label fields' do
        query = described_class.build_query

        expect(query).to include('nodes')
        expect(query).to include('id')
        expect(query).to include('title')
      end
    end
  end

  describe 'versioning' do
    it 'registers version 0.1.0' do
      expect(tool.version).to eq(Mcp::Tools::Concerns::Constants::VERSIONS[:v0_1_0])
    end

    it 'has correct operation name for version 0.1.0' do
      expect(tool.operation_name).to eq('project')
    end

    it 'has correct GraphQL operation for version 0.1.0' do
      operation = tool.graphql_operation

      expect(operation).to include('query searchLabels')
    end

    context 'when we are searching group labels' do
      let(:params) { { full_path: group.full_path, is_project: false, search: 'label' } }

      it 'has correct operation name for version 0.1.0' do
        expect(tool.operation_name).to eq('group')
      end
    end
  end

  describe '#build_variables' do
    it 'builds variables from params' do
      variables = tool.build_variables

      expect(variables[:fullPath]).to eq(project.full_path)
      expect(variables[:search]).to eq('label')
      expect(variables[:isProject]).to be(true)
    end
  end

  describe '#process_result' do
    context 'when result contains errors with string key' do
      let(:result) do
        {
          'errors' => ['Some error occurred'],
          'data' => { 'project' => { 'labels' => [] } }
        }
      end

      it 'returns the result without processing' do
        allow(tool).to receive(:process_result).and_call_original
        processed = tool.send(:process_result, result)

        expect(processed[:isError]).to be(true)
        expect(processed[:content]).to be_an(Array)
        expect(processed[:content].first[:text]).to eq('Some error occurred')
      end
    end

    context 'when result has no structured content' do
      let(:result) { {} }

      it 'returns the result without processing' do
        allow(tool).to receive(:process_result).and_call_original
        processed = tool.send(:process_result, result)

        expect(processed[:isError]).to be(true)
        expect(processed[:content]).to be_an(Array)
        expect(processed[:content].first[:text]).to eq('Operation returned no data')
      end
    end

    context 'when no labels are found' do
      let(:result) do
        {
          'data' => { 'project' => { 'labels' => {} } }
        }
      end

      it 'returns error response' do
        allow(tool).to receive(:process_result).and_call_original
        processed = tool.send(:process_result, result)

        expect(processed[:isError]).to be(true)
        expect(processed[:content].first[:text]).to include('Operation returned no data')
      end

      context 'when we are passing group in params' do
        let(:params) { { full_path: group.full_path, is_project: false, search: 'label' } }
        let(:result) do
          {
            'data' => { 'group' => { 'labels' => {} } }
          }
        end

        it 'returns error response' do
          allow(tool).to receive(:process_result).and_call_original
          processed = tool.send(:process_result, result)

          expect(processed[:isError]).to be(true)
          expect(processed[:content].first[:text]).to include('Operation returned no data')
        end
      end
    end
  end

  describe '#extract_labels' do
    context 'when labels data is in the response' do
      let(:labels_data) do
        [{
          id: "gid://gitlab/ProjectLabel/159",
          title: "API"
        },
          {
            id: "gid://gitlab/ProjectLabel/140",
            title: "Premium-tier"
          }]
      end

      let(:structured_content) do
        {
          'labels' =>
            { 'nodes' => labels_data }
        }
      end

      it 'extracts labels' do
        result = tool.send(:extract_labels, structured_content)

        expect(result).to eq(labels_data)
      end
    end

    context 'when there are no labels' do
      let(:structured_content) do
        {
          'labels' => {}
        }
      end

      it 'returns nil' do
        result = tool.send(:extract_labels, structured_content)

        expect(result).to be_nil
      end
    end

    context 'when structured_content is nil' do
      it 'returns nil' do
        result = tool.send(:extract_labels, nil)

        expect(result).to be_nil
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
          fullPath: project.full_path
        ),
        context: hash_including(current_user: user)
      )
    end

    it 'returns labels data with proper formatting' do
      result = tool.execute

      expect(result[:isError]).to be(false)
      expect(result[:content]).to be_an(Array)
      expect(result[:content].first[:type]).to eq('text')
      expect(result[:structuredContent]).to be_a(Hash)
      expect(result[:structuredContent]).to have_key(:items)
      expect(result[:structuredContent][:items].first).to include('title' => 'label')
    end

    context 'when project does not exist' do
      let(:params) { { full_path: 'non_existing_project', is_project: true, search: 'test' } }

      it 'returns error' do
        result = tool.execute

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('Operation returned no data')
      end
    end

    context 'when we pass group in params' do
      let_it_be(:group_label) { create(:group_label, group: group, title: 'test') }
      let(:params) { { full_path: group.full_path, is_project: false, search: 'test' } }

      it 'executes query with correct variables' do
        allow(GitlabSchema).to receive(:execute).and_call_original

        tool.execute

        expect(GitlabSchema).to have_received(:execute).with(
          anything,
          variables: hash_including(
            fullPath: group.full_path,
            isProject: false
          ),
          context: hash_including(current_user: user)
        )
      end

      it 'returns labels data with proper formatting' do
        result = tool.execute

        expect(result[:isError]).to be(false)
        expect(result[:content]).to be_an(Array)
        expect(result[:content].first[:type]).to eq('text')
        expect(result[:structuredContent]).to be_a(Hash)
        expect(result[:structuredContent]).to have_key(:items)
        expect(result[:structuredContent][:items].first).to include('title' => 'test')
      end

      context 'when project does not exist' do
        let(:params) { { full_path: 'non_existing_group', is_project: false, search: 'test' } }

        it 'returns error' do
          result = tool.execute

          expect(result[:isError]).to be(true)
          expect(result[:content].first[:text]).to include('Operation returned no data')
        end
      end
    end
  end
end
