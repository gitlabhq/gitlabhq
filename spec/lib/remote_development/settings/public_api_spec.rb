# frozen_string_literal: true

require_relative "../rd_fast_spec_helper"

RSpec.describe RemoteDevelopment::Settings::PublicApi, :rd_fast, feature_category: :remote_development do
  subject(:settings_module) { RemoteDevelopment::Settings }

  before do
    allow(RemoteDevelopment::Settings::Main).to receive(:get_settings).with({ options: {} }).and_return(response_hash)
  end

  context "when successful" do
    let(:response_hash) { { settings: { some_setting: 42 }, status: :success } }

    describe "get_single_setting" do
      context "when passed a valid setting name" do
        it "returns the setting context" do
          expect(settings_module.get_single_setting(:some_setting)).to eq(42)
        end
      end

      context "when passed options" do
        let(:options) { { some_options_key: true } }

        it "passes along the options and returns the setting context" do
          expect(settings_module::Main).to receive(:get_settings).with({ options: options }).and_return(response_hash)
          expect(settings_module.get_single_setting(:some_setting, options)).to eq(42)
        end
      end
    end

    describe "get_all_settings" do
      it "returns a Hash containing all settings" do
        expect(settings_module.get_all_settings)
          .to match(hash_including(some_setting: 42))
      end
    end
  end

  context "when unsuccessful" do
    let(:response_hash) { { status: :error, message: :failed } }

    describe "get_single_setting" do
      context "when passed an invalid setting name" do
        it "raises an exception with a descriptive message" do
          expect { settings_module.get_single_setting(:invalid_setting_name) }
            .to raise_error("failed")
        end
      end
    end
  end
end
