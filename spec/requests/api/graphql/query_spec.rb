# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query' do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:developer) { create(:user) }

  let(:current_user) { developer }

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

      context 'the current user is able to read designs' do
        it 'fetches the expected data' do
          expect(query_result).to eq('id' => global_id_of(version), 'sha' => version.sha)
        end
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
          expect(query_result).to eq(
            'id' => global_id_of(design_at_version),
            'filename' => design_at_version.design.filename,
            'version' => { 'id' => global_id_of(version), 'sha' => version.sha },
            'design'  => { 'id' => global_id_of(design) },
            'issue'   => { 'title' => issue.title, 'iid' => issue.iid.to_s },
            'project' => { 'id' => global_id_of(project), 'fullPath' => project.full_path }
          )
        end
      end
    end
  end
end
