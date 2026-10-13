# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::Labels::SearchTool, feature_category: :mcp_server do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:label) { create(:label, project: project, title: 'label') }
  let(:params) { { full_path: project.full_path, is_project: true, search: 'label' } }
  let(:tool) { described_class.new(current_user: user, params: params, version: '0.1.0') }

  before_all do
    project.add_developer(user)
    group.add_developer(user)
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

      expect(operation).to include('query mcpSearchLabels')
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

      it 'returns a project not found error' do
        allow(tool).to receive(:process_result).and_call_original
        processed = tool.send(:process_result, result)

        expect(processed[:isError]).to be(true)
        expect(processed[:content]).to be_an(Array)
        expect(processed[:content].first[:text]).to include(
          "Project '#{project.full_path}' not found or inaccessible"
        )
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

  describe '#resource_not_found_error' do
    context 'when searching a project' do
      it 'returns an error mentioning the project path' do
        error = tool.send(:resource_not_found_error)

        expect(error[:isError]).to be(true)
        expect(error[:content].first[:text]).to eq(
          "Project '#{project.full_path}' not found or inaccessible"
        )
      end
    end

    context 'when searching a group' do
      let(:params) { { full_path: group.full_path, is_project: false, search: 'label' } }

      it 'returns an error mentioning the group path' do
        error = tool.send(:resource_not_found_error)

        expect(error[:isError]).to be(true)
        expect(error[:content].first[:text]).to eq(
          "Group '#{group.full_path}' not found or inaccessible"
        )
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
      expect(result[:structuredContent][:items].first.keys).to match_array(%w[id title])
      expect(result[:structuredContent][:items].first).to include('title' => 'label')
    end

    context 'when project does not exist' do
      let(:params) { { full_path: 'non_existing_project', is_project: true, search: 'test' } }

      it 'returns a project not found error with the path', :aggregate_failures do
        result = tool.execute

        expect(result[:isError]).to be(true)
        expect(result[:reason]).to eq(:not_found)
        expect(result[:content].first[:text]).to include(
          "Project 'non_existing_project' not found or inaccessible"
        )
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

      context 'when group does not exist' do
        let(:params) { { full_path: 'non_existing_group', is_project: false, search: 'test' } }

        it 'returns a group not found error with the path' do
          result = tool.execute

          expect(result[:isError]).to be(true)
          expect(result[:content].first[:text]).to include(
            "Group 'non_existing_group' not found or inaccessible"
          )
        end
      end
    end
  end

  describe 'version 0.2.0' do
    let_it_be(:second_label) { create(:label, project: project, title: 'backend') }
    let_it_be(:overlapping_label) { create(:label, project: project, title: 'backend-label') }
    let(:params) { { full_path: project.full_path, is_project: true, search: %w[label backend] } }
    let(:tool) { described_class.new(current_user: user, params: params, version: '0.2.0') }

    it 'executes each term with the version 0.2.0 operation' do
      allow(GitlabSchema).to receive(:execute).and_call_original

      tool.execute

      expect(GitlabSchema).to have_received(:execute).with(
        a_string_including('query mcpSearchLabelsV020'),
        any_args
      ).twice
    end

    it 'returns matching labels once each in one flat response' do
      result = tool.execute

      expect(result[:isError]).to be(false)
      expected_labels = [label, second_label, overlapping_label].map do |item|
        a_hash_including('id' => item.to_global_id.to_s, 'title' => item.title)
      end

      expect(result[:structuredContent][:items]).to match_array(expected_labels)
      expect(Gitlab::Json::SafeParser.parse(result[:content].first[:text])).to match_array(
        result[:structuredContent][:items]
      )
    end

    it 'runs a repeated term only once' do
      allow(GitlabSchema).to receive(:execute).and_call_original
      duplicate_params = params.merge(search: %w[label label])

      result = described_class.new(current_user: user, params: duplicate_params, version: '0.2.0').execute

      expect(result[:isError]).to be(false)
      expect(GitlabSchema).to have_received(:execute).once
    end

    context 'with one search term' do
      let(:params) { { full_path: project.full_path, is_project: true, search: ['label'] } }

      it 'returns the same labels as the scalar version' do
        old_result = described_class.new(
          current_user: user, params: params.merge(search: 'label'), version: '0.1.0'
        ).execute

        expect(tool.execute).to eq(old_result)
      end
    end

    context 'when the group is inaccessible' do
      let(:params) { { full_path: 'non_existing_group', is_project: false, search: %w[label backend] } }

      it 'returns an error instead of partial results' do
        result = tool.execute

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include("Group 'non_existing_group' not found or inaccessible")
      end
    end

    context 'when a project is private' do
      let_it_be(:private_project) { create(:project, :private) }
      let_it_be(:private_label) { create(:label, project: private_project, title: 'private-label') }
      let(:params) { { full_path: private_project.full_path, is_project: true, search: %w[private label] } }

      it 'does not expose labels to non-members' do
        result = tool.execute

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).not_to include(private_label.title)
      end
    end

    context 'when a later search fails' do
      before do
        allow(GitlabSchema).to receive(:execute).and_wrap_original do |original, *args, **kwargs|
          if kwargs[:variables][:search] == 'backend'
            { 'errors' => [{ 'message' => 'Search failed' }] }
          else
            original.call(*args, **kwargs)
          end
        end
      end

      it 'returns the error without earlier matches' do
        result = tool.execute

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to eq('Search failed')
        expect(result[:structuredContent]).to eq({})
      end
    end
  end
end
