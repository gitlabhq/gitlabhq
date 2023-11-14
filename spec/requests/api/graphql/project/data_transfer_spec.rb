# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'project data transfers', feature_category: :source_code_management do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project) }

  let(:fields) do
    <<~QUERY
    #{all_graphql_fields_for('ProjectDataTransfer'.classify)}
    QUERY
  end

  let(:query) do
    graphql_query_for(
      'project',
      { fullPath: project.full_path },
      query_graphql_field('DataTransfer', params, fields)
    )
  end

  let(:from) { Date.new(2022, 1, 1) }
  let(:to) { Date.new(2023, 1, 1) }
  let(:params) { { from: from, to: to } }
  let(:egress_data) do
    graphql_data.dig('project', 'dataTransfer', 'egressNodes', 'nodes')
  end

  before do
    create(:project_data_transfer, project: project, date: '2022-01-01', repository_egress: 1)
    create(:project_data_transfer, project: project, date: '2022-02-01', repository_egress: 2)
  end

  subject { post_graphql(query, current_user: current_user) }

  context 'with anonymous access' do
    let_it_be(:current_user) { nil }

    before do
      subject
    end

    it_behaves_like 'a working graphql query'

    it 'returns no data' do
      expect(graphql_data_at(:project, :data_transfer)).to be_nil
      expect(graphql_errors).to be_nil
    end
  end

  context 'with authorized user but without enough permissions' do
    before do
      project.add_developer(current_user)
      subject
    end

    it_behaves_like 'a working graphql query'

    it 'returns empty results' do
      expect(graphql_data_at(:project, :data_transfer)).to be_nil
      expect(graphql_errors).to be_nil
    end
  end

  context 'when user has enough permissions' do
    before do
      project.add_owner(current_user)
      subject
    end

    it 'returns real results' do
      expect(response).to have_gitlab_http_status(:ok)

      expect(egress_data.count).to eq(2)

      expect(egress_data.first.keys).to match_array(
        %w[date totalEgress repositoryEgress artifactsEgress packagesEgress registryEgress]
      )

      expect(egress_data.pluck('repositoryEgress')).to match_array(%w[1 2])
    end

    it_behaves_like 'a working graphql query'
  end
end
