# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe WebIde::Settings, feature_category: :web_ide do
  let(:response_hash) { { settings: { some_setting: 42 }, status: :success } }
  let(:get_settings_args) { { requested_setting_names: [:some_setting], options: { some_option: 42 } } }

  before do
    allow(WebIde::Settings::Main).to receive(:get_settings).with(get_settings_args).and_return(response_hash)
  end

  it "implements the extended module's behavior" do
    expect(described_class.get_single_setting(:some_setting, some_option: 42)).to eq(42)
  end
end
