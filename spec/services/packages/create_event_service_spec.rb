# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::CreateEventService, feature_category: :package_registry do
  let_it_be(:project) { create(:project) }
  let(:scope) { 'generic' }
  let(:event_name) { 'pull_package' }

  let(:params) do
    {
      scope: scope,
      event_name: event_name
    }
  end

  subject(:service) { described_class.new(project, user, params).execute }

  describe '#execute' do
    let(:label) { 'generic' }
    let(:event_attrs) do
      {
        category: 'InternalEventTracking',
        label: label,
        namespace: project.namespace,
        project: project,
        property: property,
        user: nil
      }
    end

    let(:common_metrics) do
      ['counts.package_events_i_package_pull_package', "counts.package_events_i_package_#{label}_pull_package"]
    end

    shared_examples 'updates the correct metrics' do
      context 'with a user' do
        let_it_be(:user) { create(:user) }

        let(:property) { 'user' }
        let(:event_attrs) { super().merge(user: user) }

        it 'updates the correct metrics' do
          expect { service }.to trigger_internal_events('pull_package_from_registry').with(event_attrs)
            .and increment_usage_metrics(
              'counts.package_events_i_package_pull_package_by_user',
              *common_metrics,
              'redis_hll_counters.user_packages.user_packages_total_unique_counts_monthly',
              'redis_hll_counters.user_packages.user_packages_total_unique_counts_weekly'
            ).and not_increment_usage_metrics(
              'counts.package_events_i_package_pull_package_by_deploy_token',
              'counts.package_events_i_package_pull_package_by_guest',
              'redis_hll_counters.deploy_token_packages.deploy_token_packages_total_unique_counts_monthly',
              'redis_hll_counters.deploy_token_packages.deploy_token_packages_total_unique_counts_weekly'
            )
        end
      end

      context 'with a deploy token' do
        let_it_be(:user) { create(:deploy_token) }

        let(:property) { 'deploy_token' }

        it 'updates the correct metrics' do
          expect { service }.to trigger_internal_events('pull_package_from_registry').with(event_attrs)
            .and increment_usage_metrics(
              'counts.package_events_i_package_pull_package_by_deploy_token',
              *common_metrics,
              'redis_hll_counters.deploy_token_packages.deploy_token_packages_total_unique_counts_monthly',
              'redis_hll_counters.deploy_token_packages.deploy_token_packages_total_unique_counts_weekly'
            ).and not_increment_usage_metrics(
              'counts.package_events_i_package_pull_package_by_guest',
              'counts.package_events_i_package_pull_package_by_user',
              'redis_hll_counters.user_packages.user_packages_total_unique_counts_monthly',
              'redis_hll_counters.user_packages.user_packages_total_unique_counts_weekly'
            )
        end
      end

      context 'with no user' do
        let_it_be(:user) { nil }

        let(:property) { 'guest' }

        it 'updates the correct metrics' do
          expect { service }.to trigger_internal_events('pull_package_from_registry').with(event_attrs)
            .and increment_usage_metrics(
              'counts.package_events_i_package_pull_package_by_guest',
              *common_metrics
            ).and not_increment_usage_metrics(
              'counts.package_events_i_package_pull_package_by_deploy_token',
              'counts.package_events_i_package_pull_package_by_user',
              'redis_hll_counters.user_packages.user_packages_total_unique_counts_monthly',
              'redis_hll_counters.user_packages.user_packages_total_unique_counts_weekly',
              'redis_hll_counters.deploy_token_packages.deploy_token_packages_total_unique_counts_monthly',
              'redis_hll_counters.deploy_token_packages.deploy_token_packages_total_unique_counts_weekly'
            )
        end
      end
    end

    it_behaves_like 'updates the correct metrics'

    context 'with a package as scope' do
      let(:scope) { create(:npm_package) }
      let(:label) { 'npm' }

      it_behaves_like 'updates the correct metrics'
    end

    context "with not allowed event_name used" do
      let(:event_name) { 'boil_package' }
      let_it_be(:user) { create(:user) }

      it "doesn't trigger internal events" do
        expect { service }.not_to trigger_internal_events
      end

      it "doesn't update RedisHLL keys" do
        expect(::Gitlab::UsageDataCounters::HLLRedisCounter).not_to receive(:track_event)

        service
      end
    end
  end
end
