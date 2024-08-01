# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::RemoteDevelopment::Settings::CurrentSettingsReader, feature_category: :remote_development do
  include ResultMatchers

  let(:overridden_setting_type) { String }
  let(:overridden_setting_value_from_current_settings) { "value_from_current_settings" }
  let(:relevant_setting_names) { %i[overridden_setting] }

  let(:context) do
    {
      settings: {
        non_relevant_setting: "non_relevant",
        overridden_setting: "original_value"
      },
      setting_types: {
        non_relevant_setting: String,
        overridden_setting: overridden_setting_type
      }
    }
  end

  subject(:result) do
    described_class.read(context)
  end

  before do
    stub_const("#{described_class}::RELEVANT_SETTING_NAMES", relevant_setting_names)
    create(:application_setting)
  end

  context "when the relevant settings are valid CurrentSettings entries" do
    before do
      stub_application_setting(overridden_setting: overridden_setting_value_from_current_settings)
    end

    context "when there are no errors" do
      it "returns ::Gitlab::CurrentSettings overridden settings as well as other non-relevant settings" do
        expect(result).to eq(Gitlab::Fp::Result.ok(
          {
            settings: {
              non_relevant_setting: "non_relevant",
              overridden_setting: overridden_setting_value_from_current_settings
            },
            setting_types: {
              non_relevant_setting: String,
              overridden_setting: String
            }
          }
        ))
      end
    end

    context "when the type from GitLab::CurrentSettings does not match the declared remote development setting type" do
      let(:overridden_setting_type) { Integer }

      it "returns an err Result containing a Gitlab::CurrentSettings read failed message with details" do
        expect(result).to be_err_result(
          RemoteDevelopment::Settings::Messages::SettingsCurrentSettingsReadFailed.new(
            details: "Gitlab::CurrentSettings.overridden_setting type of 'String' " \
              "did not match initialized Remote Development Settings type of '#{overridden_setting_type}'."
          )
        )
      end
    end
  end

  context "when no relevant settings are requested" do
    let(:context) do
      {
        settings: {
          completely_unrelated_setting: "completely_unrelated"
        },
        setting_types: {
          completely_unrelated_setting: String
        }
      }
    end

    it "returns an OK result containing the original context" do
      expect(result).to be_ok_result(context)
    end
  end

  context "when a relevant setting is not a valid CurrentSettings entry" do
    it "raises a runtime error" do
      expect { result }.to raise_error("Invalid CurrentSettings entry specified")
    end
  end
end
