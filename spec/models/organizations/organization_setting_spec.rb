# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::OrganizationSetting, type: :model, feature_category: :cell do
  let_it_be(:organization) { create(:organization) }
  let_it_be(:organization_setting) { create(:organization_setting, organization: organization) }

  describe 'associations' do
    it { is_expected.to belong_to(:organization) }
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

  describe '.for' do
    let(:organization_id) { organization.id }

    subject(:settings) { described_class.for(organization_id) }

    context 'without organization id' do
      let(:organization_id) { nil }

      it { is_expected.to be_nil }
    end

    context 'when organization has settings' do
      it 'returns correct organization setting' do
        expect(settings).to eq(organization_setting)
      end
    end

    context 'when organization does not have settings' do
      let(:organization) { create(:organization) }

      it 'returns new settings record' do
        new_settings = settings

        expect(new_settings.organization).to eq(organization)
        expect(new_settings.new_record?).to eq(true)
      end
    end
  end
end
