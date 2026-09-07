# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::WorkItems::GetWorkItemService, feature_category: :mcp_server do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:work_item) { create(:work_item, project: project, title: 'An issue') }

  let(:service) { described_class.new(name: 'get_work_item') }
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

    it 'has a description mentioning work item' do
      expect(service.description).to include('work item')
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
              description: 'GitLab URL of the work item (a /-/work_items/, /-/issues/, or /-/epics/ URL). ' \
                'Provide this, or work_item_iid with group_id or project_id.'
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
              description: 'Internal ID of the work item. Required if url is not provided.'
            },
            include: {
              type: 'array',
              items: {
                type: 'string',
                enum: %w[notes related_merge_requests]
              },
              maxItems: 1,
              description: 'Associated data to return with the work item, one facet per call. ' \
                'notes returns up to 100 notes per call and paginates with the notes_* ' \
                'parameters; for the newest notes, use notes_last without notes_first or ' \
                'notes_after. related_merge_requests paginates with the ' \
                'related_merge_requests_* parameters and is empty for group-level work items ' \
                'such as epics.'
            },
            notes_first: {
              type: 'integer',
              minimum: 1,
              maximum: 100,
              description: 'Number of notes to return after the cursor (forward pagination). ' \
                'Default 100, max 100. Applies only when notes is in include.'
            },
            notes_after: {
              type: 'string',
              description: 'Cursor for forward pagination of notes. Use pageInfo.endCursor ' \
                'from a previous response. Applies only when notes is in include.'
            },
            notes_last: {
              type: 'integer',
              minimum: 1,
              maximum: 100,
              description: 'Number of notes to return before the cursor (backward pagination). ' \
                'Default 100, max 100. Applies only when notes is in include.'
            },
            notes_before: {
              type: 'string',
              description: 'Cursor for backward pagination of notes. Use pageInfo.startCursor ' \
                'from a previous response. Applies only when notes is in include.'
            },
            related_merge_requests_first: {
              type: 'integer',
              minimum: 1,
              maximum: 100,
              description: 'Number of related merge requests to return after the cursor ' \
                '(forward pagination). Default 20, max 100. ' \
                'Applies only when related_merge_requests is in include.'
            },
            related_merge_requests_after: {
              type: 'string',
              description: 'Cursor for forward pagination of related merge requests. ' \
                'Use pageInfo.endCursor from a previous response. ' \
                'Applies only when related_merge_requests is in include.'
            },
            mr_page_size: {
              type: 'integer',
              minimum: 1,
              maximum: 100,
              description: 'DEPRECATED: use related_merge_requests_first instead.'
            },
            mr_pagination_cursor: {
              type: 'string',
              description: 'DEPRECATED: use related_merge_requests_after instead.'
            }
          }
        }
      )
    end
  end

  describe '#execute' do
    context 'when identifying the work item by project_id and iid' do
      let(:params) { { arguments: { project_id: project.id.to_s, work_item_iid: work_item.iid } } }

      it 'returns the work item' do
        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be(false)
        expect(result[:structuredContent]['title']).to eq('An issue')
      end
    end

    context 'when paginating notes' do
      let_it_be(:old_note) { create(:note, noteable: work_item, project: project, note: 'first note') }
      let_it_be(:new_note) { create(:note, noteable: work_item, project: project, note: 'second note') }

      let(:base_arguments) do
        { project_id: project.id.to_s, work_item_iid: work_item.iid, include: %w[notes] }
      end

      def notes_widget(result)
        result[:structuredContent]['widgets'].find { |w| w['notes'] }['notes']
      end

      it 'pages forward with notes_first and notes_after', :aggregate_failures do
        first_page = service.execute(request: request, params: { arguments: base_arguments.merge(notes_first: 1) })

        widget = notes_widget(first_page)
        expect(widget['nodes'].map { |n| n['body'] }).to eq(['first note'])
        expect(widget['pageInfo']['hasNextPage']).to be(true)

        second_page = service.execute(
          request: request,
          params: { arguments: base_arguments.merge(notes_first: 1, notes_after: widget['pageInfo']['endCursor']) }
        )

        expect(notes_widget(second_page)['nodes'].map { |n| n['body'] }).to eq(['second note'])
      end

      it 'pages backward with notes_last and notes_before', :aggregate_failures do
        last_page = service.execute(request: request, params: { arguments: base_arguments.merge(notes_last: 1) })

        widget = notes_widget(last_page)
        expect(widget['nodes'].map { |n| n['body'] }).to eq(['second note'])
        expect(widget['pageInfo']['hasPreviousPage']).to be(true)

        previous_page = service.execute(
          request: request,
          params: { arguments: base_arguments.merge(notes_last: 1, notes_before: widget['pageInfo']['startCursor']) }
        )

        expect(notes_widget(previous_page)['nodes'].map { |n| n['body'] }).to eq(['first note'])
      end

      it 'ignores stray pagination params when notes is not included', :aggregate_failures do
        result = service.execute(
          request: request,
          params: { arguments: { project_id: project.id.to_s, work_item_iid: work_item.iid,
                                 notes_first: 1, notes_last: 1 } }
        )

        expect(result[:isError]).to be(false)
        expect(result[:structuredContent]['title']).to eq('An issue')
      end

      it 'rejects mixing both pagination directions', :aggregate_failures do
        result = service.execute(
          request: request,
          params: { arguments: base_arguments.merge(notes_first: 1, notes_last: 1) }
        )

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('not both directions')
      end
    end

    context 'when include requests more than one facet' do
      let(:params) do
        {
          arguments: {
            project_id: project.id.to_s,
            work_item_iid: work_item.iid,
            include: %w[notes related_merge_requests]
          }
        }
      end

      it 'returns a validation error' do
        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be(true)
      end
    end

    context 'when no identification is provided' do
      let(:params) { { arguments: { include: %w[notes] } } }

      it 'returns a validation error' do
        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to match(/work_item_iid/)
      end
    end
  end
end
