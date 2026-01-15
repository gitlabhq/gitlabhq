# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::CountUsersWithoutGroupOrProjectMembershipMetric, feature_category: :service_ping do
  let_it_be(:user_without_membership) { create(:user) }
  let_it_be(:user_with_membership) { create(:user) }
  let_it_be(:deactivated_user_without_membership) { create(:user, state: :deactivated) }

  let(:expected_value) { 1 }
  let(:time_frame) { 'all' }
  let_it_be(:group) { create(:group) }
  let(:expected_query) do
    <<~SQL.squish
      SELECT COUNT("users"."id")
      FROM "users"
      WHERE "users"."state" = 'active' AND "users"."user_type" IN (0, 6, 4, 13)
      AND (NOT EXISTS (SELECT 1 FROM "members" WHERE (members.user_id = users.id)))
    SQL
  end

  before_all do
    create(:group_member, user: user_with_membership, group: group)
  end

  it_behaves_like 'a correct instrumented metric value and query', { time_frame: 'all', data_source: 'database' }
end
