# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe WebIde::ExtensionMarketplacePreset, feature_category: :web_ide do
  describe '.all' do
    subject(:all) { described_class.all }

    it { is_expected.to eq([described_class.open_vsx]) }
  end

  describe '.open_vsx' do
    subject(:open_vsx) { described_class.open_vsx }

    it "has OpenVSX properties" do
      is_expected.to have_attributes(
        key: 'open_vsx',
        name: "Open VSX",
        values: {
          service_url: "https://open-vsx.org/vscode/gallery",
          item_url: "https://open-vsx.org/vscode/item",
          resource_url_template: "https://open-vsx.org/vscode/unpkg/{publisher}/{name}/{version}/{path}"
        }
      )
    end
  end

  describe '#to_h' do
    it 'returns hash of attributes' do
      preset = described_class.new(
        "test_key",
        "Test Key",
        service_url: "abc",
        item_url: "def",
        resource_url_template: "ghi"
      )

      expect(preset.to_h).to eq({
        key: "test_key",
        name: "Test Key",
        values: {
          service_url: "abc",
          item_url: "def",
          resource_url_template: "ghi"
        }
      })
    end
  end
end
