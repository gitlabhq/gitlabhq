# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::OrganizationSetting, type: :model, feature_category: :cell do
  let_it_be(:organization) { create(:organization) }

  describe 'associations' do
    it { is_expected.to belong_to :organization }
  end

  describe 'validations' do
    context 'for json schema' do
      let(:restricted_visibility_levels) { [] }
      let(:settings) do
        {
          restricted_visibility_levels: restricted_visibility_levels
        }
      end

      it { is_expected.to allow_value(settings).for(:settings) }

      context 'when trying to store an unsupported key' do
        let(:settings) do
          {
            unsupported_key: 'some_value'
          }
        end

        it { is_expected.not_to allow_value(settings).for(:settings) }
      end

      context "when key 'restricted_visibility_levels' is invalid" do
        let(:restricted_visibility_levels) { ['some_string'] }

        it { is_expected.not_to allow_value(settings).for(:settings) }
      end
    end

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
