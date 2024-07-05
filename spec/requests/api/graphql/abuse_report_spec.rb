# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Querying an Abuse Report', feature_category: :insider_threat do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:admin) }
  let_it_be(:abuse_report) { create(:abuse_report) }

  let(:global_id) { abuse_report.to_gid.to_s }
  let(:abuse_report_fields) { all_graphql_fields_for('AbuseReport', max_depth: 2) }
  let(:abuse_report_data) { graphql_data['abuseReport'] }

  let(:query) do
    graphql_query_for('abuseReport', { 'id' => global_id }, abuse_report_fields)
  end

  before do
    post_graphql(query, current_user: current_user)
  end

  context 'when the user is an admin' do
    it_behaves_like 'a working graphql query that returns data'

    it 'returns all fields' do
      expect(abuse_report_data).to include(
        'id' => global_id
      )
    end
  end

  context 'when the user is not an admin' do
    let(:current_user) { create(:user) }

    it 'returns nil' do
      expect(abuse_report_data).to be_nil
    end
  end

  describe 'labels' do
    let_it_be(:abuse_report_label) { create(:abuse_report_label, title: 'Label') }
    let_it_be(:abuse_report) { create(:abuse_report, labels: [abuse_report_label]) }

    let(:labels_response) do
      graphql_data_at(:abuse_report, :labels, :nodes)
    end

    let(:abuse_report_fields) do
      <<~GRAPHQL
        labels {
          nodes {
            id
            title
            description
            color
            textColor
          }
        }
      GRAPHQL
    end

    it 'returns labels' do
      expect(labels_response).to contain_exactly(
        a_graphql_entity_for(abuse_report_label)
      )
    end
  end
end
