# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'maven package details' do
  include GraphqlHelpers
  include_context 'package details setup'

  let_it_be(:package) { create(:maven_package, project: project) }

  let(:metadata) { query_graphql_fragment('MavenMetadata') }

  shared_examples 'correct maven metadata' do
    it 'has the correct metadata' do
      expect(metadata_response).to include(
        'id' => global_id_of(package.maven_metadatum),
        'path' => package.maven_metadatum.path,
        'appGroup' => package.maven_metadatum.app_group,
        'appVersion' => package.maven_metadatum.app_version,
        'appName' => package.maven_metadatum.app_name
      )
    end
  end

  context 'a maven package with version' do
    subject { post_graphql(query, current_user: user) }

    before do
      subject
    end

    it_behaves_like 'a package detail'
    it_behaves_like 'correct maven metadata'
    it_behaves_like 'a package with files'
  end

  context 'a versionless maven package' do
    let_it_be(:maven_metadatum) { create(:maven_metadatum, app_version: nil) }
    let_it_be(:package) { create(:maven_package, project: project, version: nil, maven_metadatum: maven_metadatum) }

    subject { post_graphql(query, current_user: user) }

    before do
      subject
    end

    it_behaves_like 'a package detail'
    it_behaves_like 'correct maven metadata'
    it_behaves_like 'a package with files'

    it 'has an empty version' do
      subject

      expect(metadata_response['appVersion']).to eq(nil)
    end
  end
end
