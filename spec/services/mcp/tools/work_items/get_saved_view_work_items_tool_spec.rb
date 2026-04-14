# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::WorkItems::GetSavedViewWorkItemsTool, feature_category: :mcp_server do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :public, group: group) }

  let(:params) { { group_id: group.id.to_s, filters: {}, sort: nil } }
  let(:tool) { described_class.new(current_user: user, params: params) }

  before_all do
    group.add_developer(user)
  end

  describe 'class methods' do
    describe '.build_query' do
      it 'returns the work items GraphQL query string' do
        query = described_class.build_query

        expect(query).to include('query GetWorkItemsFull')
        expect(query).to include('$fullPath: ID!')
        expect(query).to include('namespace(fullPath: $fullPath)')
        expect(query).to include('workItems(')
      end

      it 'includes pagination fields' do
        query = described_class.build_query

        pagination_fields = %w[pageInfo hasNextPage hasPreviousPage startCursor endCursor]
        pagination_fields.each { |field| expect(query).to include(field) }
      end

      it 'includes work item fields' do
        query = described_class.build_query

        work_item_fields = %w[nodes id iid title state webUrl workItemType]
        work_item_fields.each { |field| expect(query).to include(field) }
      end

      it 'includes filter variables' do
        query = described_class.build_query

        expect(query).to include('$sort: WorkItemSort')
        expect(query).to include('$state: IssuableState')
        expect(query).to include('$search: String')
        expect(query).to include('$in: [IssuableSearchableField!]')
        expect(query).to include('$assigneeUsernames: [String!]')
        expect(query).to include('$labelName: [String!]')
        expect(query).to include('$milestoneTitle: [String!]')
        expect(query).to include('$authorUsername: String')
        expect(query).to include('$types: [IssueType!]')
        expect(query).to include('$hierarchyFilters: HierarchyFilterInput')
      end

      it 'includes widget fragments' do
        query = described_class.build_query

        expect(query).to include('WorkItemWidgetAssignees')
        expect(query).to include('WorkItemWidgetLabels')
        expect(query).to include('WorkItemWidgetMilestone')
        expect(query).to include('WorkItemWidgetStartAndDueDate')
        expect(query).to include('WorkItemWidgetHierarchy')
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

      expect(operation).to include('query GetWorkItemsFull')
      expect(operation).to include('namespace(fullPath: $fullPath)')
    end
  end

  describe '#build_variables' do
    let(:full_path) { group.full_path }

    context 'with empty filters' do
      it 'returns base variables with pagination defaults' do
        variables = tool.build_variables

        expect(variables[:fullPath]).to eq(full_path)
        expect(variables[:firstPageSize]).to eq(20)
        expect(variables[:includeDescendants]).to be(true)
        expect(variables[:excludeProjects]).to be(false)
        expect(variables[:excludeGroupWorkItems]).to be(false)
        expect(variables).not_to have_key(:sort)
      end
    end

    context 'with filters from saved view' do
      let(:params) do
        {
          group_id: group.id.to_s,
          filters: {
            'labelName' => %w[bug critical],
            'assigneeUsernames' => ['testuser'],
            'state' => 'opened',
            'confidential' => true
          },
          sort: 'CREATED_DESC'
        }
      end

      it 'maps filters to GraphQL variables' do
        variables = tool.build_variables

        expect(variables[:labelName]).to eq(%w[bug critical])
        expect(variables[:assigneeUsernames]).to eq(['testuser'])
        expect(variables[:state]).to eq('opened')
        expect(variables[:confidential]).to be(true)
        expect(variables[:sort]).to eq('CREATED_DESC')
      end
    end

    context 'with search and in filters' do
      let(:params) do
        {
          group_id: group.id.to_s,
          filters: {
            'search' => 'fix login',
            'in' => %w[TITLE DESCRIPTION]
          },
          sort: nil
        }
      end

      it 'maps search and in filters to GraphQL variables' do
        variables = tool.build_variables

        expect(variables[:search]).to eq('fix login')
        expect(variables[:in]).to eq(%w[TITLE DESCRIPTION])
      end
    end

    context 'with hierarchyFilters' do
      let(:params) do
        {
          group_id: group.id.to_s,
          filters: {
            'hierarchyFilters' => {
              'parentIds' => ['gid://gitlab/WorkItem/100'],
              'includeDescendantWorkItems' => true
            }
          },
          sort: nil
        }
      end

      it 'maps hierarchyFilters to GraphQL variables' do
        variables = tool.build_variables

        expect(variables[:hierarchyFilters]).to eq({
          'parentIds' => ['gid://gitlab/WorkItem/100'],
          'includeDescendantWorkItems' => true
        })
      end
    end

    context 'with fullPath filter' do
      let_it_be(:subgroup) { create(:group, parent: group) }

      let(:params) do
        {
          group_id: group.id.to_s,
          filters: {
            'fullPath' => subgroup.full_path,
            'state' => 'opened'
          },
          sort: nil
        }
      end

      it 'overrides the namespace fullPath variable' do
        variables = tool.build_variables

        expect(variables[:fullPath]).to eq(subgroup.full_path)
      end

      it 'does not report fullPath as unsupported' do
        tool.build_variables

        expect(tool.unsupported_filters).not_to include('fullPath')
      end
    end

    context 'with unsupported filters' do
      let(:params) do
        {
          group_id: group.id.to_s,
          filters: {
            'labelName' => ['bug'],
            'healthStatusFilter' => 'onTrack',
            'iterationId' => ['gid://gitlab/Iteration/1']
          },
          sort: nil
        }
      end

      it 'detects unsupported filters' do
        tool.build_variables

        expect(tool.unsupported_filters).to contain_exactly('healthStatusFilter', 'iterationId')
      end

      it 'still maps supported filters correctly' do
        variables = tool.build_variables

        expect(variables[:labelName]).to eq(['bug'])
      end
    end

    context 'with only supported filters' do
      let(:params) do
        {
          group_id: group.id.to_s,
          filters: {
            'labelName' => ['bug'],
            'state' => 'opened'
          },
          sort: nil
        }
      end

      it 'reports no unsupported filters' do
        tool.build_variables

        expect(tool.unsupported_filters).to be_empty
      end
    end

    context 'with pagination params' do
      let(:params) do
        {
          group_id: group.id.to_s,
          filters: {},
          sort: nil,
          first: 50,
          after: 'cursor123'
        }
      end

      it 'includes pagination parameters' do
        variables = tool.build_variables

        expect(variables[:firstPageSize]).to eq(50)
        expect(variables[:afterCursor]).to eq('cursor123')
      end
    end
  end

  describe 'integration', :aggregate_failures do
    let_it_be(:work_item) { create(:work_item, :issue, project: project) }

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

    context 'when namespace returns no data' do
      before do
        allow(GitlabSchema).to receive(:execute).and_return(
          { 'data' => { 'namespace' => nil } }
        )
      end

      it 'returns error response' do
        result = tool.execute

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('Operation returned no data')
      end
    end

    context 'when namespace data has no workItems key' do
      before do
        allow(GitlabSchema).to receive(:execute).and_return(
          { 'data' => { 'namespace' => { 'id' => 'gid://gitlab/Group/1', 'name' => group.name } } }
        )
      end

      it 'returns error response about inaccessible work items' do
        result = tool.execute

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('The work items are inaccessible')
      end
    end

    it 'executes query with correct variables and defaults' do
      allow(GitlabSchema).to receive(:execute).and_call_original

      tool.execute

      expect(GitlabSchema).to have_received(:execute).with(
        a_string_including('GetWorkItemsFull'),
        variables: hash_including(
          fullPath: group.full_path,
          includeDescendants: true,
          excludeProjects: false,
          excludeGroupWorkItems: false,
          firstPageSize: 20
        ),
        context: hash_including(current_user: user)
      )
    end

    it 'returns work items data with proper formatting' do
      result = tool.execute

      expect(result[:isError]).to be(false)
      expect(result[:content]).to be_an(Array)
      expect(result[:content].first[:type]).to eq('text')
      expect(result[:structuredContent]).to be_a(Hash)
      expect(result[:structuredContent]).to have_key('pageInfo')
      expect(result[:structuredContent]).to have_key('nodes')
    end

    it 'returns work items in the namespace' do
      result = tool.execute

      iids = result[:structuredContent]['nodes'].pluck('iid')
      expect(iids).to include(work_item.iid.to_s)
    end

    context 'with filters applied' do
      let_it_be(:label) { create(:group_label, group: group, title: 'bug') }
      let_it_be(:labeled_item) do
        create(:work_item, :issue, project: project).tap do |wi|
          create(:label_link, label: label, target: wi)
        end
      end

      let(:params) do
        {
          group_id: group.id.to_s,
          filters: { 'labelName' => ['bug'] },
          sort: nil
        }
      end

      it 'passes filters to the GraphQL query' do
        allow(GitlabSchema).to receive(:execute).and_call_original

        tool.execute

        expect(GitlabSchema).to have_received(:execute).with(
          a_string_including('GetWorkItemsFull'),
          variables: hash_including(
            labelName: ['bug']
          ),
          context: anything
        )
      end

      it 'returns only matching work items' do
        result = tool.execute

        iids = result[:structuredContent]['nodes'].pluck('iid')
        expect(iids).to include(labeled_item.iid.to_s)
      end
    end

    context 'with pagination parameters' do
      let(:params) do
        {
          group_id: group.id.to_s,
          filters: {},
          sort: nil,
          first: 5
        }
      end

      it 'forwards pagination params to the query' do
        allow(GitlabSchema).to receive(:execute).and_call_original

        tool.execute

        expect(GitlabSchema).to have_received(:execute).with(
          a_string_including('GetWorkItemsFull'),
          variables: hash_including(firstPageSize: 5),
          context: anything
        )
      end

      it 'includes pageInfo in the response' do
        result = tool.execute

        page_info = result[:structuredContent]['pageInfo']
        expect(page_info).to include(
          'hasNextPage', 'hasPreviousPage',
          'startCursor', 'endCursor'
        )
      end
    end
  end
end
