# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Downloadable, feature_category: :package_registry do
  context 'with a package' do
    describe '#touch_last_downloaded_at' do
      let_it_be(:package) { create(:generic_package) }

      subject { package.touch_last_downloaded_at }

      it 'updates the downloaded_at' do
        expect(::Gitlab::Database::LoadBalancing::SessionMap.current(package.load_balancer))
          .to receive(:without_sticky_writes).and_call_original
        expect { subject }
          .to change { package.last_downloaded_at }.from(nil).to(instance_of(ActiveSupport::TimeWithZone))
      end
    end
  end
end
