# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::WorkItems::ListWorkItemsService, feature_category: :mcp_server do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:project) { create(:project, :public, group: group) }
  let_it_be(:work_item) { create(:work_item, project: project, title: 'An issue') }

  let(:service) { described_class.new(name: 'list_work_items') }
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

    it 'has a description mentioning work items' do
      expect(service.description).to include('work items')
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
              description: 'GitLab URL for the project or group.'
            },
            group_id: {
              type: 'string',
              description: 'ID or path of the group. Required if URL and project_id are not provided.'
            },
            project_id: {
              type: 'string',
              description: 'ID or path of the project. Required if URL and group_id are not provided.'
            },
            state: {
              type: 'string',
              enum: %w[opened closed all],
              description: 'Filter by state. Default is all.'
            },
            search: {
              type: 'string',
              description: 'Free-text search in title and description.'
            },
            author_username: {
              type: 'string',
              description: 'Username of the author.'
            },
            assignee_usernames: {
              type: 'array',
              items: { type: 'string' },
              maxItems: 100,
              description: 'Usernames of assignees. A work item must match all of them.'
            },
            label_name: {
              type: 'array',
              items: { type: 'string' },
              maxItems: 100,
              description: 'Label names. A work item must have all of them.'
            },
            milestone_title: {
              type: 'array',
              items: { type: 'string' },
              maxItems: 100,
              description: 'Milestone titles. Cannot be combined with milestone_wildcard_id.'
            },
            milestone_wildcard_id: {
              type: 'string',
              enum: %w[NONE ANY STARTED UPCOMING],
              description: 'Milestone wildcard. Cannot be combined with milestone_title.'
            },
            types: {
              type: 'array',
              items: {
                type: 'string',
                enum: %w[ISSUE INCIDENT TEST_CASE REQUIREMENT TASK TICKET OBJECTIVE KEY_RESULT EPIC]
              },
              description: 'Work item types to include, for example ["ISSUE", "TASK"].'
            },
            created_after: {
              type: 'string',
              description: 'Created after this time (ISO 8601; date-only means start of day, offsets honored).'
            },
            created_before: {
              type: 'string',
              description: 'Created before this time (ISO 8601; date-only means start of day, offsets honored).'
            },
            updated_after: {
              type: 'string',
              description: 'Updated after this time (ISO 8601; date-only means start of day, offsets honored).'
            },
            updated_before: {
              type: 'string',
              description: 'Updated before this time (ISO 8601; date-only means start of day, offsets honored).'
            },
            due_after: {
              type: 'string',
              description: 'Due after this time (ISO 8601; date-only means start of day, offsets honored).'
            },
            due_before: {
              type: 'string',
              description: 'Due before this time (ISO 8601; date-only means start of day, offsets honored).'
            },
            sort: {
              type: 'string',
              enum: %w[
                CLOSED_AT_ASC CLOSED_AT_DESC ESCALATION_STATUS_ASC ESCALATION_STATUS_DESC
                POPULARITY_ASC POPULARITY_DESC PRIORITY_ASC PRIORITY_DESC RELATIVE_POSITION_ASC
                SEVERITY_ASC SEVERITY_DESC UPDATED_DESC UPDATED_ASC CREATED_DESC CREATED_ASC
                TITLE_ASC TITLE_DESC
              ],
              description: 'Sort order. Default is CREATED_DESC.'
            },
            first: {
              type: 'integer',
              minimum: 1,
              maximum: 100,
              description: 'Number of work items to return. Default 20, max 100.'
            },
            after: {
              type: 'string',
              description: 'Cursor for forward pagination. Use endCursor from the previous response.'
            }
          }
        }
      )
    end

    it 'keeps the sort enum in lock-step with the model sorting keys' do
      model_keys = ::WorkItems::SortingKeys.all.keys.map { |key| key.to_s.upcase }

      expect(described_class::SORT_VALUES).to all(be_in(model_keys))
    end

    it 'keeps the types enum in lock-step with the GraphQL enum' do
      expect(described_class::TYPE_VALUES).to eq(::Types::IssueTypeEnum.values.keys)
    end
  end

  describe '#execute' do
    context 'when identifying the namespace by project_id' do
      let(:params) { { arguments: { project_id: project.id.to_s } } }

      it 'returns work items with pagination info', :aggregate_failures do
        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be(false)
        expect(result[:structuredContent]['work_items'].pluck('title')).to include('An issue')
        expect(result[:structuredContent]['pageInfo']).to include('endCursor', 'hasNextPage')
      end
    end

    context 'when no identification is provided' do
      let(:params) { { arguments: { state: 'opened' } } }

      it 'returns a validation error' do
        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to match(/project_id or group_id/)
      end
    end

    context 'when current_user is not set' do
      let(:params) { { arguments: { project_id: project.id.to_s } } }

      it 'returns an error' do
        service.set_cred(current_user: nil)
        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be(true)
      end
    end
  end
end
