# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Getting designs related to an issue' do
  include GraphqlHelpers
  include DesignManagementTestHelpers

  let_it_be(:design) { create(:design, :with_smaller_image_versions, versions_count: 1) }
  let_it_be(:current_user) { design.project.owner }

  let(:design_query) do
    <<~NODE
    designs {
      edges {
        node {
          id
          filename
          fullPath
          event
          image
          imageV432x230
        }
      }
    }
    NODE
  end

  let(:issue) { design.issue }
  let(:project) { issue.project }
  let(:query) { make_query }
  let(:design_collection) do
    graphql_data_at(:project, :issue, :design_collection)
  end

  let(:design_response) do
    design_collection.dig('designs', 'edges').first['node']
  end

  def make_query(dq = design_query)
    designs_field = query_graphql_field(:design_collection, {}, dq)
    issue_field = query_graphql_field(:issue, { iid: issue.iid.to_s }, designs_field)

    graphql_query_for(:project, { fullPath: project.full_path }, issue_field)
  end

  def design_image_url(design, ref: nil, size: nil)
    Gitlab::UrlBuilder.build(design, ref: ref, size: size)
  end

  context 'when the feature is available' do
    before do
      enable_design_management
    end

    it 'returns the design properties correctly' do
      version_sha = design.versions.first.sha

      post_graphql(query, current_user: current_user)

      expect(design_response).to eq(
        'id' => design.to_global_id.to_s,
        'event' => 'CREATION',
        'fullPath' => design.full_path,
        'filename' => design.filename,
        'image' => design_image_url(design, ref: version_sha),
        'imageV432x230' => design_image_url(design, ref: version_sha, size: :v432x230)
      )
    end

    context 'when the v432x230-sized design image has not been processed' do
      before do
        allow_next_instance_of(DesignManagement::DesignV432x230Uploader) do |uploader|
          allow(uploader).to receive(:file).and_return(nil)
        end
      end

      it 'returns nil for the v432x230-sized design image' do
        post_graphql(query, current_user: current_user)

        expect(design_response['imageV432x230']).to be_nil
      end
    end

    describe 'pagination' do
      before do
        create_list(:design, 5, :with_file, issue: issue)
        project.add_developer(current_user)
        post_graphql(query, current_user: current_user)
      end

      let(:issue) { create(:issue) }

      let(:end_cursor) { design_collection.dig('designs', 'pageInfo', 'endCursor') }

      let(:ids) { issue.designs.order(:id).map { |d| global_id_of(d) } }

      let(:query) { make_query(designs_fragment(first: 2)) }

      let(:design_query_fields) { 'pageInfo { endCursor } edges { node { id } }' }

      let(:cursored_query) do
        make_query(designs_fragment(after: end_cursor))
      end

      def designs_fragment(params)
        query_graphql_field(:designs, params, design_query_fields)
      end

      def response_ids(data = graphql_data)
        path = %w[project issue designCollection designs edges]
        data.dig(*path).map { |e| e.dig('node', 'id') }
      end

      it 'sorts designs for reliable pagination' do
        expect(response_ids).to match_array(ids.take(2))

        post_graphql(cursored_query, current_user: current_user)

        new_data = Gitlab::Json.parse(response.body).fetch('data')

        expect(response_ids(new_data)).to match_array(ids.drop(2))
      end
    end

    context 'with versions' do
      let_it_be(:version) { design.versions.take }

      let(:design_query) do
        <<~NODE
        designs {
          edges {
            node {
              filename
              versions {
                edges {
                  node {
                    id
                    sha
                  }
                }
              }
            }
          }
        }
        NODE
      end

      it 'includes the version id' do
        post_graphql(query, current_user: current_user)

        version_id = design_response['versions']['edges'].first['node']['id']

        expect(version_id).to eq(version.to_global_id.to_s)
      end

      it 'includes the version sha' do
        post_graphql(query, current_user: current_user)

        version_sha = design_response['versions']['edges'].first['node']['sha']

        expect(version_sha).to eq(version.sha)
      end
    end

    describe 'viewing a design board at a particular version' do
      let_it_be(:issue) { design.issue }
      let_it_be(:second_design, reload: true) { create(:design, :with_smaller_image_versions, issue: issue, versions_count: 1) }
      let_it_be(:deleted_design) { create(:design, :with_versions, issue: issue, deleted: true, versions_count: 1) }

      let(:all_versions) { issue.design_versions.ordered.reverse }
      let(:design_query) do
        <<~NODE
        designs(atVersion: "#{version.to_global_id}") {
          edges {
            node {
              id
              image
              imageV432x230
              event
              versions {
                edges {
                  node {
                    id
                  }
                }
              }
            }
          }
        }
        NODE
      end

      let(:design_response) do
        design_collection['designs']['edges']
      end

      def global_id(object)
        object.to_global_id.to_s
      end

      # Filters just design nodes from the larger `design_response`
      def design_nodes
        design_response.map do |response|
          response['node']
        end
      end

      # Filters just version nodes from the larger `design_response`
      def version_nodes
        design_response.map do |response|
          response.dig('node', 'versions', 'edges')
        end
      end

      context 'viewing the original version, when one design was created' do
        let(:version) { all_versions.first }

        before do
          post_graphql(query, current_user: current_user)
        end

        it 'only returns the first design' do
          expect(design_nodes).to contain_exactly(
            a_hash_including('id' => global_id(design))
          )
        end

        it 'returns the correct full-sized design image' do
          expect(design_nodes).to contain_exactly(
            a_hash_including('image' => design_image_url(design, ref: version.sha))
          )
        end

        it 'returns the correct v432x230-sized design image' do
          expect(design_nodes).to contain_exactly(
            a_hash_including('imageV432x230' => design_image_url(design, ref: version.sha, size: :v432x230))
          )
        end

        it 'returns the correct event for the design in this version' do
          expect(design_nodes).to contain_exactly(
            a_hash_including('event' => 'CREATION')
          )
        end

        it 'only returns one version record for the design (the original version)' do
          expect(version_nodes).to eq([
            [{ 'node' => { 'id' => global_id(version) } }]
          ])
        end
      end

      context 'viewing the second version, when one design was created' do
        let(:version) { all_versions.second }

        before do
          post_graphql(query, current_user: current_user)
        end

        it 'only returns the first two designs' do
          expect(design_nodes).to contain_exactly(
            a_hash_including('id' => global_id(design)),
            a_hash_including('id' => global_id(second_design))
          )
        end

        it 'returns the correct full-sized design images' do
          expect(design_nodes).to contain_exactly(
            a_hash_including('image' => design_image_url(design, ref: version.sha)),
            a_hash_including('image' => design_image_url(second_design, ref: version.sha))
          )
        end

        it 'returns the correct v432x230-sized design images' do
          expect(design_nodes).to contain_exactly(
            a_hash_including('imageV432x230' => design_image_url(design, ref: version.sha, size: :v432x230)),
            a_hash_including('imageV432x230' => design_image_url(second_design, ref: version.sha, size: :v432x230))
          )
        end

        it 'returns the correct events for the designs in this version' do
          expect(design_nodes).to contain_exactly(
            a_hash_including('event' => 'NONE'),
            a_hash_including('event' => 'CREATION')
          )
        end

        it 'returns the correct versions records for both designs' do
          expect(version_nodes).to eq([
            [{ 'node' => { 'id' => global_id(design.versions.first) } }],
            [{ 'node' => { 'id' => global_id(second_design.versions.first) } }]
          ])
        end
      end

      context 'viewing the last version, when one design was deleted and one was updated' do
        let(:version) { all_versions.last }
        let!(:second_design_update) do
          create(:design_action, :with_image_v432x230, design: second_design, version: version, event: 'modification')
        end

        before do
          post_graphql(query, current_user: current_user)
        end

        it 'does not include the deleted design' do
          # The design does exist in the version
          expect(version.designs).to include(deleted_design)

          # But the GraphQL API does not include it in these results
          expect(design_nodes).to contain_exactly(
            a_hash_including('id' => global_id(design)),
            a_hash_including('id' => global_id(second_design))
          )
        end

        it 'returns the correct full-sized design images' do
          expect(design_nodes).to contain_exactly(
            a_hash_including('image' => design_image_url(design, ref: version.sha)),
            a_hash_including('image' => design_image_url(second_design, ref: version.sha))
          )
        end

        it 'returns the correct v432x230-sized design images' do
          expect(design_nodes).to contain_exactly(
            a_hash_including('imageV432x230' => design_image_url(design, ref: version.sha, size: :v432x230)),
            a_hash_including('imageV432x230' => design_image_url(second_design, ref: version.sha, size: :v432x230))
          )
        end

        it 'returns the correct events for the designs in this version' do
          expect(design_nodes).to contain_exactly(
            a_hash_including('event' => 'NONE'),
            a_hash_including('event' => 'MODIFICATION')
          )
        end

        it 'returns all versions records for the designs' do
          expect(version_nodes).to eq([
            [
              { 'node' => { 'id' => global_id(design.versions.first) } }
            ],
            [
              { 'node' => { 'id' => global_id(second_design.versions.second) } },
              { 'node' => { 'id' => global_id(second_design.versions.first) } }
            ]
          ])
        end
      end
    end

    describe 'a design with note annotations' do
      let_it_be(:note) { create(:diff_note_on_design, noteable: design) }

      let(:design_query) do
        <<~NODE
        designs {
          edges {
            node {
              notesCount
              notes {
                edges {
                  node {
                    id
                  }
                }
              }
            }
          }
        }
        NODE
      end

      let(:design_response) do
        design_collection['designs']['edges'].first['node']
      end

      before do
        post_graphql(query, current_user: current_user)
      end

      it 'returns the notes for the design' do
        expect(design_response.dig('notes', 'edges')).to eq(
          ['node' => { 'id' => note.to_global_id.to_s }]
        )
      end

      it 'returns a note_count for the design' do
        expect(design_response['notesCount']).to eq(1)
      end
    end
  end
end
