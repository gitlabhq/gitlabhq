# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::WorkItems::SaveWorkItemService, feature_category: :mcp_server do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public) }
  let_it_be_with_reload(:work_item) { create(:work_item, :issue, project: project, title: 'Original title') }

  let(:service) { described_class.new(name: 'save_work_item') }
  let(:request) { instance_double(ActionDispatch::Request) }

  before_all do
    project.add_developer(user)
  end

  before do
    service.set_cred(current_user: user)
  end

  describe 'class configuration' do
    it 'inherits from GraphqlService' do
      expect(described_class.superclass).to eq(Mcp::Tools::Base::GraphqlService)
    end

    it 'registers version 0.1.0' do
      expect(described_class.available_versions).to include('0.1.0')
    end

    it 'has readOnlyHint: false and destructiveHint: false annotations' do
      expect(service.annotations).to eq(readOnlyHint: false, destructiveHint: false)
    end
  end

  describe 'tool aliases' do
    it 'exposes create_work_item and update_work_item as aliases' do
      expect(described_class.tool_aliases).to eq(%w[create_work_item update_work_item])
    end

    it 'resolves the aliases through the manager', :aggregate_failures do
      manager = Mcp::Tools::Manager.new

      expect(manager.get_tool(name: 'create_work_item')).to be_a(described_class)
      expect(manager.get_tool(name: 'update_work_item')).to be_a(described_class)
    end
  end

  describe 'input schema' do
    it 'matches the expected contract' do
      expect(described_class.version_metadata('0.1.0')[:input_schema]).to eq(
        {
          type: 'object',
          properties: {
            url: {
              type: 'string',
              description: 'GitLab URL for the project, group, or work item. ' \
                'Provide exactly one of url, project_id, or group_id.'
            },
            group_id: {
              type: 'string',
              description: 'ID or path of the group. Required if URL and project_id are not provided.'
            },
            project_id: {
              type: 'string',
              description: 'ID or path of the project. Required if URL and group_id are not provided.'
            },
            work_item_iid: {
              type: 'integer',
              description: 'Positive internal ID of the work item to update. Omit to create a new work item.'
            },
            title: {
              type: 'string',
              description: 'Title. Required on create.'
            },
            type_name: {
              type: 'string',
              description: 'Work item type name, for example "Issue", "Task", "Epic". Required on create. ' \
                'Valid types depend on the namespace and license; invalid values return the list of valid ones.'
            },
            description: {
              type: 'string',
              description: 'Description in GitLab Flavored Markdown (max 1,048,576 characters).',
              maxLength: 1_048_576
            },
            assignee_ids: {
              type: 'array',
              items: { type: 'integer' },
              maxItems: 100,
              description: 'User IDs to assign to the work item.'
            },
            label_ids: {
              type: 'array',
              items: { type: 'string' },
              maxItems: 100,
              description: 'Label IDs or global IDs. Create only; on update use add_label_ids/remove_label_ids.'
            },
            labels: {
              type: 'array',
              items: { type: 'string' },
              maxItems: 100,
              description: 'Names of the labels to set, resolved in the project or group and its ' \
                'ancestor groups. Create only; on update use add_labels/remove_labels.'
            },
            add_label_ids: {
              type: 'array',
              items: { type: 'string' },
              maxItems: 100,
              description: 'Update only. Label IDs or global IDs to add.'
            },
            add_labels: {
              type: 'array',
              items: { type: 'string' },
              maxItems: 100,
              description: 'Update only. Names of the labels to add.'
            },
            remove_label_ids: {
              type: 'array',
              items: { type: 'string' },
              maxItems: 100,
              description: 'Update only. Label IDs or global IDs to remove.'
            },
            remove_labels: {
              type: 'array',
              items: { type: 'string' },
              maxItems: 100,
              description: 'Update only. Names of the labels to remove.'
            },
            milestone_id: {
              type: 'string',
              description: 'ID or global ID of the milestone to assign, validated against the ' \
                'project or group and its ancestor groups. Wins over milestone when both are given.'
            },
            milestone: {
              type: 'string',
              description: 'Title of the milestone to assign, resolved among the milestones of ' \
                'the project or group and its ancestor groups.'
            },
            confidential: {
              type: 'boolean',
              description: 'Sets the work item confidentiality.'
            },
            start_date: {
              type: 'string',
              description: 'Start date, YYYY-MM-DD.'
            },
            due_date: {
              type: 'string',
              description: 'Due date, YYYY-MM-DD.'
            },
            state: {
              type: 'string',
              enum: %w[opened closed],
              description: 'Update only. closed closes the work item, opened reopens it.'
            },
            parent_id: {
              type: 'string',
              description: 'Global ID or numeric ID of the parent work item (hierarchy).'
            },
            todo_action: {
              type: 'string',
              enum: %w[add mark_as_done],
              description: 'Update only. add adds a to-do for the current user, ' \
                'mark_as_done marks to-dos as done.'
            },
            todo_id: {
              type: 'string',
              description: 'Update only. Global ID or numeric ID of the to-do; ' \
                'omit to update all to-dos on the work item.'
            }
          },
          required: []
        }
      )
    end
  end

  describe '#execute' do
    context 'without work_item_iid' do
      let(:params) do
        { arguments: { project_id: project.id.to_s, title: 'Created via MCP', type_name: 'Issue' } }
      end

      it 'routes to the create tool' do
        expect(Mcp::Tools::WorkItems::CreateWorkItemTool).to receive(:new).with(
          current_user: user,
          params: params[:arguments],
          version: '0.1.0'
        ).and_call_original

        service.execute(request: request, params: params)
      end

      it 'creates a work item and returns the compact payload', :aggregate_failures do
        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be(false)
        expect(result[:structuredContent].keys).to match_array(%w[id iid type title state confidential web_url])
        expect(result[:structuredContent]['type']).to eq('Issue')
        expect(result[:structuredContent]['title']).to eq('Created via MCP')
        expect(result[:structuredContent]['state']).to eq('OPEN')
      end
    end

    context 'with label names and milestone parameters' do
      let_it_be(:group) { create(:group, :public) }
      let_it_be(:labeled_project) { create(:project, :public, group: group, developers: [user]) }
      let_it_be(:bug_label) { create(:label, project: labeled_project, title: 'bug') }
      let_it_be(:critical_label) { create(:group_label, group: group, title: 'critical') }
      let_it_be(:milestone) { create(:milestone, project: labeled_project, title: '19.4') }
      let_it_be_with_reload(:target) { create(:work_item, :issue, project: labeled_project, title: 'Target') }

      let(:create_arguments) do
        { project_id: labeled_project.id.to_s, title: 'Labeled', type_name: 'Issue' }
      end

      it 'creates with label names and a milestone title', :aggregate_failures do
        result = service.execute(
          request: request,
          params: { arguments: create_arguments.merge(labels: %w[bug critical], milestone: '19.4') }
        )

        expect(result[:isError]).to be(false)
        created = labeled_project.work_items.find_by!(title: 'Labeled')
        expect(created.labels.map(&:title)).to match_array(%w[bug critical])
        expect(created.milestone).to eq(milestone)
      end

      it 'merges label names with label ids', :aggregate_failures do
        result = service.execute(
          request: request,
          params: { arguments: create_arguments.merge(label_ids: [bug_label.id.to_s], labels: %w[critical]) }
        )

        expect(result[:isError]).to be(false)
        created = labeled_project.work_items.find_by!(title: 'Labeled')
        expect(created.labels.map(&:title)).to match_array(%w[bug critical])
      end

      it 'assigns a milestone by id, winning over a resolvable title', :aggregate_failures do
        other = create(:milestone, project: labeled_project, title: 'other')

        result = service.execute(
          request: request,
          params: { arguments: create_arguments.merge(milestone_id: other.id.to_s, milestone: '19.4') }
        )

        expect(result[:isError]).to be(false)
        expect(labeled_project.work_items.find_by!(title: 'Labeled').milestone).to eq(other)
      end

      it 'assigns a milestone by global ID', :aggregate_failures do
        result = service.execute(
          request: request,
          params: { arguments: create_arguments.merge(milestone_id: milestone.to_global_id.to_s) }
        )

        expect(result[:isError]).to be(false)
        expect(labeled_project.work_items.find_by!(title: 'Labeled').milestone).to eq(milestone)
      end

      it 'rejects an unknown label name with the unmatched names', :aggregate_failures do
        result = nil

        expect do
          result = service.execute(request: request,
            params: { arguments: create_arguments.merge(labels: %w[bug nope]) })
        end
          .not_to change { WorkItem.count }

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('Labels not found').and include('nope')
      end

      it 'resolves a milestone title from an ancestor group', :aggregate_failures do
        group_milestone = create(:milestone, group: group, title: 'Group Q4')

        result = service.execute(
          request: request,
          params: { arguments: create_arguments.merge(milestone: 'Group Q4') }
        )

        expect(result[:isError]).to be(false)
        expect(labeled_project.work_items.find_by!(title: 'Labeled').milestone).to eq(group_milestone)
      end

      it 'strips surrounding whitespace from label names', :aggregate_failures do
        result = service.execute(
          request: request,
          params: { arguments: create_arguments.merge(labels: [' bug ']) }
        )

        expect(result[:isError]).to be(false)
        expect(labeled_project.work_items.find_by!(title: 'Labeled').labels.map(&:title)).to eq(%w[bug])
      end

      it 'strips surrounding whitespace from the milestone title', :aggregate_failures do
        result = service.execute(
          request: request,
          params: { arguments: create_arguments.merge(milestone: ' 19.4 ') }
        )

        expect(result[:isError]).to be(false)
        expect(labeled_project.work_items.find_by!(title: 'Labeled').milestone).to eq(milestone)
      end

      it 'rejects a milestone id outside the project and its ancestors', :aggregate_failures do
        foreign_milestone = create(:milestone, project: create(:project, :public))

        result = service.execute(
          request: request,
          params: { arguments: create_arguments.merge(milestone_id: foreign_milestone.id.to_s) }
        )

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text])
          .to include("Milestone with id #{foreign_milestone.id} not found")
      end

      it 'sets a milestone on update', :aggregate_failures do
        result = service.execute(
          request: request,
          params: { arguments: { project_id: labeled_project.id.to_s, work_item_iid: target.iid,
                                 milestone: '19.4' } }
        )

        expect(result[:isError]).to be(false)
        expect(target.reload.milestone).to eq(milestone)
      end

      it 'dedups a label given by id and by name', :aggregate_failures do
        result = service.execute(
          request: request,
          params: { arguments: create_arguments.merge(label_ids: [bug_label.id.to_s], labels: %w[bug]) }
        )

        expect(result[:isError]).to be(false)
        expect(labeled_project.work_items.find_by!(title: 'Labeled').labels.map(&:title)).to eq(%w[bug])
      end

      it 'merges remove_label_ids with remove_labels on update', :aggregate_failures do
        target.labels = [bug_label, critical_label]

        result = service.execute(
          request: request,
          params: {
            arguments: {
              project_id: labeled_project.id.to_s, work_item_iid: target.iid,
              remove_label_ids: [bug_label.id.to_s], remove_labels: %w[critical]
            }
          }
        )

        expect(result[:isError]).to be(false)
        expect(target.reload.labels).to be_empty
      end

      it 'rejects an unknown milestone title', :aggregate_failures do
        result = service.execute(
          request: request,
          params: { arguments: create_arguments.merge(milestone: 'no-such-milestone') }
        )

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include("Milestone 'no-such-milestone' not found")
      end

      it 'adds and removes labels by name on update', :aggregate_failures do
        target.labels << bug_label

        result = service.execute(
          request: request,
          params: {
            arguments: {
              project_id: labeled_project.id.to_s, work_item_iid: target.iid,
              add_labels: %w[critical], remove_labels: %w[bug]
            }
          }
        )

        expect(result[:isError]).to be(false)
        expect(target.reload.labels.map(&:title)).to eq(%w[critical])
      end

      it 'rejects labels on update and add_labels on create', :aggregate_failures do
        update_result = service.execute(
          request: request,
          params: { arguments: { project_id: labeled_project.id.to_s, work_item_iid: target.iid,
                                 labels: %w[bug] } }
        )
        create_result = service.execute(
          request: request,
          params: { arguments: create_arguments.merge(add_labels: %w[bug]) }
        )

        expect(update_result[:isError]).to be(true)
        expect(update_result[:content].first[:text]).to include('labels can only be used when creating')
        expect(create_result[:isError]).to be(true)
        expect(create_result[:content].first[:text]).to include('add_labels can only be used when updating')
      end
    end

    context 'with a zero work_item_iid from a zero-filling client' do
      let(:params) do
        {
          arguments: {
            project_id: project.id.to_s, work_item_iid: 0, url: '',
            title: 'Created despite zero iid', type_name: 'Issue'
          }
        }
      end

      it 'routes to the create tool and creates the work item', :aggregate_failures do
        # Blank strings are stripped by BaseService#reject_omitted_arguments before dispatch.
        expect(Mcp::Tools::WorkItems::CreateWorkItemTool).to receive(:new).with(
          current_user: user,
          params: params[:arguments].except(:url),
          version: '0.1.0'
        ).and_call_original

        result = nil

        expect { result = service.execute(request: request, params: params) }
          .to change { WorkItem.count }.by(1)

        expect(result[:isError]).to be(false)
        expect(result[:structuredContent]['title']).to eq('Created despite zero iid')
      end

      context 'when the iid is negative' do
        let(:params) do
          { arguments: { project_id: project.id.to_s, work_item_iid: -1, title: 'Negative iid', type_name: 'Issue' } }
        end

        it 'also routes to the create tool' do
          expect(Mcp::Tools::WorkItems::CreateWorkItemTool).to receive(:new).and_call_original

          expect { service.execute(request: request, params: params) }
            .to change { WorkItem.count }.by(1)
        end
      end
    end

    context 'with a zero work_item_iid and zero-filled update-only params' do
      let(:params) do
        {
          arguments: {
            project_id: project.id.to_s, work_item_iid: 0, title: 'Zero-filled', type_name: 'Issue',
            state: 'opened', todo_id: '', add_label_ids: [], remove_label_ids: []
          }
        }
      end

      it 'fails on the create path with a self-correcting message', :aggregate_failures do
        result = nil

        expect { result = service.execute(request: request, params: params) }
          .not_to change { WorkItem.count }

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text])
          .to eq('Validation error: state can only be used when updating (provide work_item_iid)')
      end
    end

    context 'with work_item_iid' do
      let(:params) do
        { arguments: { project_id: project.id.to_s, work_item_iid: work_item.iid, title: 'Updated via MCP' } }
      end

      it 'routes to the update tool' do
        expect(Mcp::Tools::WorkItems::UpdateWorkItemTool).to receive(:new).with(
          current_user: user,
          params: params[:arguments],
          version: '0.1.0'
        ).and_call_original

        service.execute(request: request, params: params)
      end

      it 'updates the work item and returns the compact payload', :aggregate_failures do
        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be(false)
        expect(result[:structuredContent]['title']).to eq('Updated via MCP')
        expect(work_item.reload.title).to eq('Updated via MCP')
      end
    end

    context 'with a work item URL' do
      let(:params) do
        {
          arguments: {
            url: "https://gitlab.com/#{project.full_path}/-/work_items/#{work_item.iid}",
            title: 'Updated via URL'
          }
        }
      end

      it 'routes to the update tool' do
        expect(Mcp::Tools::WorkItems::UpdateWorkItemTool).to receive(:new).with(
          current_user: user,
          params: params[:arguments],
          version: '0.1.0'
        ).and_call_original

        service.execute(request: request, params: params)
      end
    end

    context 'with an issue URL' do
      let(:params) do
        { arguments: { url: "https://gdk.test/#{project.full_path}/-/issues/42", title: 'Updated via URL' } }
      end

      it 'routes to the update tool and fails without creating a work item', :aggregate_failures do
        expect(Mcp::Tools::WorkItems::UpdateWorkItemTool).to receive(:new).with(
          current_user: user,
          params: params[:arguments],
          version: '0.1.0'
        ).and_call_original

        result = nil

        expect { result = service.execute(request: request, params: params) }
          .not_to change { WorkItem.count }

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text])
          .to eq('Validation error: Work item #42 not found or inaccessible')
      end
    end

    context 'when creating without a title' do
      let(:params) { { arguments: { project_id: project.id.to_s, type_name: 'Issue' } } }

      it 'returns a validation error' do
        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to eq('Validation error: title is required when creating a work item')
      end
    end

    context 'when creating without a type name' do
      let(:params) { { arguments: { project_id: project.id.to_s, title: 'Created via MCP' } } }

      it 'returns a validation error' do
        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text])
          .to eq('Validation error: type_name is required when creating a work item')
      end
    end
  end
end
