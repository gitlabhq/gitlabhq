# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::Wikis::ListWikiPagesTool, feature_category: :mcp_server do
  let_it_be(:user) { create(:user) }
  let_it_be(:group, freeze: false) { create(:group) }
  let_it_be(:project, freeze: false) { create(:project, :public) }

  let(:params) { { project_id: project.full_path } }

  subject(:tool) { described_class.new(current_user: user, params: params) }

  before_all do
    project.add_developer(user)
    group.add_developer(user)
  end

  describe '#graphql_operation' do
    shared_examples 'a wiki pages query document' do
      it 'includes wiki page fields', :aggregate_failures do
        expect(query).to include('$fullPath: ID!')
        expect(query).to include('wikiPages')
        expect(query).to include('nodes')
        expect(query).to include('title')
        expect(query).to include('slug')
        expect(query).to include('webUrl')
      end

      it 'includes pagination arguments and pageInfo', :aggregate_failures do
        expect(query).to include('$first: Int')
        expect(query).to include('$after: String')
        expect(query).to include('wikiPages(first: $first, after: $after)')
        expect(query).to include('pageInfo')
        expect(query).to include('endCursor')
      end
    end

    context 'when listing project wiki pages' do
      let(:query) { tool.graphql_operation }

      it 'returns the project query document', :aggregate_failures do
        expect(query).to include('query listProjectWikiPages')
        expect(query).to include('project(fullPath: $fullPath)')
        expect(query).not_to include('group(')
      end

      it_behaves_like 'a wiki pages query document'
    end
  end

  describe 'versioning' do
    it 'registers version 0.1.0' do
      expect(tool.version).to eq(Mcp::Tools::Concerns::Constants::VERSIONS[:v0_1_0])
    end

    it 'has correct operation name for project' do
      expect(tool.operation_name).to eq('project')
    end

    it 'has correct GraphQL operation for version 0.1.0' do
      operation = tool.graphql_operation

      expect(operation).to include('query listProjectWikiPages')
    end

    context 'when listing group wiki pages' do
      let(:params) { { group_id: group.full_path } }

      it 'has correct operation name' do
        expect(tool.operation_name).to eq('group')
      end
    end
  end

  describe 'container identification' do
    context 'when only group_id is provided' do
      let(:params) { { group_id: group.full_path } }

      it 'targets the group', :aggregate_failures do
        expect(tool.send(:group_request?)).to be(true)
        expect(tool.build_variables[:fullPath]).to eq(group.full_path)
      end
    end

    context 'when neither project_id nor group_id is provided' do
      let(:params) { {} }

      it 'raises an ArgumentError' do
        expect { tool.build_variables }.to raise_error(
          ArgumentError, 'Provide exactly one of project_id or group_id.'
        )
      end
    end

    context 'when both project_id and group_id are provided' do
      let(:params) { { project_id: project.full_path, group_id: group.full_path } }

      it 'raises an ArgumentError' do
        expect { tool.build_variables }.to raise_error(
          ArgumentError, 'Provide exactly one of project_id or group_id.'
        )
      end
    end
  end

  describe '#build_variables' do
    it 'builds variables from params', :aggregate_failures do
      variables = tool.build_variables

      expect(variables[:fullPath]).to eq(project.full_path)
      expect(variables).not_to have_key(:isProject)
    end

    it 'defaults first to DEFAULT_PAGE_SIZE when not provided' do
      expect(tool.build_variables[:first]).to eq(described_class::DEFAULT_PAGE_SIZE)
    end

    context 'when first and after are provided' do
      let(:params) { { project_id: project.full_path, first: 5, after: 'CURSOR' } }

      it 'passes them through', :aggregate_failures do
        variables = tool.build_variables

        expect(variables[:first]).to eq(5)
        expect(variables[:after]).to eq('CURSOR')
      end
    end

    context 'when project_id is a numeric ID' do
      let(:params) { { project_id: project.id.to_s } }

      it 'resolves the numeric ID to the project full path' do
        expect(tool.build_variables[:fullPath]).to eq(project.full_path)
      end
    end
  end

  describe '#process_result' do
    def process(result)
      allow(GitlabSchema).to receive(:execute).and_return(result)
      tool.execute
    end

    context 'when result contains errors' do
      let(:result) do
        {
          'errors' => ['Some error occurred'],
          'data' => { 'project' => { 'wikiPages' => [] } }
        }
      end

      it 'returns error response', :aggregate_failures do
        processed = process(result)

        expect(processed[:isError]).to be(true)
        expect(processed[:content]).to be_an(Array)
        expect(processed[:content].first[:text]).to eq('Some error occurred')
      end
    end

    context 'when the container is not found' do
      let(:result) { { 'data' => { 'project' => nil } } }

      it 'returns a project not found error', :aggregate_failures do
        processed = process(result)

        expect(processed[:isError]).to be(true)
        expect(processed[:content].first[:text]).to eq(
          "Project not found, or you do not have access to it."
        )
      end
    end

    context 'when the wiki is unavailable' do
      let(:result) { { 'data' => { 'project' => { 'wikiPages' => nil } } } }

      it 'returns an actionable unavailable message', :aggregate_failures do
        processed = process(result)

        expect(processed[:isError]).to be(true)
        expect(processed[:content].first[:text]).to include("This wiki isn't available")
      end
    end

    context 'when wikiPages has no nodes' do
      let(:result) { { 'data' => { 'project' => { 'wikiPages' => {} } } } }

      it 'falls back to the unavailable message', :aggregate_failures do
        processed = process(result)

        expect(processed[:isError]).to be(true)
        expect(processed[:content].first[:text]).to include("This wiki isn't available")
      end
    end

    context 'when wiki pages are returned with pagination' do
      let(:result) do
        {
          'data' => {
            'project' => {
              'wikiPages' => {
                'nodes' => [
                  { 'title' => 'Home', 'slug' => 'home',
                    'webUrl' => 'http://localhost/group/project/-/wikis/home' },
                  { 'title' => 'Orphan', 'slug' => nil, 'webUrl' => nil }
                ],
                'pageInfo' => { 'endCursor' => 'CURSOR' }
              }
            }
          }
        }
      end

      it 'drops null-slug rows, returns slug, and surfaces web URLs and pagination metadata',
        :aggregate_failures do
        processed = process(result)
        items = processed[:structuredContent][:items]

        expect(processed[:isError]).to be(false)
        expect(items.map { |n| n['webUrl'] }).to eq(['http://localhost/group/project/-/wikis/home'])
        expect(items.map { |n| n['title'] }).to eq(['Home'])
        expect(items.map { |n| n['slug'] }).to eq(['home'])
        expect(processed[:structuredContent][:metadata]).to eq(
          end_cursor: 'CURSOR'
        )
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
          fullPath: project.full_path
        ),
        context: hash_including(current_user: user)
      )
    end

    it 'returns wiki pages data with proper formatting', :aggregate_failures do
      # Create the real Gitaly-backed page inside the example. Gitaly writes are not rolled back
      # between examples, so a page created in a shared before-all hook can be wiped by another
      # group's cleanup before this example reads it, causing an order-dependent empty result.
      wiki_page_meta = create(:wiki_page_meta, :for_wiki_page, container: project)

      result = tool.execute

      expect(result[:isError]).to be(false)
      expect(result[:content]).to be_an(Array)
      expect(result[:content].first[:type]).to eq('text')
      expect(result[:structuredContent]).to be_a(Hash)
      expect(result[:structuredContent]).to have_key(:items)
      first_item = result[:structuredContent][:items].first
      expect(first_item).to include('title' => wiki_page_meta.title)
      expect(first_item['webUrl']).to include("#{project.full_path}/-/wikis/")
      expect(first_item['slug']).to be_present
      expect(result[:structuredContent][:metadata]).to have_key(:end_cursor)
    end

    context 'when the project does not exist' do
      let(:params) { { project_id: 'non-such-group/no-such-project' } }

      it 'raises before executing GraphQL' do
        expect { tool.execute }.to raise_error(StandardError, /not found or inaccessible/)
      end
    end

    # Group wiki support is added by the EE extension; the group integration path is covered in
    # ee/spec. Here we assert the FOSS guard by simulating an instance where it is unavailable.
    context 'when group wikis are not supported' do
      let(:params) { { group_id: group.full_path } }

      before do
        allow(tool).to receive(:group_wikis_supported?).and_return(false)
      end

      it 'returns an unavailable message without executing a query', :aggregate_failures do
        expect(GitlabSchema).not_to receive(:execute)

        result = tool.execute

        expect(result[:isError]).to be(true)
        expect(result[:content].first[:text]).to include(
          "This wiki isn't available"
        )
      end
    end
  end
end
