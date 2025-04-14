# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::ActiveInstanceIntegrationsMetric,
  feature_category: :integrations do
  let(:options) { { type: 'pivotaltracker' } }
  let(:expected_value) { 1 }
  let(:expected_query) do
    "SELECT COUNT(\"integrations\".\"id\") FROM \"integrations\" " \
      "WHERE \"integrations\".\"active\" = TRUE " \
      "AND \"integrations\".\"instance\" = TRUE " \
      "AND \"integrations\".\"type_new\" = 'Integrations::Pivotaltracker'"
  end

  before do
    create :harbor_integration
    create :pivotaltracker_integration
    create :pivotaltracker_integration

    create :pivotaltracker_integration, :instance
  end

  it_behaves_like 'a correct instrumented metric value and query',
    { options: { type: 'pivotaltracker' }, time_frame: 'all' }
end
