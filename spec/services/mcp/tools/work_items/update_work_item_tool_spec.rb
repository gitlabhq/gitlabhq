# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::WorkItems::UpdateWorkItemTool, feature_category: :mcp_server do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public) }
  let_it_be_with_reload(:work_item) { create(:work_item, :issue, project: project, title: 'Original title') }

  let(:params) { { project_id: project.id.to_s, work_item_iid: work_item.iid } }
  let(:tool) { described_class.new(current_user: user, params: params) }

  before_all do
    project.add_developer(user)
  end

  describe 'versioning' do
    it 'registers version using VERSIONS constant' do
      expect(tool.version).to eq(Mcp::Tools::Concerns::Constants::VERSIONS[:v0_1_0])
    end

    it 'has correct operation name for version 0.1.0' do
      expect(tool.operation_name).to eq('workItemUpdate')
    end

    it 'has correct GraphQL operation for version 0.1.0' do
      operation = tool.graphql_operation

      expect(operation).to include('mutation updateWorkItemMcp')
      expect(operation).to include('workItemUpdate(input: $input)')
    end
  end

  describe '#build_variables' do
    context 'with minimal params' do
      it 'maps only the work item global ID' do
        expect(tool.build_variables[:input]).to eq(id: work_item.to_global_id.to_s)
      end
    end

    context 'with base params' do
      before do
        params.merge!(title: 'New title', confidential: true)
      end

      it 'maps title and confidential to the top level', :aggregate_failures do
        input = tool.build_variables[:input]

        expect(input[:title]).to eq('New title')
        expect(input[:confidential]).to be(true)
      end
    end

    context 'with state transitions' do
      it 'maps closed to CLOSE' do
        params[:state] = 'closed'

        expect(tool.build_variables[:input][:stateEvent]).to eq('CLOSE')
      end

      it 'maps opened to REOPEN' do
        params[:state] = 'opened'

        expect(tool.build_variables[:input][:stateEvent]).to eq('REOPEN')
      end
    end

    context 'with widget params' do
      before do
        params.merge!(
          description: 'Updated description',
          assignee_ids: [user.id],
          add_label_ids: ['5'],
          remove_label_ids: ['gid://gitlab/Label/7'],
          start_date: '2026-01-01',
          due_date: '2026-01-31',
          is_fixed: true,
          parent_id: '12'
        )
      end

      it 'maps each param to its GraphQL input key', :aggregate_failures do
        input = tool.build_variables[:input]

        expect(input[:descriptionWidget]).to eq(description: 'Updated description')
        expect(input[:assigneesWidget]).to eq(assigneeIds: ["gid://gitlab/User/#{user.id}"])
        expect(input[:labelsWidget]).to eq(
          addLabelIds: ['gid://gitlab/Label/5'],
          removeLabelIds: ['gid://gitlab/Label/7']
        )
        expect(input[:startAndDueDateWidget]).to eq(startDate: '2026-01-01', dueDate: '2026-01-31', isFixed: true)
        expect(input[:hierarchyWidget]).to eq(parentId: 'gid://gitlab/WorkItem/12')
      end
    end

    context 'with only add_label_ids' do
      before do
        params[:add_label_ids] = ['5']
      end

      it 'omits removeLabelIds' do
        expect(tool.build_variables[:input][:labelsWidget]).to eq(addLabelIds: ['gid://gitlab/Label/5'])
      end
    end

    context 'with to-do params' do
      it 'upcases add and omits todoId when no to-do ID is given' do
        params[:todo_action] = 'add'

        expect(tool.build_variables[:input][:currentUserTodosWidget]).to eq(action: 'ADD')
      end

      it 'upcases mark_as_done and normalizes the to-do ID' do
        params.merge!(todo_action: 'mark_as_done', todo_id: '9')

        expect(tool.build_variables[:input][:currentUserTodosWidget]).to eq(
          action: 'MARK_AS_DONE',
          todoId: 'gid://gitlab/Todo/9'
        )
      end

      it 'rejects todo_id without todo_action' do
        params[:todo_id] = '9'

        expect { tool.build_variables }
          .to raise_error(ArgumentError, 'todo_action is required when todo_id is provided')
      end
    end

    context 'with weight params' do
      it 'maps weight' do
        params[:weight] = 3

        expect(tool.build_variables[:input][:weightWidget]).to eq(weight: 3)
      end

      it 'sends an explicit nil weight for clear_weight' do
        params[:clear_weight] = true

        input = tool.build_variables[:input]

        expect(input).to have_key(:weightWidget)
        expect(input[:weightWidget]).to eq(weight: nil)
      end

      it 'prefers clear_weight over weight' do
        params.merge!(weight: 3, clear_weight: true)

        expect(tool.build_variables[:input][:weightWidget]).to eq(weight: nil)
      end
    end

    context 'with EE-only widget params' do
      before do
        params.merge!(
          health_status: 'atRisk',
          status_id: 'gid://gitlab/WorkItems::Statuses::SystemDefined::Status/2',
          agent_plan: 'Plan content'
        )
      end

      it 'maps each param to its widget', :aggregate_failures do
        input = tool.build_variables[:input]

        expect(input[:healthStatusWidget]).to eq(healthStatus: 'atRisk')
        expect(input[:statusWidget]).to eq(status: 'gid://gitlab/WorkItems::Statuses::SystemDefined::Status/2')
        expect(input[:agentPlanWidget]).to eq(content: 'Plan content')
      end
    end

    context 'with create-only params' do
      { type_name: 'Issue', label_ids: ['1'] }.each do |param, value|
        it "rejects #{param}" do
          params[param] = value

          expect { tool.build_variables }
            .to raise_error(ArgumentError, "#{param} can only be used when creating (omit work_item_iid)")
        end
      end
    end

    context 'with both project_id and group_id' do
      before do
        params[:group_id] = '1'
      end

      it 'raises an error' do
        expect { tool.build_variables }
          .to raise_error(ArgumentError, /Provide exactly one of url, project_id, or group_id/)
      end
    end

    context 'with quick actions in the description' do
      before do
        params[:description] = '/close'
      end

      it 'raises an error' do
        expect { tool.build_variables }
          .to raise_error(ArgumentError, 'Quick actions (commands starting with /) are not allowed in description')
      end
    end
  end

  describe 'integration' do
    it 'updates the title and returns the compact payload', :aggregate_failures do
      params[:title] = 'New title'

      result = tool.execute

      expect(result[:isError]).to be(false)
      expect(result[:structuredContent].keys).to match_array(%w[id iid type title state confidential web_url])
      expect(result[:structuredContent]['title']).to eq('New title')
      expect(work_item.reload.title).to eq('New title')
    end

    it 'closes the work item' do
      params[:state] = 'closed'

      result = tool.execute

      expect(result[:structuredContent]['state']).to eq('CLOSED')
      expect(work_item.reload.state).to eq('closed')
    end

    context 'when the work item is closed' do
      before do
        work_item.close!
      end

      it 'reopens the work item' do
        params[:state] = 'opened'

        result = tool.execute

        expect(result[:structuredContent]['state']).to eq('OPEN')
        expect(work_item.reload.state).to eq('opened')
      end
    end

    context 'when the work item does not exist' do
      let(:params) { { project_id: project.id.to_s, work_item_iid: non_existing_record_iid, title: 'New title' } }

      it 'raises a uniform not-found error' do
        expect { tool.execute }.to raise_error(ArgumentError, /Work item ##{non_existing_record_iid} not found/)
      end
    end

    context 'when the work item is confidential and the user is not a member' do
      let_it_be(:non_member) { create(:user) }
      let_it_be(:confidential_work_item) { create(:work_item, :issue, :confidential, project: project) }

      let(:params) do
        { project_id: project.id.to_s, work_item_iid: confidential_work_item.iid, title: 'New title' }
      end

      let(:tool) { described_class.new(current_user: non_member, params: params) }

      it 'raises the same not-found error' do
        expect { tool.execute }
          .to raise_error(ArgumentError, /Work item ##{confidential_work_item.iid} not found/)
      end
    end

    context 'when the user can read but not update the work item' do
      let_it_be(:non_member) { create(:user) }

      let(:params) { { project_id: project.id.to_s, work_item_iid: work_item.iid, title: 'New title' } }
      let(:tool) { described_class.new(current_user: non_member, params: params) }

      it 'returns the same uniform not-found error', :aggregate_failures do
        result = tool.execute

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text])
          .to include('Work item not found: it does not exist or you do not have access to it.')
      end
    end
  end
end
