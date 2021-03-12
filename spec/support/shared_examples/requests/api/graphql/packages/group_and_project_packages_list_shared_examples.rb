# frozen_string_literal: true

RSpec.shared_examples 'group and project packages query' do
  include GraphqlHelpers

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
end
