# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe UpdateApplicationSettingsContainerRegistryExpPolWorkerCapacityDefault,
  feature_category: :container_registry do
  let(:settings) { table(:application_settings) }

  context 'with no rows in the application_settings table' do
    it 'does not insert a row' do
      expect { migrate! }.to not_change { settings.count }
    end
  end

  context 'with a row in the application_settings table' do
    before do
      settings.create!(container_registry_expiration_policies_worker_capacity: capacity)
    end

    context 'with container_registry_expiration_policy_worker_capacity set to a value different than 0' do
      let(:capacity) { 1 }

      it 'does not update the row' do
        expect { migrate! }
          .to not_change { settings.count }
          .and not_change { settings.first.container_registry_expiration_policies_worker_capacity }
      end
    end

    context 'with container_registry_expiration_policy_worker_capacity set to 0' do
      let(:capacity) { 0 }

      it 'updates the existing row' do
        expect { migrate! }
          .to not_change { settings.count }
          .and change { settings.first.container_registry_expiration_policies_worker_capacity }.from(0).to(4)
      end
    end
  end
end
