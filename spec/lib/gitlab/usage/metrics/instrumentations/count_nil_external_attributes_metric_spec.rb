# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::CountNilExternalAttributesMetric, feature_category: :service_ping do
  let_it_be(:external_user_with_nil_value) { create(:user, :external, external: nil) }

  let(:expected_value) { 1 }
  let(:expected_query) do
    <<~SQL.squish
      SELECT COUNT("users"."id")
      FROM "users"
      WHERE "users"."external" IS NULL
    SQL
  end

  it_behaves_like 'a correct instrumented metric value and query', { time_frame: 'all', data_source: 'database' }
end
