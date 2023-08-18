# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'abuse_report_labels', feature_category: :insider_threat do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:admin) }
  let_it_be(:project_label) { create(:label) }
  let_it_be(:label_one) { create(:abuse_report_label, title: 'Uno') }
  let_it_be(:label_two) { create(:abuse_report_label, title: 'Dos') }

  let(:fields) do
    <<~GRAPHQL
      nodes {
        id
        title
        description
        color
        textColor
      }
    GRAPHQL
  end

  let(:arguments) { { searchTerm: '' } }
  let(:query) { graphql_query_for('abuseReportLabels', arguments, fields) }

  before do
    post_graphql(query, current_user: current_user)
  end

  it_behaves_like 'a working graphql query that returns data'

  it 'returns abuse report labels sorted by title in ascending order' do
    expect(graphql_data_at('abuseReportLabels', 'nodes').size).to eq 2
    expect(graphql_data_at('abuseReportLabels', 'nodes', 0)).to match(a_graphql_entity_for(label_two))
    expect(graphql_data_at('abuseReportLabels', 'nodes', 1)).to match(a_graphql_entity_for(label_one))
  end

  context 'when current user is not an admin' do
    let_it_be(:current_user) { create(:user) }

    it_behaves_like 'a working graphql query'

    it 'does not contain any data' do
      expect(graphql_data_at('abuseReportLabels', 'nodes')).to be_empty
    end
  end

  context 'with a search term param' do
    let(:arguments) { { searchTerm: 'uno' } }

    it 'returns only matching abuse report labels' do
      expect(graphql_data_at('abuseReportLabels', 'nodes').size).to eq 1
      expect(graphql_data_at('abuseReportLabels', 'nodes', 0)).to match(a_graphql_entity_for(label_one))
    end
  end
end
