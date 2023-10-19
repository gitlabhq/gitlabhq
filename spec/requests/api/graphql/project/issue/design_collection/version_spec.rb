# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.project(fullPath).issue(iid).designCollection.version(sha)',
  feature_category: :design_management do
  include GraphqlHelpers
  include DesignManagementTestHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:developer) { create(:user) }
  let_it_be(:stranger) { create(:user) }
  let_it_be(:old_version) do
    create(:design_version, issue: issue, created_designs: create_list(:design, 3, issue: issue))
  end

  let_it_be(:version) do
    create(:design_version,
      issue: issue,
      modified_designs: old_version.designs,
      created_designs: create_list(:design, 2, issue: issue))
  end

  let(:current_user) { developer }

  def query(vq = version_fields)
    graphql_query_for(:project, { fullPath: project.full_path },
      query_graphql_field(:issue, { iid: issue.iid.to_s },
        query_graphql_field(:design_collection, nil,
          query_graphql_field(:version, { sha: version.sha }, vq))))
  end

  let(:post_query) { post_graphql(query, current_user: current_user) }
  let(:path_prefix) { %w[project issue designCollection version] }

  let(:data) { graphql_data.dig(*path) }

  before do
    enable_design_management
    project.add_developer(developer)
  end

  describe 'scalar fields' do
    let(:path) { path_prefix }

    before do
      post_query
    end

    { id: ->(x) { x.to_global_id.to_s }, sha: ->(x) { x.sha } }.each do |field, value|
      describe ".#{field}" do
        let(:version_fields) { field }

        it "retrieves the #{field}" do
          expect(data).to match(a_hash_including(field.to_s => value[version]))
        end
      end
    end
  end

  describe 'design_at_version' do
    let(:path) { path_prefix + %w[designAtVersion] }
    let(:design) { issue.designs.visible_at_version(version).to_a.sample }
    let(:design_at_version) { build(:design_at_version, design: design, version: version) }

    let(:version_fields) do
      query_graphql_field(:design_at_version, dav_params, 'id filename')
    end

    shared_examples 'finds dav' do
      it 'finds all the designs as of the given version' do
        post_query

        expect(data).to match a_graphql_entity_for(design_at_version, filename: design.filename)
      end

      context 'when the current_user is not authorized' do
        let(:current_user) { stranger }

        it 'returns nil' do
          post_query

          expect(data).to be_nil
        end
      end
    end

    context 'by ID' do
      let(:dav_params) { { id: global_id_of(design_at_version) } }

      include_examples 'finds dav'
    end

    context 'by filename' do
      let(:dav_params) { { filename: design.filename } }

      include_examples 'finds dav'
    end

    context 'by design_id' do
      let(:dav_params) { { design_id: global_id_of(design) } }

      include_examples 'finds dav'
    end
  end

  describe 'designs_at_version' do
    let(:path) { path_prefix + %w[designsAtVersion edges] }
    let(:version_fields) do
      query_graphql_field(:designs_at_version, dav_params, 'edges { node { id filename } }')
    end

    let(:dav_params) { nil }

    let(:results) do
      issue.designs.visible_at_version(version).map do |d|
        dav = build(:design_at_version, design: d, version: version)

        a_graphql_entity_for(dav, filename: d.filename)
      end
    end

    it 'finds all the designs as of the given version' do
      post_query

      expect(data.pluck('node')).to match_array(results)
    end

    describe 'filtering' do
      let(:designs) { issue.designs.sample(3) }
      let(:filenames) { designs.map(&:filename) }
      let(:expected_designs) do
        designs.map { |d| a_graphql_entity_for(build(:design_at_version, design: d, version: version)) }
      end

      before do
        post_query
      end

      describe 'by filename' do
        let(:dav_params) { { filenames: filenames } }

        it 'finds the designs by filename' do
          expect(data.map { |e| e['node'] }).to match_array expected_designs
        end
      end

      describe 'by design-id' do
        let(:dav_params) { { ids: designs.map { |d| global_id_of(d) } } }

        it 'finds the designs by id' do
          expect(data.map { |e| e.dig('node', 'filename') }).to match_array(filenames)
        end
      end
    end

    describe 'pagination' do
      let(:end_cursor) { graphql_data_at(*path_prefix, :designs_at_version, :page_info, :end_cursor) }

      let(:entities) do
        ::DesignManagement::Design.visible_at_version(version).order(:id).map do |d|
          a_graphql_entity_for(build(:design_at_version, design: d, version: version))
        end
      end

      let(:version_fields) do
        query_graphql_field(:designs_at_version, { first: 2 }, fields)
      end

      let(:cursored_query) do
        frag = query_graphql_field(:designs_at_version, { after: end_cursor }, fields)
        query(frag)
      end

      let(:fields) { ['pageInfo { endCursor }', 'edges { node { id } }'] }

      def response_values(data = graphql_data)
        data.dig(*path).map { |e| e['node'] }
      end

      it 'sorts designs for reliable pagination' do
        post_graphql(query, current_user: current_user)

        expect(response_values).to match_array(entities.take(2))

        post_graphql(cursored_query, current_user: current_user)

        new_data = Gitlab::Json.parse(response.body).fetch('data')

        expect(response_values(new_data)).to match_array(entities.drop(2))
      end
    end
  end

  describe 'designs' do
    let(:path) { path_prefix + %w[designs edges] }
    let(:version_fields) do
      query_graphql_field(:designs, nil, 'edges { node { id filename } }')
    end

    let(:results) do
      version.designs.map { |design| a_graphql_entity_for(design, :filename) }
    end

    it 'finds all the designs as of the given version' do
      post_query

      expect(data.pluck('node')).to match_array(results)
    end
  end
end
