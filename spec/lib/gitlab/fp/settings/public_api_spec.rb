# frozen_string_literal: true

require "fast_spec_helper"

RSpec.describe Gitlab::Fp::Settings::PublicApi, feature_category: :web_ide do
  let(:settings_module) { Module.new { extend Gitlab::Fp::Settings::PublicApi } }
  let(:settings_main_class) { double(Class.new) } # rubocop:disable RSpec/VerifiedDoubles -- we want to use 'fast_spec_helper' so we don't want to refer to a concrete class
  let(:options) { {} }
  let(:get_settings_args) { { requested_setting_names: setting_names, options: options } }

  before do
    allow(settings_module).to receive(:settings_main_class).and_return(settings_main_class)
  end

  describe ".get" do
    subject(:returned_settings) do
      settings_module.get(setting_names, options)
    end

    context "when successful" do
      before do
        allow(settings_main_class).to receive(:get_settings).with(get_settings_args).and_return(response_hash)
      end

      let(:response_hash) { { settings: { some_setting: 42 }, status: :success } }

      context "when passed a valid setting names" do
        let(:setting_names) { [:some_setting] }

        it "returns the setting context" do
          expect(returned_settings).to eq({ some_setting: 42 })
        end

        context "when passed options" do
          let(:options) { { some_options_key: true } }

          it "passes along the options and returns the setting context" do
            expect(settings_main_class).to receive(:get_settings).with(get_settings_args).and_return(response_hash)
            expect(returned_settings).to eq({ some_setting: 42 })
          end
        end

        context "when settings_main_class returns an error" do
          let(:response_hash) { { status: :error, message: :failed } }

          before do
            allow(settings_main_class).to receive(:get_settings).with(get_settings_args).and_return(response_hash)
          end

          it "raises an exception with a descriptive message" do
            expect { returned_settings }.to raise_error("failed")
          end
        end
      end
    end

    context "when unsuccessful" do
      context "when passed a non-array as first arg" do
        let(:setting_names) { :some_setting }

        it "raises an exception with a descriptive message" do
          # noinspection RubyMismatchedArgumentType -- Intentionally passing wrong type for testing
          expect { returned_settings }.to raise_error("setting_names arg must be an Array of Symbols")
        end
      end

      context "when passed an array containing non-Symbol as first arg" do
        let(:setting_names) { ['some_setting'] }

        it "raises an exception with a descriptive message" do
          # noinspection RubyMismatchedArgumentType -- Intentionally passing wrong type for testing
          expect { returned_settings }.to raise_error("setting_names arg must be an Array of Symbols")
        end
      end

      context "when passed an invalid setting name" do
        let(:setting_names) { [:bad_1, :bad_2] }
        let(:response_hash) { { settings: { some_setting: "doesn't matter" }, status: :success } }

        before do
          allow(settings_main_class).to receive(:get_settings).with(get_settings_args).and_return(response_hash)
        end

        it "raises an exception with a descriptive message" do
          expect { returned_settings }.to raise_error("Unsupported setting name(s): bad_1, bad_2")
        end
      end
    end
  end

  describe ".get_single_setting" do
    subject(:returned_settings) do
      settings_module.get_single_setting(
        :some_setting,
        options
      )
    end

    context "when passed a valid setting name" do
      let(:response_hash) { { settings: { some_setting: 42 }, status: :success } }
      let(:setting_names) { [:some_setting] }

      before do
        allow(settings_main_class).to receive(:get_settings).with(get_settings_args).and_return(response_hash)
      end

      it "returns the setting context" do
        expect(returned_settings).to eq(42)
      end
    end
  end
end
