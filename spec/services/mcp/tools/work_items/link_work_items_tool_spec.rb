# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::WorkItems::LinkWorkItemsTool, feature_category: :mcp_server do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:source_work_item) { create(:work_item, :issue, project: project, iid: 1) }
  let_it_be(:target_work_item) { create(:work_item, :issue, project: project, iid: 2) }

  let(:target_gid) { target_work_item.to_global_id.to_s }
  let(:params) do
    {
      project_id: project.id.to_s,
      work_item_iid: source_work_item.iid,
      work_items_ids: [target_gid]
    }
  end

  let(:tool) { described_class.new(current_user: user, params: params) }

  before_all do
    project.add_developer(user)
  end

  describe 'class methods' do
    describe '.build_mutation' do
      it 'returns the GraphQL mutation string' do
        mutation = described_class.build_mutation

        expect(mutation).to include('mutation LinkWorkItems($input: WorkItemAddLinkedItemsInput!)')
        expect(mutation).to include('workItemAddLinkedItems(input: $input)')
        expect(mutation).to include('workItem {')
        expect(mutation).to include('id')
        expect(mutation).to include('iid')
        expect(mutation).to include('title')
        expect(mutation).to include('message')
        expect(mutation).to include('errors')
      end
    end
  end

  describe 'versioning' do
    it 'registers version using VERSIONS constant' do
      expect(tool.version).to eq(Mcp::Tools::Concerns::Constants::VERSIONS[:v0_1_0])
    end

    it 'has correct operation name for version 0.1.0' do
      expect(tool.operation_name).to eq('workItemAddLinkedItems')
    end

    it 'has correct GraphQL operation for version 0.1.0' do
      operation = tool.graphql_operation

      expect(operation).to include('mutation LinkWorkItems')
      expect(operation).to include('workItemAddLinkedItems(input: $input)')
    end
  end

  describe '#build_variables' do
    context 'with valid params' do
      it 'builds variables with source work item ID and target IDs' do
        variables = tool.build_variables

        expect(variables[:input]).to include(
          id: source_work_item.to_global_id.to_s,
          workItemsIds: [target_gid]
        )
      end

      it 'defaults link_type to RELATED when not provided' do
        variables = tool.build_variables

        expect(variables[:input][:linkType]).to eq('RELATED')
      end

      it 'maps link_type relates_to to RELATED' do
        params[:link_type] = 'relates_to'
        variables = tool.build_variables

        expect(variables[:input][:linkType]).to eq('RELATED')
      end

      it 'accepts multiple target work item IDs' do
        another_gid = "gid://gitlab/WorkItem/#{target_work_item.id + 1}"
        params[:work_items_ids] = [target_gid, another_gid]
        variables = tool.build_variables

        expect(variables[:input][:workItemsIds]).to match_array([target_gid, another_gid])
      end
    end

    context 'with URL-based identification' do
      let(:params) do
        {
          url: "https://gitlab.com/#{project.full_path}/-/work_items/#{source_work_item.iid}",
          work_items_ids: [target_gid]
        }
      end

      it 'resolves source work item from URL' do
        variables = tool.build_variables

        expect(variables[:input][:id]).to eq(source_work_item.to_global_id.to_s)
      end
    end

    context 'when link_type is blank' do
      let(:params) do
        {
          project_id: project.id.to_s,
          work_item_iid: source_work_item.iid,
          work_items_ids: [target_gid],
          link_type: ''
        }
      end

      it 'defaults to RELATED' do
        variables = tool.build_variables

        expect(variables[:input][:linkType]).to eq('RELATED')
      end
    end

    context 'when link_type is relates_to' do
      let(:params) do
        {
          project_id: project.id.to_s,
          work_item_iid: source_work_item.iid,
          work_items_ids: [target_gid],
          link_type: 'relates_to'
        }
      end

      it 'maps to RELATED' do
        variables = tool.build_variables

        expect(variables[:input][:linkType]).to eq('RELATED')
      end
    end

    context 'when work_items_ids contains an invalid ID format' do
      where(:invalid_id) do
        [
          ['not-a-gid'],
          ['gid://gitlab/Issue/123'],
          ['123'],
          ['']
        ]
      end

      with_them do
        let(:params) do
          {
            project_id: project.id.to_s,
            work_item_iid: source_work_item.iid,
            work_items_ids: [invalid_id]
          }
        end

        it 'raises ArgumentError with descriptive message' do
          expect { tool.build_variables }
            .to raise_error(ArgumentError, /Invalid work item ID format/)
        end
      end
    end

    context 'when link_type is invalid' do
      let(:params) do
        {
          project_id: project.id.to_s,
          work_item_iid: source_work_item.iid,
          work_items_ids: [target_gid],
          link_type: 'invalid_type'
        }
      end

      it 'raises ArgumentError' do
        expect { tool.build_variables }
          .to raise_error(ArgumentError, /Invalid link_type/)
      end
    end

    context 'when source work item does not exist' do
      let(:params) do
        {
          project_id: project.id.to_s,
          work_item_iid: non_existing_record_iid,
          work_items_ids: [target_gid]
        }
      end

      it 'raises ArgumentError' do
        expect { tool.build_variables }
          .to raise_error(ArgumentError, "Work item ##{non_existing_record_iid} not found")
      end
    end

    context 'when user lacks access to source work item' do
      let_it_be(:private_project) { create(:project, :private) }
      let(:params) do
        {
          project_id: private_project.id.to_s,
          work_item_iid: 1,
          work_items_ids: [target_gid]
        }
      end

      it 'raises ArgumentError' do
        expect { tool.build_variables }
          .to raise_error(ArgumentError, /Access denied to project/)
      end
    end
  end

  describe 'integration' do
    it 'executes mutation with correct variables' do
      allow(GitlabSchema).to receive(:execute).and_call_original

      tool.execute

      expect(GitlabSchema).to have_received(:execute).with(
        anything,
        variables: hash_including(
          input: hash_including(
            id: source_work_item.to_global_id.to_s,
            workItemsIds: [target_gid],
            linkType: 'RELATED'
          )
        ),
        context: hash_including(current_user: user)
      )
    end

    it 'returns linked work item data' do
      result = tool.execute

      expect(result[:isError]).to be(false)
      expect(result[:structuredContent]['workItem']).to be_a(Hash)
      expect(result[:structuredContent]['workItem']['iid'].to_i).to eq(source_work_item.iid)
    end

    context 'when source work item does not exist' do
      let(:params) do
        {
          project_id: project.id.to_s,
          work_item_iid: non_existing_record_iid,
          work_items_ids: [target_gid]
        }
      end

      it 'raises error before executing GraphQL' do
        expect { tool.execute }.to raise_error(ArgumentError, "Work item ##{non_existing_record_iid} not found")
      end
    end

    context 'when user lacks permission' do
      let_it_be(:private_project) { create(:project, :private) }
      let(:params) do
        {
          project_id: private_project.id.to_s,
          work_item_iid: 1,
          work_items_ids: [target_gid]
        }
      end

      it 'raises error before executing GraphQL' do
        expect { tool.execute }.to raise_error(ArgumentError, /Access denied to project/)
      end
    end
  end
end
