# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe UpdateInvalidDormantUserSetting, :migration, feature_category: :user_profile do
  let(:settings) { table(:application_settings) }

  context 'with no rows in the application_settings table' do
    it 'does not insert a row' do
      expect { migrate! }.to not_change { settings.count }
    end
  end

  context 'with a row in the application_settings table' do
    before do
      settings.create!(deactivate_dormant_users_period: days)
    end

    context 'with deactivate_dormant_users_period set to a value greater than or equal to 90' do
      let(:days) { 90 }

      it 'does not update the row' do
        expect { migrate! }
          .to not_change { settings.count }
          .and not_change { settings.first.deactivate_dormant_users_period }
      end
    end

    context 'with deactivate_dormant_users_period set to a value less than or equal to 90' do
      let(:days) { 1 }

      it 'updates the existing row' do
        expect { migrate! }
          .to not_change { settings.count }
          .and change { settings.first.deactivate_dormant_users_period }
      end
    end
  end
end
