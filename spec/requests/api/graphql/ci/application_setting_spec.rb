# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting Application Settings', feature_category: :continuous_integration do
  include GraphqlHelpers

  let(:fields) do
    <<~QUERY
      #{all_graphql_fields_for('CiApplicationSettings', max_depth: 1)}
    QUERY
  end

  let(:query) do
    graphql_query_for(
      'ciApplicationSettings',
      fields
    )
  end

  let(:settings_data) { graphql_data['ciApplicationSettings'] }

  context 'without admin permissions' do
    let(:user) { create(:user) }

    before do
      post_graphql(query, current_user: user)
    end

    it_behaves_like 'a working graphql query that returns no data'
  end

  context 'with admin permissions' do
    let(:user) { create(:user, :admin) }

    before do
      post_graphql(query, current_user: user)
    end

    it_behaves_like 'a working graphql query that returns data'

    it 'fetches the settings data' do
      # assert against hash to ensure no additional fields are exposed
      expect(settings_data).to match({ 'keepLatestArtifact' => Gitlab::CurrentSettings.current_application_settings.keep_latest_artifact })
    end
  end
end
