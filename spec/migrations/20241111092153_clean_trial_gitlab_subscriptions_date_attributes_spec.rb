# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe CleanTrialGitlabSubscriptionsDateAttributes, migration: :gitlab_main, feature_category: :subscription_management do
  let(:migration) { described_class.new }

  let(:yesterday) { today - 1.day }
  let(:today) { Date.current }
  let(:tomorrow) { today + 1.day }

  let(:gitlab_subscriptions) { table(:gitlab_subscriptions) }
  let(:namespaces) { table(:namespaces) }

  let(:namespace_kinetic) { namespaces.create!(name: 'kinetic', path: 'kinetic') }
  let(:namespace_laser) { namespaces.create!(name: 'laser', path: 'laser') }
  let(:namespace_gravity) { namespaces.create!(name: 'gravity', path: 'gravity') }
  let(:namespace_universe) { namespaces.create!(name: 'universe', path: 'universe') }
  let(:namespace_void) { namespaces.create!(name: 'void', path: 'void') }
  let(:namespace_sky) { namespaces.create!(name: 'sky', path: 'sky') }
  let(:namespace_rocket) { namespaces.create!(name: 'rocket', path: 'rocket') }

  context "with trial_starts_on and trial_ends_on" do
    let!(:subscription_without_trial_ends_on) do
      gitlab_subscriptions.create!(
        trial: true,
        trial_starts_on: yesterday,
        trial_ends_on: nil,
        start_date: yesterday,
        end_date: tomorrow,
        namespace_id: namespace_laser.id
      )
    end

    let!(:subscription_without_trial_starts_on) do
      gitlab_subscriptions.create!(
        trial: true,
        trial_starts_on: nil,
        trial_ends_on: tomorrow,
        start_date: yesterday,
        end_date: tomorrow,
        namespace_id: namespace_gravity.id
      )
    end

    let!(:subscription_without_trial_dates) do
      gitlab_subscriptions.create!(
        trial: true,
        trial_starts_on: nil,
        trial_ends_on: nil,
        start_date: yesterday,
        end_date: tomorrow,
        namespace_id: namespace_universe.id
      )
    end

    let!(:subscription_with_equal_trial_dates) do
      gitlab_subscriptions.create!(
        trial: true,
        trial_starts_on: yesterday,
        trial_ends_on: yesterday,
        start_date: yesterday,
        end_date: yesterday,
        namespace_id: namespace_void.id
      )
    end

    let!(:subscription_non_trial) do
      gitlab_subscriptions.create!(
        trial: false,
        trial_starts_on: nil,
        trial_ends_on: nil,
        namespace_id: namespace_sky.id
      )
    end

    let!(:subscription_with_trial_dates) do
      gitlab_subscriptions.create!(
        trial: true,
        trial_starts_on: yesterday,
        trial_ends_on: tomorrow,
        start_date: yesterday,
        end_date: tomorrow,
        namespace_id: namespace_rocket.id
      )
    end

    it 'updates attributes' do
      expect(subscription_without_trial_starts_on.trial_starts_on).to be_nil
      expect(subscription_without_trial_ends_on.trial_ends_on).to be_nil

      expect(subscription_without_trial_dates.trial_starts_on).to be_nil
      expect(subscription_without_trial_dates.trial_ends_on).to be_nil

      expect(subscription_with_equal_trial_dates.trial_ends_on).to eq(yesterday)
      expect(subscription_with_equal_trial_dates.end_date).to eq(yesterday)

      expect(subscription_non_trial.trial_starts_on).to be_nil
      expect(subscription_non_trial.trial_ends_on).to be_nil

      expect(subscription_with_trial_dates.trial_starts_on).to eq(yesterday)
      expect(subscription_with_trial_dates.trial_ends_on).to eq(tomorrow)

      migrate!

      expect(subscription_without_trial_starts_on.reload.trial_starts_on).to eq(yesterday)
      expect(subscription_without_trial_ends_on.reload.trial_ends_on).to eq(tomorrow)

      expect(subscription_without_trial_dates.reload.trial_starts_on).to eq(yesterday)
      expect(subscription_without_trial_dates.reload.trial_ends_on).to eq(tomorrow)

      expect(subscription_with_equal_trial_dates.reload.trial_ends_on).to eq(today)
      expect(subscription_with_equal_trial_dates.reload.end_date).to eq(today)

      expect(subscription_non_trial.reload.trial_starts_on).to be_nil
      expect(subscription_non_trial.reload.trial_ends_on).to be_nil

      expect(subscription_with_trial_dates.reload.trial_starts_on).to eq(yesterday)
      expect(subscription_with_trial_dates.reload.trial_ends_on).to eq(tomorrow)
    end
  end
end
