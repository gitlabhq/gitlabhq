# frozen_string_literal: true

require "fast_spec_helper"

RSpec.describe Gitlab::Fp::Settings::DefaultSettingsParser, feature_category: :shared do
  let(:module_name) { "My Module" }
  let(:requested_setting_names) { [:setting] }
  let(:default_settings_class) do
    Class.new do
      def self.default_settings
        # return value will be mocked in each context
      end
    end
  end

  let(:mutually_dependent_settings_groups) { [] }

  subject(:returned_values) do
    described_class.parse(
      module_name: module_name,
      requested_setting_names: requested_setting_names,
      default_settings: default_settings_class.default_settings,
      mutually_dependent_settings_groups: mutually_dependent_settings_groups
    )
  end

  context "when settings values and types all match" do
    let(:requested_setting_names) { [:setting, :boolean_setting] }

    before do
      allow(default_settings_class).to receive(:default_settings).and_return(
        {
          setting: ["a value", String],
          boolean_setting: [true, :Boolean],
          setting_that_was_not_requested: ["a value", String]
        }
      )
    end

    it "returns default settings and setting_types for requested_setting_names" do
      expect(returned_values).to eq(
        [
          { setting: "a value", boolean_setting: true },
          { setting: String, boolean_setting: :Boolean }
        ]
      )
    end
  end

  context "when a setting value has a type mismatch" do
    context "for a Class setting_type" do
      before do
        allow(default_settings_class).to receive(:default_settings).and_return(
          {
            setting: ["not an integer", Integer]
          }
        )
      end

      it "raises a descriptive exception" do
        expect { returned_values }.to raise_error(
          "#{module_name} Setting 'setting' has a type of 'String', which does not match declared type of 'Integer'."
        )
      end
    end

    context "for a :Boolean setting_type" do
      before do
        allow(default_settings_class).to receive(:default_settings).and_return(
          {
            setting: ["not a bool", :Boolean]
          }
        )
      end

      it "raises a descriptive exception" do
        expect { returned_values }.to raise_error(
          "#{module_name} Setting 'setting' has a type of 'String', which does not match declared type of 'Boolean'."
        )
      end
    end
  end

  context "when a default_settings entry is not an array" do
    before do
      allow(default_settings_class).to receive(:default_settings).and_return(
        {
          setting: "Just a value"
        }
      )
    end

    it "raises a descriptive exception" do
      expect { returned_values }.to raise_error(
        "#{module_name} Setting entry for 'setting' must be a two-element array containing the value and type."
      )
    end
  end

  context "when settings type is not specified as a Class or :Boolean" do
    before do
      allow(default_settings_class).to receive(:default_settings).and_return(
        {
          setting: ["value", 1]
        }
      )
    end

    it "raises a descriptive exception" do
      expect { returned_values }.to raise_error(
        "#{module_name} Setting type for 'setting' must be a class or :Boolean, but it was a Integer."
      )
    end
  end

  describe "mutually dependent settings validation" do
    before do
      allow(default_settings_class).to receive(:default_settings).and_return(
        {
          needle: ["a", String],
          thread: ["a", String],
          peanut_butter: ["a", String],
          jelly: ["a", String]
        }
      )
    end

    context "when mutually dependent settings are not all specified" do
      context "for one group" do
        let(:requested_setting_names) { [:needle] }
        let(:mutually_dependent_settings_groups) { [[:needle, :thread]] }

        it "raises a descriptive exception" do
          expect { returned_values }.to raise_error(/needle and thread.*mutually dependent/)
        end
      end

      context "for multiple groups" do
        let(:requested_setting_names) { [:needle, :thread, :peanut_butter] }
        let(:mutually_dependent_settings_groups) { [[:needle, :thread], [:peanut_butter, :jelly]] }

        it "raises a descriptive exception" do
          expect { returned_values }.to raise_error(/peanut_butter and jelly.*mutually dependent/)
        end
      end
    end

    context "when a specified mutually dependent settings is not a supported setting name" do
      let(:requested_setting_names) { [:needle, :thread] }
      let(:mutually_dependent_settings_groups) { [[:not_a_supported_default_setting]] }

      it "raises a descriptive exception" do
        expect { returned_values }.to raise_error(/Unknown.*: not_a_supported_default_setting/)
      end
    end
  end
end
