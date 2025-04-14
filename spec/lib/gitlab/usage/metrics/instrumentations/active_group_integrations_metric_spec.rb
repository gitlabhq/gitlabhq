# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::ActiveGroupIntegrationsMetric,
  feature_category: :integrations do
  let(:options) { { type: 'pivotaltracker' } }
  let(:expected_value) { 3 }
  let(:expected_query) do
    "SELECT COUNT(\"integrations\".\"id\") FROM \"integrations\" " \
      "WHERE \"integrations\".\"active\" = TRUE AND \"integrations\".\"group_id\" IS NOT NULL " \
      "AND \"integrations\".\"type_new\" = 'Integrations::Pivotaltracker'"
  end

  before do
    create :harbor_integration
    create_list :pivotaltracker_integration, 3, :group

    create :pivotaltracker_integration
  end

  it_behaves_like 'a correct instrumented metric value and query',
    { options: { type: 'pivotaltracker' }, time_frame: 'all' }
end
