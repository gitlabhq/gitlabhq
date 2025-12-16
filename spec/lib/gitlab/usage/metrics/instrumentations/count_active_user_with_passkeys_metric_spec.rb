# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::CountActiveUserWithPasskeysMetric, feature_category: :service_ping do
  ## Should be counted
  let_it_be(:active_user_with_passkey) { create(:user, :with_passkey, updated_at: 4.days.ago) }
  let_it_be(:another_active_user_with_passkey) { create(:user, :with_passkey, updated_at: 47.days.ago) }

  ## Should not be counted
  let_it_be(:deactivated_user_with_passkey) { create(:user, :with_passkey, :deactivated, updated_at: 4.days.ago) }
  let_it_be(:blocked_user_with_passkey) { create(:user, :with_passkey, :blocked, updated_at: 47.days.ago) }
  let_it_be(:active_user_without_passkey) { create(:user, :two_factor_via_webauthn, updated_at: 4.days.ago) }

  it_behaves_like 'a correct instrumented metric value and query', { time_frame: '28d', data_source: 'database' } do
    let(:expected_value) { 1 }
    let(:start) { 30.days.ago.to_fs(:db) }
    let(:finish) { 2.days.ago.to_fs(:db) }
    let(:expected_query) do
      <<~SQL.squish
        SELECT COUNT("users"."id") FROM "users"
        WHERE
          "users"."state" = 'active'
          AND "users"."id"
          IN (SELECT "webauthn_registrations"."user_id" FROM "webauthn_registrations" WHERE "webauthn_registrations"."authentication_mode" = 1)
          AND "users"."updated_at"
          BETWEEN '#{start}' AND '#{finish}'
      SQL
    end
  end

  it_behaves_like 'a correct instrumented metric value and query', { time_frame: 'all', data_source: 'database' } do
    let(:expected_value) { 2 }
    let(:expected_query) do
      <<~SQL.squish
        SELECT COUNT("users"."id") FROM "users"
        WHERE
          "users"."state" = 'active'
          AND "users"."id"
          IN (SELECT "webauthn_registrations"."user_id" FROM "webauthn_registrations" WHERE "webauthn_registrations"."authentication_mode" = 1)
      SQL
    end
  end
end
