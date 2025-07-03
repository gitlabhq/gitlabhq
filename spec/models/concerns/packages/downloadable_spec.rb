# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Downloadable, feature_category: :package_registry do
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

    describe '#touch_last_downloaded_at' do
      subject(:execute) { package.touch_last_downloaded_at }

      it_behaves_like 'updating the last_downloaded_at column'
    end

    describe '.touch_last_downloaded_at' do
      subject(:execute) { ::Packages::Generic::Package.touch_last_downloaded_at(package.id) }

      it_behaves_like 'updating the last_downloaded_at column'
    end
  end
end
