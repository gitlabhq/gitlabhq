# frozen_string_literal: true

RSpec.shared_examples 'group and project packages query' do
  include GraphqlHelpers

  let_it_be(:versionaless_package) { create(:maven_package, project: project1, version: nil) }
  let_it_be(:maven_package) { create(:maven_package, project: project1, name: 'tab', version: '4.0.0', created_at: 5.days.ago) }
  let_it_be(:package) { create(:npm_package, project: project1, name: 'uab', version: '5.0.0', created_at: 4.days.ago) }
  let_it_be(:composer_package) { create(:composer_package, project: project2, name: 'vab', version: '6.0.0', created_at: 3.days.ago) }
  let_it_be(:debian_package) { create(:debian_package, project: project2, name: 'zab', version: '7.0.0', created_at: 2.days.ago) }
  let_it_be(:composer_metadatum) do
    create(:composer_metadatum, package: composer_package,
           target_sha: 'afdeh',
           composer_json: { name: 'x', type: 'y', license: 'z', version: 1 })
  end

  let(:package_names) { graphql_data_at(resource_type, :packages, :nodes, :name) }
  let(:target_shas) { graphql_data_at(resource_type, :packages, :nodes, :metadata, :target_sha) }
  let(:packages) { graphql_data_at(resource_type, :packages, :nodes) }

  let(:fields) do
    <<~QUERY
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

    it_behaves_like 'a working graphql query'

    it 'returns packages successfully' do
      expect(package_names).to contain_exactly(
        package.name,
        maven_package.name,
        debian_package.name,
        composer_package.name
      )
    end

    it 'deals with metadata' do
      expect(target_shas).to contain_exactly(composer_metadatum.target_sha)
    end
  end

  context 'when the user does not have access to the resource' do
    before do
      post_graphql(query, current_user: current_user)
    end

    it_behaves_like 'a working graphql query'

    it 'returns nil' do
      expect(packages).to be_nil
    end
  end

  context 'when the user is not authenticated' do
    before do
      post_graphql(query)
    end

    it_behaves_like 'a working graphql query'

    it 'returns nil' do
      expect(packages).to be_nil
    end
  end

  describe 'sorting and pagination' do
    let_it_be(:ascending_packages) { [maven_package, package, composer_package, debian_package].map { |package| global_id_of(package)} }

    let(:data_path) { [resource_type, :packages] }

    before do
      resource.add_reporter(current_user)
    end

    [:CREATED_ASC, :NAME_ASC, :VERSION_ASC, :TYPE_ASC].each do |order|
      context "#{order}" do
        it_behaves_like 'sorted paginated query' do
          let(:sort_param) { order }
          let(:first_param) { 4 }
          let(:expected_results) { ascending_packages }
        end
      end
    end

    [:CREATED_DESC, :NAME_DESC, :VERSION_DESC, :TYPE_DESC].each do |order|
      context "#{order}" do
        it_behaves_like 'sorted paginated query' do
          let(:sort_param) { order }
          let(:first_param) { 4 }
          let(:expected_results) { ascending_packages.reverse }
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
        expect_graphql_errors_to_include(/Argument \'sort\' on Field \'packages\' has an invalid value/)
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

      it { is_expected.to include({ "name" => versionaless_package.name }) }
    end
  end
end
