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
              *common_metrics
            ).and not_increment_usage_metrics(
              'counts.package_events_i_package_pull_package_by_deploy_token',
              'counts.package_events_i_package_pull_package_by_guest'
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
              *common_metrics
            ).and not_increment_usage_metrics(
              'counts.package_events_i_package_pull_package_by_guest',
              'counts.package_events_i_package_pull_package_by_user'
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
              'counts.package_events_i_package_pull_package_by_user'
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

    context 'when using non-internal events' do
      let(:event_name) { 'push_package' }

      shared_examples 'redis package unique event creation' do
        it 'tracks the event' do
          expect(::Gitlab::UsageDataCounters::HLLRedisCounter).to receive(:track_event).with(/package/, values: user.id)

          subject
        end
      end

      shared_examples 'redis package count event creation' do
        it 'tracks the event' do
          expect(::Gitlab::UsageDataCounters::PackageEventCounter).to receive(:count).at_least(:once)

          subject
        end
      end

      context 'with a user' do
        let(:user) { create(:user) }

        it_behaves_like 'redis package unique event creation'
        it_behaves_like 'redis package count event creation'
      end

      context 'with a deploy token' do
        let(:user) { create(:deploy_token) }

        it_behaves_like 'redis package unique event creation'
        it_behaves_like 'redis package count event creation'
      end

      context 'with no user' do
        let(:user) { nil }

        it_behaves_like 'redis package count event creation'
      end

      context 'with a package as scope' do
        let(:scope) { create(:npm_package) }

        context 'as guest' do
          let(:user) { nil }

          it_behaves_like 'redis package count event creation'
        end

        context 'with user' do
          let(:user) { create(:user) }

          it_behaves_like 'redis package unique event creation'
          it_behaves_like 'redis package count event creation'
        end

        context 'with a deploy token' do
          let(:user) { create(:deploy_token) }

          it_behaves_like 'redis package unique event creation'
          it_behaves_like 'redis package count event creation'
        end
      end
    end
  end
end
