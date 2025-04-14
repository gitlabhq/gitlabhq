# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::CountAdminsMetric, feature_category: :service_ping do
  let_it_be(:admin_user) { create(:user, :admin) }

  let(:expected_value) { 1 }
  let(:time_frame) { 'all' }
  let(:expected_query) do
    <<~SQL.squish
      SELECT COUNT("users"."id") FROM "users"
      WHERE "users"."admin" = TRUE
    SQL
  end

  it_behaves_like 'a correct instrumented metric value and query', { time_frame: 'all', data_source: 'database' }
end
