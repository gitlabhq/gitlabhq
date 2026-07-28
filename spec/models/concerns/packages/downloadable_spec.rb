# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Downloadable, feature_category: :package_registry do
  let(:throttle_period) { described_class::THROTTLE_PERIOD }

  context 'with a package', :aggregate_failures do
    let_it_be_with_reload(:package) { create(:generic_package) }

    shared_examples 'updating the last_downloaded_at column' do
      specify do
        expect(::Gitlab::Database::LoadBalancing::SessionMap.current(package.load_balancer))
          .to receive(:without_sticky_writes).and_call_original
        expect { execute }
          .to change { package.reload.last_downloaded_at }.from(nil).to(instance_of(ActiveSupport::TimeWithZone))
      end
    end

    shared_examples 'throttling the last_downloaded_at update' do
      it 'does not update again within the throttle period' do
        execute

        travel_to(throttle_period.from_now - 1.second) do
          expect { execute }.not_to change { package.reload.last_downloaded_at }
        end
      end

      it 'updates again once the throttle period has passed' do
        execute

        travel_to(throttle_period.from_now + 1.second) do
          expect { execute }.to change { package.reload.last_downloaded_at }
        end
      end
    end

    describe '#touch_last_downloaded_at' do
      # Not a memoized `subject`: the throttling examples call it more than once.
      def execute
        package.reload.touch_last_downloaded_at
      end

      it_behaves_like 'updating the last_downloaded_at column'
      it_behaves_like 'throttling the last_downloaded_at update'

      context 'when the timestamp is already fresh' do
        before do
          package.update_column(:last_downloaded_at, Time.current)
        end

        it 'short-circuits without issuing a database write' do
          expect(::Packages::Generic::Package).not_to receive(:touch_last_downloaded_at)

          expect { package.reload.touch_last_downloaded_at }
            .not_to change { package.reload.last_downloaded_at }
        end
      end
    end

    describe '.touch_last_downloaded_at' do
      # Not a memoized `subject`: the throttling examples call it more than once.
      def execute
        ::Packages::Generic::Package.touch_last_downloaded_at(package.id)
      end

      it_behaves_like 'updating the last_downloaded_at column'
      it_behaves_like 'throttling the last_downloaded_at update'
    end
  end
end
