# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe UpdateSeatControlInApplicationSettings, :migration, feature_category: :seat_cost_management do
  let(:application_settings) { table(:application_settings) }

  describe '#up' do
    it 'updates seat control to 0 when new_user_signups_cap is NULL' do
      application_settings.create!(new_user_signups_cap: nil)

      migrate!

      expect(application_settings.first.user_seat_management).to eq({ 'seat_control' => 0 })
    end

    it 'updates seat control to 1 when new_user_signups_cap is not NULL' do
      application_settings.create!(new_user_signups_cap: 10)

      migrate!

      expect(application_settings.first.user_seat_management).to eq({ 'seat_control' => 1 })
    end
  end
end
