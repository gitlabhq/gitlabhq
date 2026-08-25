# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::Projects::ListProjectMembersService, feature_category: :mcp_server do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public) }

  let(:service) { described_class.new(name: 'list_project_members') }

  before_all do
    project.add_maintainer(user)
  end

  before do
    service.set_cred(current_user: user)
  end

  describe 'class configuration' do
    it 'registers version 0.1.0' do
      expect(described_class.available_versions).to include('0.1.0')
    end

    it 'locks the description' do
      expect(described_class.version_metadata('0.1.0')[:description]).to eq(
        'List the members of a GitLab project with their role and access level. ' \
          'Direct members only, unless include_inherited is true.'
      )
    end
  end

  describe 'input schema' do
    it 'locks the full input schema for version 0.1.0' do
      expect(described_class.version_metadata('0.1.0')[:input_schema]).to eq({
        type: 'object',
        required: %w[project_id],
        properties: {
          project_id: {
            type: 'string',
            description: 'ID or full path of the project'
          },
          include_inherited: {
            type: 'boolean',
            description: 'Include members inherited from parent groups. Defaults to false.'
          },
          query: {
            type: 'string',
            description: 'Filter by name or username.'
          },
          after: {
            type: 'string',
            description: 'Cursor for forward pagination. Use metadata.end_cursor from the ' \
              'previous response.'
          },
          first: {
            type: 'integer',
            description: 'Number of members to return (forward pagination, default ' \
              "#{described_class::DEFAULT_PAGE_SIZE}, max #{described_class::MAX_PAGE_SIZE}).",
            minimum: 1,
            maximum: described_class::MAX_PAGE_SIZE
          }
        }
      })
    end

    it 'rejects unknown arguments' do
      expect(service.input_schema[:additionalProperties]).to be(false)
    end
  end

  describe '#execute' do
    let(:request) { instance_double(ActionDispatch::Request) }
    let(:params) { { arguments: { project_id: project.id.to_s } } }

    it 'returns the project members', :aggregate_failures do
      result = service.execute(request: request, params: params)

      expect(result[:isError]).to be(false)
      expect(result[:structuredContent][:items].pluck(:username))
        .to contain_exactly(user.username, project.first_owner.username)
    end

    it 'instantiates the tool with the resolved version and arguments' do
      expect(Mcp::Tools::Projects::ListProjectMembersTool).to receive(:new).with(
        current_user: user,
        params: params[:arguments],
        version: '0.1.0'
      ).and_call_original

      service.execute(request: request, params: params)
    end

    context 'when project_id is missing' do
      let(:params) { { arguments: {} } }

      it 'returns a validation error', :aggregate_failures do
        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('project_id is missing')
      end
    end

    context 'when current_user is not set' do
      before do
        service.set_cred(current_user: nil)
      end

      it 'returns an error response', :aggregate_failures do
        result = service.execute(request: request, params: params)

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include('current_user is not set')
      end
    end
  end
end
