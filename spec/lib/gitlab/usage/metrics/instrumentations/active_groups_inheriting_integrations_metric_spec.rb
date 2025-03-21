# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::ActiveGroupsInheritingIntegrationsMetric,
  feature_category: :integrations do
  let(:options) { { type: 'pivotaltracker' } }
  let(:expected_value) { 3 }
  let(:expected_query) do
    "SELECT COUNT(\"integrations\".\"id\") FROM \"integrations\" " \
      "WHERE \"integrations\".\"active\" = TRUE " \
      "AND \"integrations\".\"group_id\" IS NOT NULL " \
      "AND \"integrations\".\"inherit_from_id\" IS NOT NULL " \
      "AND \"integrations\".\"type_new\" = 'Integrations::Pivotaltracker'"
  end

  before do
    create :harbor_integration
    integration = create :pivotaltracker_integration

    create_list :pivotaltracker_integration, 3, :group, inherit_from_id: integration.id
  end

  it_behaves_like 'a correct instrumented metric value and query',
    { options: { type: 'pivotaltracker' }, time_frame: 'all' }
end
