# frozen_string_literal: true

RSpec.shared_examples 'group and project packages query' do
  include GraphqlHelpers

  let_it_be(:versionless_package) { create(:maven_package, project: project1, version: nil) }
  let_it_be(:maven_package) { create(:maven_package, project: project1, name: 'bab', version: '6.0.0', created_at: 1.day.ago) }
  let_it_be(:npm_package) { create(:npm_package, project: project1, name: 'cab', version: '7.0.0', created_at: 4.days.ago) }
  let_it_be(:composer_package) { create(:composer_package, project: project2, name: 'dab', version: '4.0.0', created_at: 3.days.ago) }
  let_it_be(:debian_package) { create(:debian_package, project: project2, name: 'aab', version: '5.0.0', created_at: 2.days.ago) }
  let_it_be(:composer_metadatum) do
    create(:composer_metadatum,
      package: composer_package,
      target_sha: 'afdeh',
      composer_json: { name: 'x', type: 'y', license: 'z', version: 1 })
  end

  let(:package_names) { graphql_data_at(resource_type, :packages, :nodes, :name) }
  let(:target_shas) { graphql_data_at(resource_type, :packages, :nodes, :metadata, :target_sha) }
  let(:packages) { graphql_data_at(resource_type, :packages, :nodes) }
  let(:packages_count) { graphql_data_at(resource_type, :packages, :count) }

  let(:fields) do
    <<~QUERY
      count
      nodes {
        #{all_graphql_fields_for('packages'.classify, excluded: ['project'])}
        metadata { #{query_graphql_fragment('ComposerMetadata')} }
      }
    QUERY
  end

  let(:query) do
    graphql_query_for(
      resource_type,
      { 'fullPath' => resource.full_path },
      query_graphql_field('packages', {}, fields)
    )
  end

  context 'when user has access to the resource' do
    before do
      resource.add_reporter(current_user)
      post_graphql(query, current_user: current_user)
    end

    it_behaves_like 'a working graphql query that returns data'

    it 'returns packages successfully' do
      expect(package_names).to contain_exactly(
        npm_package.name,
        maven_package.name,
        debian_package.name,
        composer_package.name
      )
    end

    it 'deals with metadata' do
      expect(target_shas.compact).to contain_exactly(composer_metadatum.target_sha)
    end

    it 'returns the count of the packages' do
      expect(packages_count).to eq(4)
    end

    context '_links' do
      let_it_be(:errored_package) { create(:maven_package, :error, project: project1) }

      let(:package_web_paths) { graphql_data_at(resource_type, :packages, :nodes, :_links, :web_path) }

      it 'does not contain the web path of errored package' do
        expect(package_web_paths.compact).to contain_exactly(
          "/#{project1.full_path}/-/packages/#{npm_package.id}",
          "/#{project1.full_path}/-/packages/#{maven_package.id}",
          "/#{project2.full_path}/-/packages/#{debian_package.id}",
          "/#{project2.full_path}/-/packages/#{composer_package.id}"
        )
      end
    end
  end

  context 'when the user does not have access to the resource' do
    before do
      post_graphql(query, current_user: current_user)
    end

    it_behaves_like 'a working graphql query that returns no data'
  end

  context 'when the user is not authenticated' do
    before do
      post_graphql(query)
    end

    it_behaves_like 'a working graphql query that returns no data'
  end

  describe 'sorting and pagination' do
    let_it_be(:packages_order_map) do
      {
        TYPE_ASC: [maven_package, npm_package, composer_package, debian_package],
        TYPE_DESC: [debian_package, composer_package, npm_package, maven_package],

        NAME_ASC: [debian_package, maven_package, npm_package, composer_package],
        NAME_DESC: [composer_package, npm_package, maven_package, debian_package],

        VERSION_ASC: [composer_package, debian_package, maven_package, npm_package],
        VERSION_DESC: [npm_package, maven_package, debian_package, composer_package],

        CREATED_ASC: [npm_package, composer_package, debian_package, maven_package],
        CREATED_DESC: [maven_package, debian_package, composer_package, npm_package]
      }
    end

    let(:expected_packages) { sorted_packages.map { |package| global_id_of(package).to_s } }

    let(:data_path) { [resource_type, :packages] }

    before do
      resource.add_reporter(current_user)
    end

    [:CREATED_ASC, :NAME_ASC, :VERSION_ASC, :TYPE_ASC, :CREATED_DESC, :NAME_DESC, :VERSION_DESC, :TYPE_DESC].each do |order|
      context order.to_s do
        let(:sorted_packages) { packages_order_map.fetch(order) }

        it_behaves_like 'sorted paginated query' do
          let(:sort_param) { order }
          let(:first_param) { 4 }
          let(:all_records) { expected_packages }
        end
      end
    end

    context 'with an invalid sort' do
      let(:query) do
        graphql_query_for(
          resource_type,
          { 'fullPath' => resource.full_path },
          query_nodes(:packages, :name, args: { sort: :WRONG_ORDER })
        )
      end

      before do
        post_graphql(query, current_user: current_user)
      end

      it 'throws an error' do
        expect_graphql_errors_to_include(/Argument 'sort' on Field 'packages' has an invalid value/)
      end
    end

    def pagination_query(params)
      graphql_query_for(resource_type, { 'fullPath' => resource.full_path },
        query_nodes(:packages, :id, include_pagination_info: true, args: params)
      )
    end
  end

  describe 'filtering' do
    subject { packages }

    let(:query) do
      graphql_query_for(
        resource_type,
        { 'fullPath' => resource.full_path },
        query_nodes(:packages, :name, args: params)
      )
    end

    before do
      resource.add_reporter(current_user)
      post_graphql(query, current_user: current_user)
    end

    context 'package_name' do
      let(:params) { { package_name: maven_package.name } }

      it { is_expected.to contain_exactly({ "name" => maven_package.name }) }
    end

    context 'package_type' do
      let(:params) { { package_type: :COMPOSER } }

      it { is_expected.to contain_exactly({ "name" => composer_package.name }) }
    end

    context 'status' do
      let_it_be(:errored_package) { create(:maven_package, project: project1, status: 'error') }

      let(:params) { { status: :ERROR } }

      it { is_expected.to contain_exactly({ "name" => errored_package.name }) }
    end

    context 'include_versionless' do
      let(:params) { { include_versionless: true } }

      it { is_expected.to include({ "name" => versionless_package.name }) }
    end
  end

  context 'when reading pipelines' do
    let(:npm_pipelines) { create_list(:ci_pipeline, 6, project: project1) }
    let(:npm_pipeline_gids) { npm_pipelines.sort_by(&:id).map(&:to_gid).map(&:to_s).reverse }
    let(:composer_pipelines) { create_list(:ci_pipeline, 6, project: project2) }
    let(:composer_pipeline_gids) { composer_pipelines.sort_by(&:id).map(&:to_gid).map(&:to_s).reverse }
    let(:npm_end_cursor) { graphql_data_npm_package.dig('pipelines', 'pageInfo', 'endCursor') }
    let(:npm_start_cursor) { graphql_data_npm_package.dig('pipelines', 'pageInfo', 'startCursor') }
    let(:pipelines_nodes) do
      <<~QUERY
        nodes {
          id
        }
        pageInfo {
          startCursor
          endCursor
        }
      QUERY
    end

    before do
      resource.add_maintainer(current_user)

      npm_pipelines.each do |pipeline|
        create(:package_build_info, package: npm_package, pipeline: pipeline)
      end

      composer_pipelines.each do |pipeline|
        create(:package_build_info, package: composer_package, pipeline: pipeline)
      end
    end

    it 'loads the second page with pagination first correctly' do
      run_query(first: 2)
      expect(npm_pipeline_ids).to eq(npm_pipeline_gids[0..1])
      expect(composer_pipeline_ids).to eq(composer_pipeline_gids[0..1])

      run_query(first: 2, after: npm_end_cursor)
      expect(npm_pipeline_ids).to eq(npm_pipeline_gids[2..3])
      expect(composer_pipeline_ids).to be_empty
    end

    it 'loads the second page with pagination last correctly' do
      run_query(last: 2)
      expect(npm_pipeline_ids).to eq(npm_pipeline_gids[4..5])
      expect(composer_pipeline_ids).to eq(composer_pipeline_gids[4..5])

      run_query(last: 2, before: npm_start_cursor)
      expect(npm_pipeline_ids).to eq(npm_pipeline_gids[2..3])
      expect(composer_pipeline_ids).to eq(composer_pipeline_gids[4..5])
    end

    def run_query(args)
      pipelines_field = query_graphql_field('pipelines', args, pipelines_nodes)

      packages_nodes = <<~QUERY
        nodes {
          id
          #{pipelines_field}
        }
      QUERY

      query = graphql_query_for(
        resource_type,
        { 'fullPath' => resource.full_path },
        query_graphql_field('packages', {}, packages_nodes)
      )

      post_graphql(query, current_user: current_user)
    end

    def npm_pipeline_ids
      graphql_data_npm_package.dig('pipelines', 'nodes').pluck('id')
    end

    def composer_pipeline_ids
      graphql_data_composer_package.dig('pipelines', 'nodes').pluck('id')
    end

    def graphql_data_npm_package
      graphql_data_at(resource_type, :packages, :nodes).find { |pkg| pkg['id'] == npm_package.to_gid.to_s }
    end

    def graphql_data_composer_package
      graphql_data_at(resource_type, :packages, :nodes).find { |pkg| pkg['id'] == composer_package.to_gid.to_s }
    end
  end
end
