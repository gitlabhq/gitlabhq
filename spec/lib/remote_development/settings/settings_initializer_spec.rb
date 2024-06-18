# frozen_string_literal: true

require_relative "../rd_fast_spec_helper"

RSpec.describe RemoteDevelopment::Settings::SettingsInitializer, :rd_fast, feature_category: :remote_development do
  let(:context) { {} }
  let(:default_settings_class) { RemoteDevelopment::Settings::DefaultSettings }

  subject(:returned_value) do
    described_class.init(context)
  end

  context "when settings values and types all match" do
    it "returns default settings and setting_types" do
      expect(returned_value).to match(
        {
          settings: hash_including(default_max_hours_before_termination: 24),
          setting_types: hash_including(default_max_hours_before_termination: Integer)
        }
      )
    end
  end

  context "when a setting value has a type mismatch" do
    before do
      allow(default_settings_class).to receive(:default_settings).and_return(
        {
          setting: ["not an integer", Integer]
        }
      )
    end

    it "raises a descriptive exception" do
      expect { returned_value }.to raise_error(
        "Remote Development Setting 'setting' has a type of 'String', which does not match declared type of 'Integer'."
      )
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
      expect { returned_value }.to raise_error(
        "Remote Development Setting entry for 'setting' must be a two-element array containing the value and type."
      )
    end
  end

  context "when settings type is not specified as a Class" do
    before do
      allow(default_settings_class).to receive(:default_settings).and_return(
        {
          setting: ["value", 1]
        }
      )
    end

    it "raises a descriptive exception" do
      expect { returned_value }.to raise_error(
        "Remote Development Setting type for 'setting' must be a class, but it was a Integer."
      )
    end
  end
end
