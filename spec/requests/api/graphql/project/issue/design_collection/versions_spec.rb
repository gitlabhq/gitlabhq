# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Getting versions related to an issue' do
  include GraphqlHelpers
  include DesignManagementTestHelpers

  let_it_be(:issue) { create(:issue) }

  let_it_be(:version_a) do
    create(:design_version, issue: issue)
  end

  let_it_be(:version_b) do
    create(:design_version, issue: issue)
  end

  let_it_be(:version_c) do
    create(:design_version, issue: issue)
  end

  let_it_be(:version_d) do
    create(:design_version, issue: issue)
  end

  let_it_be(:owner) { issue.project.owner }

  def version_query(params = version_params)
    query_graphql_field(:versions, params, version_query_fields)
  end

  let(:version_params) { nil }

  let(:version_query_fields) { ['edges { node { sha } }'] }
  let(:edges_path) { %w[project issue designCollection versions edges] }

  let(:project) { issue.project }
  let(:current_user) { owner }

  let(:query) { make_query }

  def make_query(vq = version_query)
    graphql_query_for(:project, { fullPath: project.full_path },
      query_graphql_field(:issue, { iid: issue.iid.to_s },
        query_graphql_field(:design_collection, {}, vq)))
  end

  let(:design_collection) do
    graphql_data_at(:project, :issue, :design_collection)
  end

  def response_values(data = graphql_data, key = 'sha')
    data.dig(*edges_path).map { |e| e.dig('node', key) }
  end

  before do
    enable_design_management
  end

  it 'returns the design filename' do
    post_graphql(query, current_user: current_user)

    expect(response_values).to match_array([version_a, version_b, version_c, version_d].map(&:sha))
  end

  context 'with all fields requested' do
    let(:version_query_fields) do
      ['edges { node { id sha createdAt author { id } } }']
    end

    it 'returns correct data' do
      post_graphql(query, current_user: current_user)

      keys = graphql_data.dig(*edges_path).first['node'].keys
      expect(keys).to match_array(%w(id sha createdAt author))
    end
  end

  describe 'filter by sha' do
    let(:sha) { version_b.sha }

    let(:version_params) { { earlier_or_equal_to_sha: sha } }

    it 'finds only those versions at or before the given cut-off' do
      post_graphql(query, current_user: current_user)

      expect(response_values).to contain_exactly(version_a.sha, version_b.sha)
    end
  end

  describe 'filter by id' do
    let(:id) { global_id_of(version_c) }

    let(:version_params) { { earlier_or_equal_to_id: id } }

    it 'finds only those versions at or before the given cut-off' do
      post_graphql(query, current_user: current_user)

      expect(response_values).to contain_exactly(version_a.sha, version_b.sha, version_c.sha)
    end
  end

  describe 'pagination' do
    let(:end_cursor) { design_collection.dig('versions', 'pageInfo', 'endCursor') }

    let(:ids) { issue.design_collection.versions.ordered.map(&:sha) }

    let(:query) { make_query(version_query(first: 2)) }

    let(:cursored_query) do
      make_query(version_query(after: end_cursor))
    end

    let(:version_query_fields) { ['pageInfo { endCursor }', 'edges { node { sha } }'] }

    it 'sorts designs for reliable pagination' do
      post_graphql(query, current_user: current_user)

      expect(response_values).to match_array(ids.take(2))

      post_graphql(cursored_query, current_user: current_user)

      new_data = Gitlab::Json.parse(response.body).fetch('data')

      expect(response_values(new_data)).to match_array(ids.drop(2))
    end
  end
end
