# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::WorkItems::GetWorkItemNotesTool, feature_category: :mcp_server do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:work_item) { create(:work_item, :issue, project: project, iid: 42) }
  let_it_be(:note1) { create(:note, noteable: work_item, project: project, author: user, note: 'First comment') }
  let_it_be(:note2) { create(:note, noteable: work_item, project: project, author: user, note: 'Second comment') }

  let(:params) { { project_id: project.id.to_s, work_item_iid: work_item.iid } }
  let(:tool) { described_class.new(current_user: user, params: params) }

  before_all do
    project.add_developer(user)
  end

  describe 'class methods' do
    describe '.build_query' do
      it 'returns the GraphQL query string' do
        query = described_class.build_query

        expect(query).to include('query GetWorkItemNotes')
        expect(query).to include('$id: WorkItemID!')
        expect(query).to include('$after: String')
        expect(query).to include('$before: String')
        expect(query).to include('$first: Int')
        expect(query).to include('$last: Int')
        expect(query).to include('workItem(id: $id)')
        expect(query).to include('widgets')
        expect(query).to include('WorkItemWidgetNotes')
        expect(query).to include('notes(')
      end

      it 'includes count field' do
        query = described_class.build_query

        expect(query).to include('count')
      end

      it 'includes pagination fields' do
        query = described_class.build_query

        expect(query).to include('pageInfo')
        expect(query).to include('hasNextPage')
        expect(query).to include('hasPreviousPage')
        expect(query).to include('startCursor')
        expect(query).to include('endCursor')
      end

      it 'includes note fields' do
        query = described_class.build_query

        expect(query).to include('nodes')
        expect(query).to include('id')
        expect(query).to include('body')
        expect(query).to include('internal')
        expect(query).to include('createdAt')
        expect(query).to include('updatedAt')
        expect(query).to include('system')
        expect(query).to include('systemNoteIconName')
      end

      it 'includes author fields' do
        query = described_class.build_query

        expect(query).to include('author')
        expect(query).to include('name')
        expect(query).to include('username')
        expect(query).to include('avatarUrl')
        expect(query).to include('webUrl')
      end

      it 'includes discussion field' do
        query = described_class.build_query

        expect(query).to include('discussion')
      end
    end
  end

  describe 'versioning' do
    it 'registers version 0.1.0' do
      expect(tool.version).to eq(Mcp::Tools::Concerns::Constants::VERSIONS[:v0_1_0])
    end

    it 'has correct operation name for version 0.1.0' do
      expect(tool.operation_name).to eq('workItem')
    end

    it 'has correct GraphQL operation for version 0.1.0' do
      operation = tool.graphql_operation

      expect(operation).to include('query GetWorkItemNotes')
      expect(operation).to include('workItem(id: $id)')
    end
  end

  describe '#build_variables' do
    before do
      allow(tool).to receive(:resolve_work_item_id).and_return(work_item.to_global_id.to_s)
    end

    it 'builds variables with work item ID' do
      variables = tool.build_variables

      expect(variables[:id]).to eq(work_item.to_global_id.to_s)
      expect(tool).to have_received(:resolve_work_item_id)
    end

    it 'omits pagination parameters when not provided' do
      variables = tool.build_variables

      expect(variables).not_to have_key(:after)
      expect(variables).not_to have_key(:before)
      expect(variables).not_to have_key(:first)
      expect(variables).not_to have_key(:last)
    end

    it 'includes after parameter when provided' do
      params[:after] = 'cursor123'
      variables = tool.build_variables

      expect(variables[:after]).to eq('cursor123')
    end

    it 'includes before parameter when provided' do
      params[:before] = 'cursor456'
      variables = tool.build_variables

      expect(variables[:before]).to eq('cursor456')
    end

    it 'includes first parameter when provided' do
      params[:first] = 20
      variables = tool.build_variables

      expect(variables[:first]).to eq(20)
    end

    it 'includes last parameter when provided' do
      params[:last] = 10
      variables = tool.build_variables

      expect(variables[:last]).to eq(10)
    end

    it 'includes all pagination parameters when provided' do
      params[:after] = 'cursor1'
      params[:first] = 25
      variables = tool.build_variables

      expect(variables[:after]).to eq('cursor1')
      expect(variables[:first]).to eq(25)
    end
  end

  describe '#process_result' do
    let(:notes_data) do
      {
        'count' => 2,
        'pageInfo' => {
          'hasNextPage' => false,
          'hasPreviousPage' => false,
          'startCursor' => 'cursor1',
          'endCursor' => 'cursor2'
        },
        'nodes' => [
          {
            'id' => 'gid://gitlab/Note/1',
            'body' => 'First comment',
            'internal' => false,
            'createdAt' => '2024-01-01T00:00:00Z',
            'author' => {
              'id' => 'gid://gitlab/User/1',
              'name' => 'Test User',
              'username' => 'testuser'
            }
          },
          {
            'id' => 'gid://gitlab/Note/2',
            'body' => 'Second comment',
            'internal' => false,
            'createdAt' => '2024-01-02T00:00:00Z',
            'author' => {
              'id' => 'gid://gitlab/User/1',
              'name' => 'Test User',
              'username' => 'testuser'
            }
          }
        ]
      }
    end

    context 'when result contains errors with string key' do
      let(:result) do
        {
          'errors' => ['Some error occurred'],
          'data' => { 'workItem' => { 'widgets' => [] } }
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

    context 'when no notes are found' do
      let(:result) do
        {
          'data' => { 'workItem' => { 'widgets' => [] } }
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

  describe '#extract_notes' do
    context 'when widgets contain notes with count' do
      let(:notes_data) do
        {
          'count' => 5,
          'pageInfo' => { 'hasNextPage' => false },
          'nodes' => [{ 'id' => 'gid://gitlab/Note/1', 'body' => 'Test note' }]
        }
      end

      let(:structured_content) do
        {
          'widgets' => [
            { 'type' => 'DESCRIPTION' },
            { 'notes' => notes_data },
            { 'type' => 'ASSIGNEES' }
          ]
        }
      end

      it 'extracts notes with count from widgets array' do
        result = tool.send(:extract_notes, structured_content)

        expect(result).to eq(notes_data)
        expect(result['count']).to eq(5)
      end
    end

    context 'when widgets do not contain notes' do
      let(:structured_content) do
        {
          'widgets' => [
            { 'type' => 'DESCRIPTION' },
            { 'type' => 'ASSIGNEES' }
          ]
        }
      end

      it 'returns nil' do
        result = tool.send(:extract_notes, structured_content)

        expect(result).to be_nil
      end
    end

    context 'when widgets is nil' do
      let(:structured_content) { { 'widgets' => nil } }

      it 'returns nil' do
        result = tool.send(:extract_notes, structured_content)

        expect(result).to be_nil
      end
    end

    context 'when structured_content is nil' do
      it 'returns nil' do
        result = tool.send(:extract_notes, nil)

        expect(result).to be_nil
      end
    end

    context 'when widgets is empty array' do
      let(:structured_content) { { 'widgets' => [] } }

      it 'returns nil' do
        result = tool.send(:extract_notes, structured_content)

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
          id: work_item.to_global_id.to_s
        ),
        context: hash_including(current_user: user)
      )
    end

    it 'returns notes data with proper formatting including count' do
      result = tool.execute

      expect(result[:isError]).to be(false)
      expect(result[:content]).to be_an(Array)
      expect(result[:content].first[:type]).to eq('text')
      expect(result[:structuredContent]).to be_a(Hash)
      expect(result[:structuredContent]).to have_key('count')
      expect(result[:structuredContent]).to have_key('pageInfo')
      expect(result[:structuredContent]).to have_key('nodes')
    end

    context 'with pagination parameters' do
      let(:params) do
        {
          project_id: project.id.to_s,
          work_item_iid: work_item.iid,
          first: 10,
          after: 'cursor123'
        }
      end

      it 'includes pagination parameters in variables' do
        allow(GitlabSchema).to receive(:execute).and_call_original

        tool.execute

        expect(GitlabSchema).to have_received(:execute).with(
          anything,
          variables: hash_including(
            first: 10,
            after: 'cursor123'
          ),
          context: anything
        )
      end
    end

    context 'when work item does not exist' do
      let(:params) { { project_id: project.id.to_s, work_item_iid: non_existing_record_iid } }

      it 'raises error before executing GraphQL' do
        expect { tool.execute }.to raise_error(ArgumentError, "Work item ##{non_existing_record_iid} not found")
      end
    end

    context 'when user lacks permission' do
      let_it_be(:private_project) { create(:project, :private) }
      let_it_be(:private_work_item) { create(:work_item, :issue, project: private_project, iid: 1) }
      let(:params) { { project_id: private_project.id.to_s, work_item_iid: private_work_item.iid } }

      it 'raises error before executing GraphQL' do
        expect { tool.execute }.to raise_error(ArgumentError, /Access denied to project/)
      end
    end
  end
end
