# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::WorkItems::GraphqlGetSavedViewWorkItemsService, feature_category: :mcp_server do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :public, group: group) }

  let(:service) { described_class.new(name: 'get_saved_view_work_items') }
  let(:request) { instance_double(ActionDispatch::Request) }

  before_all do
    group.add_developer(user)
  end

  before do
    service.set_cred(current_user: user)
  end

  describe 'class configuration' do
    it 'inherits from GraphqlService' do
      expect(described_class.superclass).to eq(Mcp::Tools::GraphqlService)
    end

    it 'registers version 0.1.0' do
      expect(described_class.available_versions).to include('0.1.0')
    end

    it 'has correct description' do
      expect(service.description).to eq('Fetch a saved view and its work items list from a namespace')
    end
  end

  describe 'input schema' do
    let(:schema) { described_class.version_metadata('0.1.0')[:input_schema] }

    it 'defines object type schema' do
      expect(schema[:type]).to eq('object')
    end

    it 'requires saved_view_id' do
      expect(schema[:required]).to eq(['saved_view_id'])
    end

    context 'with namespace identification properties' do
      let(:properties) { schema[:properties] }

      where(:property_name, :property_type, :description_includes) do
        [
          [:url, 'string', 'GitLab URL for the namespace'],
          [:group_id, 'string', 'ID or path of the group'],
          [:project_id, 'string', 'ID or path of the project']
        ]
      end

      with_them do
        it 'defines property with correct type and description' do
          expect(properties[property_name][:type]).to eq(property_type)
          expect(properties[property_name][:description]).to include(description_includes)
        end
      end
    end

    context 'with saved view identification' do
      let(:properties) { schema[:properties] }

      it 'defines saved_view_id with correct type and description' do
        expect(properties[:saved_view_id][:type]).to eq('string')
        expect(properties[:saved_view_id][:description]).to include('global ID of the saved view')
      end
    end

    context 'with pagination properties' do
      let(:properties) { schema[:properties] }

      it 'defines after cursor' do
        expect(properties[:after][:type]).to eq('string')
        expect(properties[:after][:description]).to include('forward pagination')
      end

      it 'defines first with constraints' do
        expect(properties[:first][:type]).to eq('integer')
        expect(properties[:first][:minimum]).to eq(1)
        expect(properties[:first][:maximum]).to eq(100)
        expect(properties[:first][:description]).to include('forward pagination')
      end
    end

    it 'has readOnlyHint annotation' do
      annotations = described_class.version_metadata('0.1.0')[:annotations]
      expect(annotations[:readOnlyHint]).to be(true)
    end
  end

  describe '#graphql_tool_class' do
    it 'raises NotImplementedError since it orchestrates two tools' do
      expect { service.send(:graphql_tool_class) }.to raise_error(NotImplementedError)
    end
  end

  describe '#perform_0_1_0' do
    let(:saved_view_id) { 'gid://gitlab/WorkItems::SavedViews::SavedView/1' }
    let(:arguments) do
      {
        group_id: group.id.to_s,
        saved_view_id: saved_view_id
      }
    end

    let(:saved_view_data) do
      {
        'id' => saved_view_id,
        'name' => 'Open Bugs',
        'description' => 'All open bugs',
        'filters' => { 'labelName' => ['bug'], 'state' => 'opened' },
        'sort' => 'CREATED_DESC'
      }
    end

    let(:work_items_data) do
      {
        'pageInfo' => {
          'hasNextPage' => false,
          'hasPreviousPage' => false,
          'startCursor' => 'cursor1',
          'endCursor' => 'cursor2'
        },
        'nodes' => [
          { 'id' => 'gid://gitlab/WorkItem/1', 'iid' => '42', 'title' => 'Fix bug' }
        ]
      }
    end

    let(:saved_view_success) do
      {
        content: [{ type: 'text', text: Gitlab::Json.dump(saved_view_data) }],
        structuredContent: saved_view_data,
        isError: false
      }
    end

    let(:work_items_success) do
      {
        content: [{ type: 'text', text: Gitlab::Json.dump(work_items_data) }],
        structuredContent: work_items_data,
        isError: false
      }
    end

    before do
      saved_view_tool = instance_double(Mcp::Tools::WorkItems::GetSavedViewTool)
      allow(Mcp::Tools::WorkItems::GetSavedViewTool).to receive(:new).and_return(saved_view_tool)
      allow(saved_view_tool).to receive(:execute).and_return(saved_view_success)

      work_items_tool = instance_double(Mcp::Tools::WorkItems::GetSavedViewWorkItemsTool)
      allow(Mcp::Tools::WorkItems::GetSavedViewWorkItemsTool).to receive(:new).and_return(work_items_tool)
      allow(work_items_tool).to receive_messages(execute: work_items_success, unsupported_filters: [])
    end

    it 'executes saved view tool with correct arguments' do
      expect(Mcp::Tools::WorkItems::GetSavedViewTool).to receive(:new).with(
        current_user: user,
        params: arguments,
        version: '0.1.0'
      )

      service.send(:perform_0_1_0, arguments)
    end

    it 'executes work items tool with filters from saved view' do
      expect(Mcp::Tools::WorkItems::GetSavedViewWorkItemsTool).to receive(:new).with(
        current_user: user,
        params: arguments.merge(
          filters: saved_view_data['filters'],
          sort: saved_view_data['sort']
        ),
        version: '0.1.0'
      )

      service.send(:perform_0_1_0, arguments)
    end

    context 'when saved view has unsupported filters' do
      let(:saved_view_data) do
        {
          'id' => saved_view_id,
          'name' => 'Complex View',
          'description' => 'View with unsupported filters',
          'filters' => {
            'labelName' => ['bug'],
            'healthStatusFilter' => 'onTrack',
            'iterationId' => ['gid://gitlab/Iteration/1']
          },
          'sort' => 'CREATED_DESC'
        }
      end

      it 'includes warnings about unsupported filters in the response' do
        work_items_tool = instance_double(Mcp::Tools::WorkItems::GetSavedViewWorkItemsTool)
        allow(Mcp::Tools::WorkItems::GetSavedViewWorkItemsTool).to receive(:new).and_return(work_items_tool)
        allow(work_items_tool).to receive_messages(execute: work_items_success,
          unsupported_filters: %w[healthStatusFilter iterationId]
        )

        result = service.send(:perform_0_1_0, arguments)

        expect(result[:isError]).to be(false)
        expect(result[:structuredContent]).to have_key('warnings')

        warning = result[:structuredContent]['warnings'].first
        expect(warning['type']).to eq('unsupported_filters')
        expect(warning['filters']).to contain_exactly('healthStatusFilter', 'iterationId')
        expect(warning['message']).to include('healthStatusFilter')
        expect(warning['message']).to include('iterationId')
        expect(warning['message']).to include('results may be broader than expected')
      end
    end

    context 'when all filters are supported' do
      it 'does not include warnings in the response' do
        work_items_tool = instance_double(Mcp::Tools::WorkItems::GetSavedViewWorkItemsTool)
        allow(Mcp::Tools::WorkItems::GetSavedViewWorkItemsTool).to receive(:new).and_return(work_items_tool)
        allow(work_items_tool).to receive_messages(execute: work_items_success, unsupported_filters: [])

        result = service.send(:perform_0_1_0, arguments)

        expect(result[:isError]).to be(false)
        expect(result[:structuredContent]).not_to have_key('warnings')
      end
    end

    context 'when unsupported_filters is nil' do
      it 'does not append warnings' do
        combined = { 'savedView' => {}, 'workItems' => {} }

        service.send(:append_unsupported_filter_warnings, combined, nil)

        expect(combined).not_to have_key('warnings')
      end
    end

    context 'when unsupported_filters is empty' do
      it 'does not append warnings' do
        combined = { 'savedView' => {}, 'workItems' => {} }

        service.send(:append_unsupported_filter_warnings, combined, [])

        expect(combined).not_to have_key('warnings')
      end
    end

    context 'when work items tool returns error' do
      let(:work_items_error) do
        {
          content: [{ type: 'text', text: 'The work items are inaccessible' }],
          structuredContent: {},
          isError: true
        }
      end

      before do
        work_items_tool = instance_double(Mcp::Tools::WorkItems::GetSavedViewWorkItemsTool)
        allow(Mcp::Tools::WorkItems::GetSavedViewWorkItemsTool).to receive(:new).and_return(work_items_tool)
        allow(work_items_tool).to receive_messages(execute: work_items_error, unsupported_filters: [])
      end

      it 'returns the error from work items tool' do
        result = service.send(:perform_0_1_0, arguments)

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('The work items are inaccessible')
      end
    end
  end

  describe '#perform_default' do
    let(:arguments) do
      {
        group_id: group.id.to_s,
        saved_view_id: 'gid://gitlab/WorkItems::SavedViews::SavedView/1'
      }
    end

    it 'delegates to perform_0_1_0' do
      expect(service).to receive(:perform_0_1_0).with(arguments)

      service.send(:perform_default, arguments)
    end
  end

  describe '#execute' do
    let(:params) do
      {
        arguments: {
          group_id: group.id.to_s,
          saved_view_id: 'gid://gitlab/WorkItems::SavedViews::SavedView/1'
        }
      }
    end

    context 'when current_user is not set' do
      before do
        service.set_cred(current_user: nil)
      end

      it 'returns error response' do
        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('current_user is not set')
      end
    end
  end

  describe 'integration', :aggregate_failures do
    let_it_be(:label) { create(:group_label, group: group, title: 'bug') }
    let_it_be(:critical_label) { create(:group_label, group: group, title: 'critical') }
    let_it_be(:other_user) { create(:user) }
    let_it_be(:milestone) { create(:milestone, group: group, title: 'v1.0') }

    let_it_be(:labeled_work_item) do
      create(:work_item, :issue, project: project).tap do |wi|
        create(:label_link, label: label, target: wi)
      end
    end

    let_it_be(:closed_work_item) { create(:work_item, :issue, project: project, state: :closed) }

    # Helper to execute the service and verify the work items query received the expected variables
    def execute_and_verify_variables(expected_variables)
      allow(GitlabSchema).to receive(:execute).and_call_original

      result = service.execute(request: request, params: { arguments: params_arguments })

      expect(result[:isError]).to be(false)
      expect(GitlabSchema).to have_received(:execute).with(
        a_string_including('GetWorkItemsFull'),
        variables: hash_including(expected_variables),
        context: anything
      )

      result
    end

    context 'when saved view exists with filters' do
      let_it_be(:saved_view) do
        create(:saved_view,
          namespace: group,
          author: user,
          name: 'Open Bugs',
          description: 'All open bugs',
          filter_data: { state: 'opened', label_ids: [label.id] },
          sort: :created_desc
        )
      end

      let(:saved_view_gid) { saved_view.to_global_id.to_s }
      let(:params_arguments) { { group_id: group.id.to_s, saved_view_id: saved_view_gid } }

      it 'fetches saved view via GraphQL and returns its metadata' do
        allow(GitlabSchema).to receive(:execute).and_call_original

        result = service.execute(request: request, params: { arguments: params_arguments })

        expect(result[:isError]).to be(false)
        expect(result[:structuredContent]).to have_key('savedView')

        view_data = result[:structuredContent]['savedView']
        expect(view_data['name']).to eq('Open Bugs')
        expect(view_data['description']).to eq('All open bugs')
        expect(view_data['filters']).to be_present
      end

      it 'fetches work items using saved view filters' do
        allow(GitlabSchema).to receive(:execute).and_call_original

        result = service.execute(request: request, params: { arguments: params_arguments })

        expect(result[:isError]).to be(false)
        expect(result[:structuredContent]).to have_key('workItems')

        work_items_data = result[:structuredContent]['workItems']
        expect(work_items_data).to have_key('nodes')
        expect(work_items_data).to have_key('pageInfo')
      end

      it 'executes two GraphQL queries (saved view + work items)' do
        allow(GitlabSchema).to receive(:execute).and_call_original

        service.execute(request: request, params: { arguments: params_arguments })

        expect(GitlabSchema).to have_received(:execute).twice
      end

      it 'passes correct context to both GraphQL queries' do
        allow(GitlabSchema).to receive(:execute).and_call_original

        service.execute(request: request, params: { arguments: params_arguments })

        expect(GitlabSchema).to have_received(:execute).twice.with(
          anything,
          variables: anything,
          context: hash_including(current_user: user)
        )
      end

      it 'passes saved view ID in the first query variables' do
        allow(GitlabSchema).to receive(:execute).and_call_original

        service.execute(request: request, params: { arguments: params_arguments })

        expect(GitlabSchema).to have_received(:execute).with(
          a_string_including('GetNamespaceSavedView'),
          variables: hash_including(
            fullPath: group.full_path,
            id: saved_view_gid
          ),
          context: anything
        )
      end

      it 'passes namespace fullPath in the work items query' do
        allow(GitlabSchema).to receive(:execute).and_call_original

        service.execute(request: request, params: { arguments: params_arguments })

        expect(GitlabSchema).to have_received(:execute).with(
          a_string_including('GetWorkItemsFull'),
          variables: hash_including(fullPath: group.full_path),
          context: anything
        )
      end

      it 'returns combined savedView and workItems in structured content' do
        result = service.execute(request: request, params: { arguments: params_arguments })

        structured = result[:structuredContent]
        expect(structured.keys).to contain_exactly('savedView', 'workItems')
      end
    end

    context 'with assigneeUsernames filter' do
      let_it_be(:assigned_work_item) do
        create(:work_item, :issue, project: project).tap do |wi|
          wi.assignees << other_user
        end
      end

      let_it_be(:saved_view) do
        create(:saved_view,
          namespace: group,
          author: user,
          name: 'Assigned to other_user',
          filter_data: { assignee_ids: [other_user.id] }
        )
      end

      let(:params_arguments) { { group_id: group.id.to_s, saved_view_id: saved_view.to_global_id.to_s } }

      it 'passes assigneeUsernames to the work items query' do
        result = execute_and_verify_variables(assigneeUsernames: [other_user.username])

        iids = result[:structuredContent].dig('workItems', 'nodes').pluck('iid')
        expect(iids).to include(assigned_work_item.iid.to_s)
      end
    end

    context 'with assigneeWildcardId filter' do
      let_it_be(:assigned_wi) do
        create(:work_item, :issue, project: project).tap do |wi|
          wi.assignees << other_user
        end
      end

      let_it_be(:saved_view) do
        create(:saved_view,
          namespace: group,
          author: user,
          name: 'Any assignee',
          filter_data: { assignee_wildcard_id: 'ANY' }
        )
      end

      let(:params_arguments) { { group_id: group.id.to_s, saved_view_id: saved_view.to_global_id.to_s } }

      it 'passes assigneeWildcardId to the work items query' do
        result = execute_and_verify_variables(assigneeWildcardId: 'ANY')

        iids = result[:structuredContent].dig('workItems', 'nodes').pluck('iid')
        expect(iids).to include(assigned_wi.iid.to_s)
      end
    end

    context 'with authorUsername filter' do
      let_it_be(:authored_work_item) do
        create(:work_item, :issue, project: project, author: other_user)
      end

      let_it_be(:saved_view) do
        create(:saved_view,
          namespace: group,
          author: user,
          name: 'By other_user',
          filter_data: { author_ids: [other_user.id] }
        )
      end

      let(:params_arguments) { { group_id: group.id.to_s, saved_view_id: saved_view.to_global_id.to_s } }

      it 'passes authorUsername to the work items query' do
        result = execute_and_verify_variables(authorUsername: other_user.username)

        iids = result[:structuredContent].dig('workItems', 'nodes').pluck('iid')
        expect(iids).to include(authored_work_item.iid.to_s)
      end
    end

    context 'with confidential filter' do
      let_it_be(:confidential_work_item) do
        create(:work_item, :issue, :confidential, project: project)
      end

      let_it_be(:saved_view) do
        create(:saved_view,
          namespace: group,
          author: user,
          name: 'Confidential only',
          filter_data: { confidential: true }
        )
      end

      let(:params_arguments) { { group_id: group.id.to_s, saved_view_id: saved_view.to_global_id.to_s } }

      it 'passes confidential to the work items query' do
        result = execute_and_verify_variables(confidential: true)

        nodes = result[:structuredContent].dig('workItems', 'nodes')
        expect(nodes).to all(include('confidential' => true))
      end
    end

    context 'with labelName filter' do
      let_it_be(:saved_view) do
        create(:saved_view,
          namespace: group,
          author: user,
          name: 'Bug items',
          filter_data: { label_ids: [label.id] }
        )
      end

      let(:params_arguments) { { group_id: group.id.to_s, saved_view_id: saved_view.to_global_id.to_s } }

      it 'passes labelName to the work items query' do
        result = execute_and_verify_variables(labelName: [label.title])

        iids = result[:structuredContent].dig('workItems', 'nodes').pluck('iid')
        expect(iids).to include(labeled_work_item.iid.to_s)
      end
    end

    context 'with milestoneTitle filter' do
      let_it_be(:milestoned_work_item) do
        create(:work_item, :issue, project: project, milestone: milestone)
      end

      let_it_be(:saved_view) do
        create(:saved_view,
          namespace: group,
          author: user,
          name: 'v1.0 milestone',
          filter_data: { milestone_ids: [milestone.id] }
        )
      end

      let(:params_arguments) { { group_id: group.id.to_s, saved_view_id: saved_view.to_global_id.to_s } }

      it 'passes milestoneTitle to the work items query' do
        result = execute_and_verify_variables(milestoneTitle: [milestone.title])

        iids = result[:structuredContent].dig('workItems', 'nodes').pluck('iid')
        expect(iids).to include(milestoned_work_item.iid.to_s)
      end
    end

    context 'with milestoneWildcardId filter' do
      let_it_be(:milestoned_wi) do
        create(:work_item, :issue, project: project, milestone: milestone)
      end

      let_it_be(:saved_view) do
        create(:saved_view,
          namespace: group,
          author: user,
          name: 'Any milestone',
          filter_data: { milestone_wildcard_id: 'ANY' }
        )
      end

      let(:params_arguments) { { group_id: group.id.to_s, saved_view_id: saved_view.to_global_id.to_s } }

      it 'passes milestoneWildcardId to the work items query' do
        result = execute_and_verify_variables(milestoneWildcardId: 'ANY')

        iids = result[:structuredContent].dig('workItems', 'nodes').pluck('iid')
        expect(iids).to include(milestoned_wi.iid.to_s)
      end
    end

    context 'with myReactionEmoji filter' do
      let_it_be(:thumbsup_work_item) do
        create(:work_item, :issue, project: project).tap do |wi|
          create(:award_emoji, name: 'thumbsup', user: user, awardable: wi)
        end
      end

      let_it_be(:saved_view) do
        create(:saved_view,
          namespace: group,
          author: user,
          name: 'Thumbs up',
          filter_data: { my_reaction_emoji: 'thumbsup' }
        )
      end

      let(:params_arguments) { { group_id: group.id.to_s, saved_view_id: saved_view.to_global_id.to_s } }

      it 'passes myReactionEmoji to the work items query' do
        result = execute_and_verify_variables(myReactionEmoji: 'thumbsup')

        iids = result[:structuredContent].dig('workItems', 'nodes').pluck('iid')
        expect(iids).to include(thumbsup_work_item.iid.to_s)
      end
    end

    context 'with types filter' do
      let_it_be(:task_work_item) { create(:work_item, :task, project: project) }

      let_it_be(:saved_view) do
        create(:saved_view,
          namespace: group,
          author: user,
          name: 'Tasks only',
          filter_data: { issue_types: %w[TASK] }
        )
      end

      let(:params_arguments) { { group_id: group.id.to_s, saved_view_id: saved_view.to_global_id.to_s } }

      it 'passes types to the work items query' do
        result = execute_and_verify_variables(types: %w[TASK])

        nodes = result[:structuredContent].dig('workItems', 'nodes')
        type_names = nodes.map { |n| n.dig('workItemType', 'name') }
        expect(type_names).to all(eq('Task'))
      end
    end

    context 'with state filter' do
      let_it_be(:saved_view) do
        create(:saved_view,
          namespace: group,
          author: user,
          name: 'Closed items',
          filter_data: { state: 'closed' }
        )
      end

      let(:params_arguments) { { group_id: group.id.to_s, saved_view_id: saved_view.to_global_id.to_s } }

      it 'passes state to the work items query and returns only closed items' do
        result = execute_and_verify_variables(state: 'closed')

        nodes = result[:structuredContent].dig('workItems', 'nodes')
        states = nodes.pluck('state')
        expect(states).to all(eq('CLOSED'))
        expect(nodes.pluck('iid')).to include(closed_work_item.iid.to_s)
      end
    end

    context 'with not (negated) filter' do
      let_it_be(:saved_view) do
        create(:saved_view,
          namespace: group,
          author: user,
          name: 'Not bug',
          filter_data: { not: { label_ids: [label.id] } }
        )
      end

      let(:params_arguments) { { group_id: group.id.to_s, saved_view_id: saved_view.to_global_id.to_s } }

      it 'passes not filter to the work items query' do
        result = execute_and_verify_variables(not: hash_including('labelName' => [label.title]))

        iids = result[:structuredContent].dig('workItems', 'nodes').pluck('iid')
        expect(iids).not_to include(labeled_work_item.iid.to_s)
      end
    end

    context 'with or (union) filter' do
      let_it_be(:critical_work_item) do
        create(:work_item, :issue, project: project).tap do |wi|
          create(:label_link, label: critical_label, target: wi)
        end
      end

      let_it_be(:saved_view) do
        create(:saved_view,
          namespace: group,
          author: user,
          name: 'Bug or Critical',
          filter_data: { or: { label_ids: [label.id, critical_label.id] } }
        )
      end

      let(:params_arguments) { { group_id: group.id.to_s, saved_view_id: saved_view.to_global_id.to_s } }

      it 'passes or filter to the work items query' do
        result = execute_and_verify_variables(
          or: hash_including('labelNames' => contain_exactly(label.title, critical_label.title))
        )

        iids = result[:structuredContent].dig('workItems', 'nodes').pluck('iid')
        expect(iids).to include(labeled_work_item.iid.to_s, critical_work_item.iid.to_s)
      end
    end

    context 'with multiple filters combined' do
      let_it_be(:matching_work_item) do
        create(:work_item, :issue, :confidential, project: project, author: other_user).tap do |wi|
          create(:label_link, label: label, target: wi)
          wi.assignees << other_user
        end
      end

      let_it_be(:saved_view) do
        create(:saved_view,
          namespace: group,
          author: user,
          name: 'Combined filters',
          filter_data: {
            state: 'opened',
            confidential: true,
            label_ids: [label.id],
            assignee_ids: [other_user.id],
            author_ids: [other_user.id]
          },
          sort: :created_desc
        )
      end

      let(:params_arguments) { { group_id: group.id.to_s, saved_view_id: saved_view.to_global_id.to_s } }

      it 'passes all filters to the work items query' do
        result = execute_and_verify_variables(
          state: 'opened',
          confidential: true,
          labelName: [label.title],
          assigneeUsernames: [other_user.username],
          authorUsername: other_user.username
        )

        nodes = result[:structuredContent].dig('workItems', 'nodes')
        expect(nodes).to all(include('confidential' => true))
        iids = nodes.pluck('iid')
        expect(iids).to include(matching_work_item.iid.to_s)
      end
    end

    context 'with pagination parameters' do
      let_it_be(:saved_view) do
        create(:saved_view,
          namespace: group,
          author: user,
          name: 'Paginated View',
          filter_data: { state: 'opened' }
        )
      end

      let(:saved_view_gid) { saved_view.to_global_id.to_s }
      let(:params_arguments) do
        {
          group_id: group.id.to_s,
          saved_view_id: saved_view_gid,
          first: 5
        }
      end

      it 'forwards pagination params to the work items query' do
        allow(GitlabSchema).to receive(:execute).and_call_original

        service.execute(request: request, params: { arguments: params_arguments })

        expect(GitlabSchema).to have_received(:execute).with(
          a_string_including('GetWorkItemsFull'),
          variables: hash_including(firstPageSize: 5),
          context: anything
        )
      end

      it 'includes pageInfo in the response' do
        result = service.execute(request: request, params: { arguments: params_arguments })

        page_info = result[:structuredContent].dig('workItems', 'pageInfo')
        expect(page_info).to include('hasNextPage', 'hasPreviousPage', 'startCursor', 'endCursor')
      end
    end

    context 'when saved view does not exist' do
      let(:params_arguments) do
        {
          group_id: group.id.to_s,
          saved_view_id: "gid://gitlab/WorkItems::SavedViews::SavedView/#{non_existing_record_id}"
        }
      end

      it 'returns error response' do
        result = service.execute(request: request, params: { arguments: params_arguments })

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('Saved view not found')
      end
    end

    context 'when user lacks permission on private namespace' do
      let_it_be(:private_group) { create(:group, :private) }
      let_it_be(:private_saved_view) do
        create(:saved_view,
          namespace: private_group,
          author: create(:user),
          name: 'Private View',
          filter_data: { state: 'opened' }
        )
      end

      let(:params_arguments) do
        {
          group_id: private_group.id.to_s,
          saved_view_id: private_saved_view.to_global_id.to_s
        }
      end

      it 'returns error response' do
        result = service.execute(request: request, params: { arguments: params_arguments })

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('Access denied to group')
      end
    end

    context 'when saved view has no filters' do
      let_it_be(:empty_saved_view) do
        create(:saved_view,
          namespace: group,
          author: user,
          name: 'No Filters View',
          filter_data: {}
        )
      end

      let(:params_arguments) do
        {
          group_id: group.id.to_s,
          saved_view_id: empty_saved_view.to_global_id.to_s
        }
      end

      it 'returns work items without filter constraints' do
        result = service.execute(request: request, params: { arguments: params_arguments })

        expect(result[:isError]).to be(false)
        expect(result[:structuredContent]['workItems']['nodes']).to be_an(Array)
      end
    end

    context 'with search and in filters' do
      let_it_be(:searchable_work_item) do
        create(:work_item, :issue, project: project, title: 'Fix login timeout bug')
      end

      let_it_be(:saved_view) do
        create(:saved_view,
          namespace: group,
          author: user,
          name: 'Search login',
          filter_data: { search: 'login timeout', in: %w[TITLE] }
        )
      end

      let(:params_arguments) { { group_id: group.id.to_s, saved_view_id: saved_view.to_global_id.to_s } }

      it 'passes search and in to the work items query' do
        result = execute_and_verify_variables(search: 'login timeout', in: %w[TITLE])

        expect(result[:isError]).to be(false)

        iids = result[:structuredContent].dig('workItems', 'nodes').pluck('iid')
        expect(iids).to include(searchable_work_item.iid.to_s)
      end
    end

    context 'with hierarchyFilters' do
      let_it_be(:parent_work_item) { create(:work_item, :issue, namespace: group) }
      let_it_be(:child_work_item) do
        create(:work_item, :task, project: project).tap do |child|
          create(:parent_link, work_item: child, work_item_parent: parent_work_item)
        end
      end

      let_it_be(:saved_view) do
        create(:saved_view,
          namespace: group,
          author: user,
          name: 'Children of parent',
          filter_data: {
            hierarchy_filters: {
              work_item_parent_ids: [parent_work_item.id.to_s]
            }
          }
        )
      end

      let(:params_arguments) { { group_id: group.id.to_s, saved_view_id: saved_view.to_global_id.to_s } }

      it 'passes hierarchyFilters with parentIds as GIDs to the work items query' do
        expected_gid = "gid://gitlab/WorkItem/#{parent_work_item.id}"

        result = execute_and_verify_variables(
          hierarchyFilters: hash_including('parentIds' => [expected_gid])
        )

        iids = result[:structuredContent].dig('workItems', 'nodes').pluck('iid')
        expect(iids).to include(child_work_item.iid.to_s)
      end
    end

    context 'with fullPath filter scoping to a subgroup' do
      let_it_be(:subgroup) { create(:group, parent: group) }
      let_it_be(:subgroup_project) { create(:project, :public, group: subgroup) }
      let_it_be(:subgroup_work_item) { create(:work_item, :issue, project: subgroup_project) }

      let_it_be(:saved_view) do
        create(:saved_view,
          namespace: group,
          author: user,
          name: 'Subgroup scoped',
          filter_data: { namespace_id: subgroup.id, state: 'opened' }
        )
      end

      let(:params_arguments) { { group_id: group.id.to_s, saved_view_id: saved_view.to_global_id.to_s } }

      it 'overrides fullPath to the subgroup and passes other filters' do
        allow(GitlabSchema).to receive(:execute).and_call_original

        result = service.execute(request: request, params: { arguments: params_arguments })

        expect(result[:isError]).to be(false)

        # The work items query should target the subgroup namespace
        expect(GitlabSchema).to have_received(:execute).with(
          a_string_including('GetWorkItemsFull'),
          variables: hash_including(
            fullPath: subgroup.full_path,
            state: 'opened'
          ),
          context: anything
        )
      end

      it 'does not report fullPath as an unsupported filter' do
        result = service.execute(request: request, params: { arguments: params_arguments })

        expect(result[:isError]).to be(false)
        expect(result[:structuredContent]).not_to have_key('warnings')
      end
    end

    context 'with fullPath filter scoping to a project' do
      let_it_be(:scoped_project) { create(:project, :public, group: group) }
      let_it_be(:project_work_item) { create(:work_item, :issue, project: scoped_project) }

      let_it_be(:saved_view) do
        create(:saved_view,
          namespace: group,
          author: user,
          name: 'Project scoped',
          filter_data: { namespace_id: scoped_project.project_namespace.id }
        )
      end

      let(:params_arguments) { { group_id: group.id.to_s, saved_view_id: saved_view.to_global_id.to_s } }

      it 'overrides fullPath to the project path' do
        allow(GitlabSchema).to receive(:execute).and_call_original

        result = service.execute(request: request, params: { arguments: params_arguments })

        expect(result[:isError]).to be(false)

        expect(GitlabSchema).to have_received(:execute).with(
          a_string_including('GetWorkItemsFull'),
          variables: hash_including(fullPath: scoped_project.full_path),
          context: anything
        )
      end
    end

    context 'with sort from saved view' do
      let_it_be(:sorted_saved_view) do
        create(:saved_view,
          namespace: group,
          author: user,
          name: 'Sorted View',
          filter_data: { state: 'opened' },
          sort: :updated_desc
        )
      end

      let(:params_arguments) do
        {
          group_id: group.id.to_s,
          saved_view_id: sorted_saved_view.to_global_id.to_s
        }
      end

      it 'passes sort from saved view to work items query' do
        allow(GitlabSchema).to receive(:execute).and_call_original

        service.execute(request: request, params: { arguments: params_arguments })

        expect(GitlabSchema).to have_received(:execute).with(
          a_string_including('GetWorkItemsFull'),
          variables: hash_including(:sort),
          context: anything
        )
      end
    end
  end
end
