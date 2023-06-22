# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::OrganizationSetting, type: :model, feature_category: :cell do
  let_it_be(:organization) { create(:organization) }

  describe 'associations' do
    it { is_expected.to belong_to :organization }
  end

  describe 'validations' do
    context 'when setting restricted_visibility_levels' do
      it 'is one or more of Gitlab::VisibilityLevel constants' do
        setting = build(:organization_setting)

        setting.restricted_visibility_levels = [123]

        expect(setting.valid?).to be false
        expect(setting.errors.full_messages).to include(
          "Restricted visibility levels '123' is not a valid visibility level"
        )

        setting.restricted_visibility_levels = [Gitlab::VisibilityLevel::PUBLIC, Gitlab::VisibilityLevel::PRIVATE,
          Gitlab::VisibilityLevel::INTERNAL]
        expect(setting.valid?).to be true
      end
    end
  end
end
