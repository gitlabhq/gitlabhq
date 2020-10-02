# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Analytics::UniqueVisits, :clean_gitlab_redis_shared_state do
  let(:unique_visits) { Gitlab::Analytics::UniqueVisits.new }
  let(:target1_id) { 'g_analytics_contribution' }
  let(:target2_id) { 'g_analytics_insights' }
  let(:target3_id) { 'g_analytics_issues' }
  let(:target4_id) { 'g_compliance_dashboard' }
  let(:target5_id) { 'i_compliance_credential_inventory' }
  let(:visitor1_id) { 'dfb9d2d2-f56c-4c77-8aeb-6cddc4a1f857' }
  let(:visitor2_id) { '1dd9afb2-a3ee-4de1-8ae3-a405579c8584' }
  let(:visitor3_id) { '34rfjuuy-ce56-sa35-ds34-dfer567dfrf2' }

  around do |example|
    # We need to freeze to a reference time
    # because visits are grouped by the week number in the year
    # Without freezing the time, the test may behave inconsistently
    # depending on which day of the week test is run.
    reference_time = Time.utc(2020, 6, 1)
    travel_to(reference_time) { example.run }
  end

  describe '#track_visit' do
    it 'tracks the unique weekly visits for targets' do
      unique_visits.track_visit(visitor1_id, target1_id, 7.days.ago)
      unique_visits.track_visit(visitor1_id, target1_id, 7.days.ago)
      unique_visits.track_visit(visitor2_id, target1_id, 7.days.ago)

      unique_visits.track_visit(visitor2_id, target2_id, 7.days.ago)
      unique_visits.track_visit(visitor1_id, target2_id, 8.days.ago)
      unique_visits.track_visit(visitor1_id, target2_id, 15.days.ago)

      unique_visits.track_visit(visitor3_id, target4_id, 7.days.ago)

      unique_visits.track_visit(visitor3_id, target5_id, 15.days.ago)
      unique_visits.track_visit(visitor2_id, target5_id, 15.days.ago)

      expect(unique_visits.unique_visits_for(targets: target1_id)).to eq(2)
      expect(unique_visits.unique_visits_for(targets: target2_id)).to eq(1)
      expect(unique_visits.unique_visits_for(targets: target4_id)).to eq(1)

      expect(unique_visits.unique_visits_for(targets: target2_id, start_date: 15.days.ago)).to eq(1)

      expect(unique_visits.unique_visits_for(targets: target3_id)).to eq(0)

      expect(unique_visits.unique_visits_for(targets: target5_id, start_date: 15.days.ago)).to eq(2)

      expect(unique_visits.unique_visits_for(targets: :analytics)).to eq(2)
      expect(unique_visits.unique_visits_for(targets: :analytics, start_date: 15.days.ago)).to eq(1)
      expect(unique_visits.unique_visits_for(targets: :analytics, start_date: 30.days.ago)).to eq(0)

      expect(unique_visits.unique_visits_for(targets: :analytics, start_date: 4.weeks.ago, end_date: Date.current)).to eq(2)

      expect(unique_visits.unique_visits_for(targets: :compliance)).to eq(1)
      expect(unique_visits.unique_visits_for(targets: :compliance, start_date: 15.days.ago)).to eq(2)
      expect(unique_visits.unique_visits_for(targets: :compliance, start_date: 30.days.ago)).to eq(0)

      expect(unique_visits.unique_visits_for(targets: :compliance, start_date: 4.weeks.ago, end_date: Date.current)).to eq(2)
    end

    it 'sets the keys in Redis to expire automatically after 12 weeks' do
      unique_visits.track_visit(visitor1_id, target1_id)

      Gitlab::Redis::SharedState.with do |redis|
        redis.scan_each(match: "{#{target1_id}}-*").each do |key|
          expect(redis.ttl(key)).to be_within(5.seconds).of(12.weeks)
        end
      end
    end

    it 'raises an error if an invalid target id is given' do
      invalid_target_id = "x_invalid"

      expect do
        unique_visits.track_visit(visitor1_id, invalid_target_id)
      end.to raise_error(Gitlab::UsageDataCounters::HLLRedisCounter::UnknownEvent)
    end
  end
end
