# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::InstallationCreationDateMetric,
  feature_category: :service_ping do
  context 'with a root user' do
    let_it_be(:root) { create(:user, id: 1) }
    let_it_be(:expected_value) { root.reload.created_at } # reloading to get the timestamp from the database

    it_behaves_like 'a correct instrumented metric value', { time_frame: 'all', data_source: 'database' }
  end

  context 'without a root user' do
    let_it_be(:another_user) { create(:user, id: 2) }
    let_it_be(:expected_value) { nil }

    it_behaves_like 'a correct instrumented metric value', { time_frame: 'all', data_source: 'database' }
  end
end
