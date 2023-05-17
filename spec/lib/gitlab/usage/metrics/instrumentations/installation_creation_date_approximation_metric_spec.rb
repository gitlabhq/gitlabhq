# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::InstallationCreationDateApproximationMetric,
  feature_category: :service_ping do
  let_it_be(:application_setting) { create(:application_setting) }

  context 'with a root user' do
    let_it_be(:root) { create(:user, id: 1, created_at: DateTime.current - 2.days) }
    let_it_be(:expected_value) { root.reload.created_at } # reloading to get the timestamp from the database

    it_behaves_like 'a correct instrumented metric value', { time_frame: 'all', data_source: 'database' }
  end

  context 'without a root user' do
    let_it_be(:another_user) { create(:user, id: 2, created_at: DateTime.current + 2.days) }
    let_it_be(:expected_value) { application_setting.reload.created_at }

    it_behaves_like 'a correct instrumented metric value', { time_frame: 'all', data_source: 'database' }
  end
end
