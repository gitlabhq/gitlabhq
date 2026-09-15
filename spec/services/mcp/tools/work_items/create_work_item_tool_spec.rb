# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::WorkItems::CreateWorkItemTool, feature_category: :mcp_server do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:label) { create(:label, project: project) }

  let(:params) { { project_id: project.id.to_s, title: 'New item', type_name: 'Issue' } }
  let(:tool) { described_class.new(current_user: user, params: params) }

  before_all do
    project.add_developer(user)
  end

  describe 'versioning' do
    it 'registers version using VERSIONS constant' do
      expect(tool.version).to eq(Mcp::Tools::Concerns::Constants::VERSIONS[:v0_1_0])
    end

    it 'has correct operation name for version 0.1.0' do
      expect(tool.operation_name).to eq('workItemCreate')
    end

    it 'has correct GraphQL operation for version 0.1.0' do
      operation = tool.graphql_operation

      expect(operation).to include('mutation createWorkItemMcp')
      expect(operation).to include('workItemCreate(input: $input)')
    end
  end

  describe '#build_variables' do
    let(:issue_type_gid) do
      WorkItems::TypesFramework::Provider.new(project).find_by_name('Issue').to_global_id.to_s
    end

    context 'with minimal params' do
      it 'maps namespace path, type and title', :aggregate_failures do
        input = tool.build_variables[:input]

        expect(input[:namespacePath]).to eq(project.full_path)
        expect(input[:workItemTypeId]).to eq(issue_type_gid)
        expect(input[:title]).to eq('New item')
        expect(input.keys).to match_array(%i[namespacePath workItemTypeId title])
      end
    end

    context 'with a lowercase type name' do
      before do
        params[:type_name] = 'issue'
      end

      it 'resolves the type case-insensitively' do
        expect(tool.build_variables[:input][:workItemTypeId]).to eq(issue_type_gid)
      end
    end

    context 'with an unknown type name' do
      before do
        params[:type_name] = 'Nonexistent'
      end

      it 'raises an error listing the valid types' do
        expect { tool.build_variables }.to raise_error(ArgumentError) do |error|
          expect(error.message).to include("Work item type 'Nonexistent' not found. Valid types:")
          expect(error.message).to include('Issue')
        end
      end
    end

    context 'with optional params' do
      before do
        params.merge!(
          confidential: true,
          description: 'A description',
          assignee_ids: [user.id],
          label_ids: [label.id.to_s, 'gid://gitlab/Label/7'],
          start_date: '2026-01-01',
          due_date: '2026-01-31',
          parent_id: '12'
        )
      end

      it 'maps each param to its GraphQL input key', :aggregate_failures do
        input = tool.build_variables[:input]

        expect(input[:confidential]).to be(true)
        expect(input[:descriptionWidget]).to eq(description: 'A description')
        expect(input[:assigneesWidget]).to eq(assigneeIds: ["gid://gitlab/User/#{user.id}"])
        expect(input[:labelsWidget]).to eq(labelIds: ["gid://gitlab/Label/#{label.id}", 'gid://gitlab/Label/7'])
        expect(input[:startAndDueDateWidget]).to eq(startDate: '2026-01-01', dueDate: '2026-01-31')
        expect(input[:hierarchyWidget]).to eq(parentId: 'gid://gitlab/WorkItem/12')
      end
    end

    context 'with a parent global ID' do
      before do
        params[:parent_id] = 'gid://gitlab/WorkItem/34'
      end

      it 'passes the global ID through unchanged' do
        expect(tool.build_variables[:input][:hierarchyWidget]).to eq(parentId: 'gid://gitlab/WorkItem/34')
      end
    end

    context 'with only one date param' do
      before do
        params[:due_date] = '2026-01-31'
      end

      it 'includes only the provided date key' do
        expect(tool.build_variables[:input][:startAndDueDateWidget]).to eq(dueDate: '2026-01-31')
      end
    end

    context 'with EE-only params' do
      before do
        params.merge!(
          health_status: 'onTrack',
          weight: 3,
          status_id: 'gid://gitlab/WorkItems::Statuses::SystemDefined::Status/1',
          agent_plan: 'Plan content'
        )
      end

      it 'maps each param to its widget', :aggregate_failures do
        input = tool.build_variables[:input]

        expect(input[:healthStatusWidget]).to eq(healthStatus: 'onTrack')
        expect(input[:weightWidget]).to eq(weight: 3)
        expect(input[:statusWidget]).to eq(status: 'gid://gitlab/WorkItems::Statuses::SystemDefined::Status/1')
        expect(input[:agentPlanWidget]).to eq(content: 'Plan content')
      end
    end

    context 'with readiness_score' do
      it 'maps readiness_score to agentPlanWidget' do
        params[:readiness_score] = 70

        expect(tool.build_variables[:input][:agentPlanWidget]).to eq(readinessScore: 70)
      end

      it 'combines readiness_score with agent_plan content' do
        params.merge!(agent_plan: 'Plan content', readiness_score: 70)

        expect(tool.build_variables[:input][:agentPlanWidget]).to eq(content: 'Plan content', readinessScore: 70)
      end
    end

    context 'with update-only params' do
      update_only = {
        state: 'closed',
        add_label_ids: ['1'],
        remove_label_ids: ['1'],
        todo_action: 'add',
        todo_id: '1',
        clear_weight: true
      }

      update_only.each do |param, value|
        it "rejects #{param}" do
          params[param] = value

          expect { tool.build_variables }
            .to raise_error(ArgumentError, "#{param} can only be used when updating (provide work_item_iid)")
        end
      end
    end

    context 'without a title' do
      let(:params) { { project_id: project.id.to_s, type_name: 'Issue' } }

      it 'raises an error' do
        expect { tool.build_variables }
          .to raise_error(ArgumentError, 'title is required when creating a work item')
      end
    end

    context 'without a type name' do
      let(:params) { { project_id: project.id.to_s, title: 'New item' } }

      it 'raises an error' do
        expect { tool.build_variables }
          .to raise_error(ArgumentError, 'type_name is required when creating a work item')
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
    let(:params) do
      {
        project_id: project.id.to_s,
        title: 'Created via MCP',
        type_name: 'Issue',
        description: 'A description',
        label_ids: [label.id.to_s],
        start_date: '2026-01-01',
        due_date: '2026-01-31'
      }
    end

    it 'creates a work item and returns the compact payload', :aggregate_failures do
      result = tool.execute

      expect(result[:isError]).to be(false)
      expect(result[:structuredContent].keys).to match_array(%w[id iid type title state confidential web_url])
      expect(result[:structuredContent]['type']).to eq('Issue')
      expect(result[:structuredContent]['title']).to eq('Created via MCP')
      expect(result[:structuredContent]['state']).to eq('OPEN')
      expect(result[:structuredContent]['confidential']).to be(false)

      created = WorkItem.find(GlobalID.parse(result[:structuredContent]['id']).model_id.to_i)
      expect(created.description).to eq('A description')
      expect(created.labels).to contain_exactly(label)
      expect(created.start_date).to eq(Date.parse('2026-01-01'))
      expect(created.due_date).to eq(Date.parse('2026-01-31'))
    end

    context 'when the project does not exist' do
      let(:params) { { project_id: 'nonexistent/project', title: 'New item', type_name: 'Issue' } }

      it 'raises an error' do
        expect { tool.execute }.to raise_error(StandardError, /not found or inaccessible/)
      end
    end

    context 'when the user cannot access the project' do
      let_it_be(:private_project) { create(:project, :private) }

      let(:params) { { project_id: private_project.id.to_s, title: 'New item', type_name: 'Issue' } }

      it 'raises an error' do
        expect { tool.execute }.to raise_error(StandardError, /not found or inaccessible/)
      end
    end
  end
end
