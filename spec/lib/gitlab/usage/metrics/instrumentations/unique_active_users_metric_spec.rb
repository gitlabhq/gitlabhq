# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::UniqueActiveUsersMetric do
  let_it_be(:user1) { create(:user, last_activity_on: 1.day.ago) }
  let_it_be(:user2) { create(:user, last_activity_on: 5.days.ago) }
  let_it_be(:user3) { create(:user, last_activity_on: 50.days.ago) }
  let_it_be(:user4) { create(:user) }
  let_it_be(:user5) { create(:user, user_type: 1, last_activity_on: 5.days.ago ) } # support bot
  let_it_be(:user6) { create(:user, state: 'blocked') }

  context '28d' do
    let(:start) { 30.days.ago.to_date.to_s }
    let(:finish) { 2.days.ago.to_date.to_s }
    let(:expected_value) { 1 }
    let(:expected_query) do
      "SELECT COUNT(\"users\".\"id\") FROM \"users\" WHERE (\"users\".\"state\" IN ('active')) AND " \
      "(\"users\".\"user_type\" IS NULL OR \"users\".\"user_type\" IN (6, 4)) AND \"users\".\"last_activity_on\" " \
      "BETWEEN '#{start}' AND '#{finish}'"
    end

    it_behaves_like 'a correct instrumented metric value and query', { time_frame: '28d' }
  end

  context 'all' do
    let(:expected_value) { 4 }

    it_behaves_like 'a correct instrumented metric value', { time_frame: 'all' }
  end
end
