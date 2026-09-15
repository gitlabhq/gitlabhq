# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe SeedServiceDeskEmailRateLimits, migration: :gitlab_main, feature_category: :service_desk do
  let(:plans) { table(:plans) }
  let(:plan_limits) { table(:plan_limits) }

  let(:plan_name_uids) do
    {
      default: 1,
      free: 2,
      premium: 5,
      ultimate: 7,
      ultimate_trial: 8,
      premium_trial: 9,
      ultimate_trial_paid_customer: 10,
      opensource: 11
    }
  end

  let(:seeded_limits) do
    {
      'free' => [100, 700],
      'ultimate_trial' => [100, 700],
      'premium_trial' => [100, 700],
      'ultimate_trial_paid_customer' => [0, 0],
      'premium' => [5000, 50000],
      'opensource' => [1500, 10000],
      'ultimate' => [0, 0]
    }
  end

  let!(:default_plan_limits) { create_plan_limits!('default') }
  let!(:seeded_plan_limits) do
    seeded_limits.keys.index_with { |plan_name| create_plan_limits!(plan_name) }
  end

  def create_plan_limits!(plan_name)
    plan = plans.create!(name: plan_name, plan_name_uid: plan_name_uids.fetch(plan_name.to_sym))

    plan_limits.create!(plan_id: plan.id)
  end

  describe '#up' do
    it 'seeds the hourly and daily limits for every plan in the matrix', :aggregate_failures do
      migrate!

      seeded_limits.each do |plan_name, (hourly, daily)|
        record = seeded_plan_limits[plan_name].reload

        expect(record.service_desk_outbound_emails_per_hour).to eq(hourly)
        expect(record.service_desk_outbound_emails_per_day).to eq(daily)
      end
    end

    it 'leaves the default plan unlimited' do
      migrate!

      expect(default_plan_limits.reload.service_desk_outbound_emails_per_hour).to eq(0)
      expect(default_plan_limits.reload.service_desk_outbound_emails_per_day).to eq(0)
    end
  end

  describe '#down' do
    it 'resets every seeded plan back to zero', :aggregate_failures do
      migrate!
      schema_migrate_down!

      seeded_limits.each_key do |plan_name|
        record = seeded_plan_limits[plan_name].reload

        expect(record.service_desk_outbound_emails_per_hour).to eq(0)
        expect(record.service_desk_outbound_emails_per_day).to eq(0)
      end
    end

    it 'leaves the default plan untouched' do
      migrate!
      schema_migrate_down!

      expect(default_plan_limits.reload.service_desk_outbound_emails_per_hour).to eq(0)
      expect(default_plan_limits.reload.service_desk_outbound_emails_per_day).to eq(0)
    end
  end

  it 'seeds hourly and daily limits for the same set of plans' do
    expect(described_class::HOURLY_LIMITS.keys).to match_array(described_class::DAILY_LIMITS.keys)
  end
end
