# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'abuse_report', feature_category: :insider_threat do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:admin) }
  let_it_be(:label) { create(:abuse_report_label, title: 'Uno') }
  let_it_be(:report) { create(:abuse_report, labels: [label]) }

  let(:report_gid) { Gitlab::GlobalId.build(report, id: report.id).to_s }

  let(:fields) do
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

  let(:arguments) { { id: report_gid } }
  let(:query) { graphql_query_for('abuseReport', arguments, fields) }

  before do
    post_graphql(query, current_user: current_user)
  end

  it_behaves_like 'a working graphql query that returns data'

  it 'returns abuse report with labels' do
    expect(graphql_data_at('abuseReport', 'labels', 'nodes', 0)).to match(a_graphql_entity_for(label))
  end

  context 'when current user is not an admin' do
    let_it_be(:current_user) { create(:user) }

    it_behaves_like 'a working graphql query'

    it 'does not contain any data' do
      expect(graphql_data_at('abuseReportLabel')).to be_nil
    end
  end
end
