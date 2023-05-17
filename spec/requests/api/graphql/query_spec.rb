# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query', feature_category: :shared do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, public_builds: false) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:developer) { create(:user) }

  let(:current_user) { developer }

  describe 'gitpodEnabled field' do
    let(:gitpod_enabled) { true }
    let(:gitpod_enabled_query) do
      <<~GRAPHQL
        { gitpodEnabled }
      GRAPHQL
    end

    before do
      allow(Gitlab::CurrentSettings.current_application_settings).to receive(:gitpod_enabled).and_return(gitpod_enabled)
      post_graphql(gitpod_enabled_query)
    end

    context 'When Gitpod is enabled for the application' do
      it { expect(graphql_data).to include('gitpodEnabled' => true) }
    end

    context 'When Gitpod is disabled for the application' do
      let(:gitpod_enabled) { false }

      it { expect(graphql_data).to include('gitpodEnabled' => false) }
    end
  end

  describe '.designManagement' do
    include DesignManagementTestHelpers

    let_it_be(:version) { create(:design_version, issue: issue) }
    let_it_be(:design) { version.designs.first }

    let(:query_result) { graphql_data.dig(*path) }
    let(:query) { graphql_query_for(:design_management, nil, dm_fields) }

    before do
      enable_design_management
      project.add_developer(developer)
      post_graphql(query, current_user: current_user)
    end

    shared_examples 'a query that needs authorization' do
      context 'the current user is not able to read designs' do
        let(:current_user) { create(:user) }

        it 'does not retrieve the record' do
          expect(query_result).to be_nil
        end

        it 'raises an error' do
          expect(graphql_errors).to include(
            a_hash_including('message' => a_string_matching(%r{you don't have permission}))
          )
        end
      end
    end

    describe '.version' do
      let(:path) { %w[designManagement version] }

      let(:dm_fields) do
        query_graphql_field(:version, { 'id' => global_id_of(version) }, 'id sha')
      end

      it_behaves_like 'a working graphql query'
      it_behaves_like 'a query that needs authorization'

      it 'fetches the expected data' do
        expect(query_result).to match a_graphql_entity_for(version, :sha)
      end
    end

    describe '.designAtVersion' do
      let_it_be(:design_at_version) do
        ::DesignManagement::DesignAtVersion.new(design: design, version: version)
      end

      let(:path) { %w[designManagement designAtVersion] }

      let(:dm_fields) do
        query_graphql_field(:design_at_version, { 'id' => global_id_of(design_at_version) }, <<~FIELDS)
          id
          filename
          version { id sha }
          design { id }
          issue { title iid }
          project { id fullPath }
        FIELDS
      end

      it_behaves_like 'a working graphql query'
      it_behaves_like 'a query that needs authorization'

      context 'the current user is able to read designs' do
        it 'fetches the expected data, including the correct associations' do
          expect(query_result).to match a_graphql_entity_for(
            design_at_version,
            'filename' => design_at_version.design.filename,
            'version' => a_graphql_entity_for(version, :sha),
            'design' => a_graphql_entity_for(design),
            'issue' => { 'title' => issue.title, 'iid' => issue.iid.to_s },
            'project' => a_graphql_entity_for(project, :full_path)
          )
        end
      end
    end
  end

  describe '.ciPipelineStage' do
    let_it_be(:ci_stage) { create(:ci_stage, name: 'graphql test stage', project: project) }

    let(:query) do
      <<~GRAPHQL
        {
          ciPipelineStage(id: "#{ci_stage.to_global_id}") {
            name
          }
        }
      GRAPHQL
    end

    context 'when the current user has access to the stage' do
      it 'fetches the stage for the given ID' do
        project.add_developer(developer)

        post_graphql(query, current_user: developer)

        expect(graphql_data.dig('ciPipelineStage', 'name')).to eq('graphql test stage')
      end
    end

    context 'when the current user does not have access to the stage' do
      it 'returns nil' do
        post_graphql(query, current_user: developer)

        expect(graphql_data['ciPipelineStage']).to be_nil
      end
    end
  end
end
