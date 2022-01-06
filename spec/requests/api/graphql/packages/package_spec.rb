# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'package details' do
  include GraphqlHelpers

  let_it_be_with_reload(:project) { create(:project) }
  let_it_be(:composer_package) { create(:composer_package, project: project) }
  let_it_be(:composer_json) { { name: 'name', type: 'type', license: 'license', version: 1 } }
  let_it_be(:composer_metadatum) do
    # we are forced to manually create the metadatum, without using the factory to force the sha to be a string
    # and avoid an error where gitaly can't find the repository
    create(:composer_metadatum, package: composer_package, target_sha: 'foo_sha', composer_json: composer_json)
  end

  let(:depth) { 3 }
  let(:excluded) { %w[metadata apiFuzzingCiConfiguration pipeline packageFiles] }
  let(:metadata) { query_graphql_fragment('ComposerMetadata') }
  let(:package_files) {all_graphql_fields_for('PackageFile')}
  let(:user) { project.owner }
  let(:package_global_id) { global_id_of(composer_package) }
  let(:package_details) { graphql_data_at(:package) }

  let(:query) do
    graphql_query_for(:package, { id: package_global_id }, <<~FIELDS)
    #{all_graphql_fields_for('PackageDetailsType', max_depth: depth, excluded: excluded)}
    metadata {
      #{metadata}
    }
    packageFiles {
      nodes {
        #{package_files}
      }
    }
    FIELDS
  end

  subject { post_graphql(query, current_user: user) }

  it_behaves_like 'a working graphql query' do
    before do
      subject
    end

    it 'matches the JSON schema' do
      expect(package_details).to match_schema('graphql/packages/package_details')
    end
  end

  context 'there are other versions of this package' do
    let(:depth) { 3 }
    let(:excluded) { %w[metadata project tags pipelines] } # to limit the query complexity

    let_it_be(:siblings) { create_list(:composer_package, 2, project: project, name: composer_package.name) }

    it 'includes the sibling versions' do
      subject

      expect(graphql_data_at(:package, :versions, :nodes)).to match_array(
        siblings.map { |p| a_hash_including('id' => global_id_of(p)) }
      )
    end

    context 'going deeper' do
      let(:depth) { 6 }

      it 'does not create a cycle of versions' do
        subject

        expect(graphql_data_at(:package, :versions, :nodes, :version)).to be_present
        expect(graphql_data_at(:package, :versions, :nodes, :versions, :nodes)).to eq [nil, nil]
      end
    end
  end

  context 'with package files pending destruction' do
    let_it_be(:package_file) { create(:package_file, package: composer_package) }
    let_it_be(:package_file_pending_destruction) { create(:package_file, :pending_destruction, package: composer_package) }

    let(:package_file_ids) { graphql_data_at(:package, :package_files, :nodes).map { |node| node["id"] } }

    it 'does not return them' do
      subject

      expect(package_file_ids).to contain_exactly(package_file.to_global_id.to_s)
    end

    context 'with packages_installable_package_files disabled' do
      before do
        stub_feature_flags(packages_installable_package_files: false)
      end

      it 'returns them' do
        subject

        expect(package_file_ids).to contain_exactly(package_file_pending_destruction.to_global_id.to_s, package_file.to_global_id.to_s)
      end
    end
  end

  context 'with a batched query' do
    let_it_be(:conan_package) { create(:conan_package, project: project) }

    let(:batch_query) do
      <<~QUERY
      {
        a: package(id: "#{global_id_of(composer_package)}") { name }
        b: package(id: "#{global_id_of(conan_package)}") { name }
      }
      QUERY
    end

    let(:a_packages_names) { graphql_data_at(:a, :packages, :nodes, :name) }

    it 'returns an error for the second package and data for the first' do
      post_graphql(batch_query, current_user: user)

      expect(graphql_data_at(:a, :name)).to eq(composer_package.name)

      expect_graphql_errors_to_include [/Package details can be requested only for one package at a time/]
      expect(graphql_data_at(:b)).to be(nil)
    end
  end

  context 'with unauthorized user' do
    let_it_be(:user) { create(:user) }

    before do
      project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
    end

    it 'returns no packages' do
      subject

      expect(graphql_data_at(:package)).to be_nil
    end
  end

  context 'pipelines field', :aggregate_failures do
    let(:pipelines) { create_list(:ci_pipeline, 6, project: project) }
    let(:pipeline_gids) { pipelines.sort_by(&:id).map(&:to_gid).map(&:to_s).reverse }

    before do
      composer_package.pipelines = pipelines
      composer_package.save!
    end

    def run_query(args)
      pipelines_nodes = <<~QUERY
      nodes {
        id
      }
      pageInfo {
        startCursor
        endCursor
      }
      QUERY

      query = graphql_query_for(:package, { id: package_global_id }, query_graphql_field("pipelines", args, pipelines_nodes))
      post_graphql(query, current_user: user)
    end

    it 'loads the second page with pagination first correctly' do
      run_query(first: 2)
      pipeline_ids = graphql_data.dig('package', 'pipelines', 'nodes').pluck('id')

      expect(pipeline_ids).to eq(pipeline_gids[0..1])

      cursor = graphql_data.dig('package', 'pipelines', 'pageInfo', 'endCursor')

      run_query(first: 2, after: cursor)

      pipeline_ids = graphql_data.dig('package', 'pipelines', 'nodes').pluck('id')

      expect(pipeline_ids).to eq(pipeline_gids[2..3])
    end

    it 'loads the second page with pagination last correctly' do
      run_query(last: 2)
      pipeline_ids = graphql_data.dig('package', 'pipelines', 'nodes').pluck('id')

      expect(pipeline_ids).to eq(pipeline_gids[4..5])

      cursor = graphql_data.dig('package', 'pipelines', 'pageInfo', 'startCursor')

      run_query(last: 2, before: cursor)

      pipeline_ids = graphql_data.dig('package', 'pipelines', 'nodes').pluck('id')

      expect(pipeline_ids).to eq(pipeline_gids[2..3])
    end

    context 'with unauthorized user' do
      let_it_be(:user) { create(:user) }

      before do
        project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
      end

      it 'returns no packages' do
        run_query(first: 2)

        expect(graphql_data_at(:package)).to be_nil
      end
    end
  end
end
