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
      let(:default_group_visibility) { nil }
      let(:restricted_visibility_levels) { [] }
      let(:settings) do
        {
          restricted_visibility_levels: restricted_visibility_levels,
          default_group_visibility: default_group_visibility
        }
      end

      it { is_expected.to allow_value(settings).for(:settings) }

      context 'when trying to store an unsupported key' do
        let(:settings) do
          {
            restricted_visibility_levels: [Gitlab::VisibilityLevel::PRIVATE],
            unsupported_key: 'some_value'
          }
        end

        it { is_expected.not_to allow_value(settings).for(:settings) }
      end

      context 'when value' do
        using RSpec::Parameterized::TableSyntax

        where(:setting_key, :valid_value, :invalid_value) do
          :restricted_visibility_levels | [Gitlab::VisibilityLevel::PRIVATE] | ['some_string']
          :default_group_visibility     | Gitlab::VisibilityLevel::PRIVATE   | 'some_string'
        end

        with_them do
          subject(:organization_settings) { described_class.new }

          let(:settings) do
            organization_settings.settings.merge({
              setting_key => setting_value
            })
          end

          context "for key '#{params[:setting_key]}' is invalid" do
            let(:setting_value) { invalid_value }

            it { is_expected.not_to allow_value(settings).for(:settings) }
          end

          context "for key '#{params[:setting_key]}' is valid" do
            let(:setting_value) { valid_value }

            it { is_expected.to allow_value(settings).for(:settings) }
          end
        end
      end
    end

    context 'when setting restricted_visibility_levels' do
      let(:setting) { build(:organization_setting) }

      it 'rejects invalid visibility levels' do
        setting.restricted_visibility_levels = [123]

        setting.valid?

        expect(setting.errors).to include(:restricted_visibility_levels)
        expect(setting.errors.full_messages).to include(
          "Restricted visibility levels '123' is not a valid visibility level"
        )
      end

      it 'accept one or more of Gitlab::VisibilityLevel constants' do
        setting.restricted_visibility_levels = [
          Gitlab::VisibilityLevel::PUBLIC,
          Gitlab::VisibilityLevel::PRIVATE,
          Gitlab::VisibilityLevel::INTERNAL
        ]

        setting.valid?

        expect(setting.errors).not_to include(:restricted_visibility_levels)
      end
    end

    context 'when setting default_group_visibility' do
      subject(:setting) { build(:organization_setting) }

      it 'allows nil' do
        # This will force the validation to run.
        allow(setting).to receive(:should_prevent_visibility_restriction?).and_return(true)

        setting.default_group_visibility = nil

        expect(setting).to be_valid
      end

      it 'allows valid visibility levels' do
        is_expected.to validate_inclusion_of(:default_group_visibility).in_array(Gitlab::VisibilityLevel.values)
      end

      it 'prevents setting default_group_visibility to a restricted visibility level' do
        setting.restricted_visibility_levels = [Gitlab::VisibilityLevel::PUBLIC]
        setting.default_group_visibility = Gitlab::VisibilityLevel::PUBLIC

        expect(setting).not_to be_valid
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
