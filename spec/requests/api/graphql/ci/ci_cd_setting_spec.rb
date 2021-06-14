# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'Getting Ci Cd Setting' do
  include GraphqlHelpers

  let_it_be_with_reload(:project) { create(:project, :repository) }
  let_it_be(:current_user) { project.owner }

  let(:fields) do
    <<~QUERY
      #{all_graphql_fields_for('ProjectCiCdSetting', max_depth: 1)}
    QUERY
  end

  let(:query) do
    graphql_query_for(
      'project',
      { 'fullPath' => project.full_path },
      query_graphql_field('ciCdSettings', {}, fields)
    )
  end

  let(:settings_data) { graphql_data['project']['ciCdSettings'] }

  context 'without permissions' do
    let(:user) { create(:user) }

    before do
      project.add_reporter(user)
      post_graphql(query, current_user: user)
    end

    it_behaves_like 'a working graphql query'

    specify { expect(settings_data).to be nil }
  end

  context 'with project permissions' do
    before do
      post_graphql(query, current_user: current_user)
    end

    it_behaves_like 'a working graphql query'

    it 'fetches the settings data' do
      expect(settings_data['mergePipelinesEnabled']).to eql project.ci_cd_settings.merge_pipelines_enabled?
      expect(settings_data['mergeTrainsEnabled']).to eql project.ci_cd_settings.merge_trains_enabled?
      expect(settings_data['keepLatestArtifact']).to eql project.keep_latest_artifacts_available?
      expect(settings_data['jobTokenScopeEnabled']).to eql project.ci_cd_settings.job_token_scope_enabled?
    end
  end
end
