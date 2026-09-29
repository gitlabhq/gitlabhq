# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'MFE gem wiring', feature_category: :compliance_management do
  using RSpec::Parameterized::TableSyntax

  describe 'Gitlab::Mfe.enabled?' do
    subject(:enabled) { Gitlab::Mfe.enabled? }

    where(:config_enabled, :flag_enabled, :result) do
      true  | true  | true
      true  | false | false
      false | true  | false
      false | false | false
    end

    with_them do
      before do
        stub_config(mfe: { enabled: config_enabled })
        stub_feature_flags(mfe_enabled: flag_enabled)
      end

      it { is_expected.to eq(result) }
    end

    context 'when the mfe config section is missing' do
      before do
        allow(Gitlab.config).to receive(:mfe).and_raise(Gitlab::Configs::MissingConfig)
        stub_feature_flags(mfe_enabled: true)
      end

      it { is_expected.to be(false) }
    end
  end

  describe 'Gitlab::Mfe.registry_url' do
    subject(:registry_url) { Gitlab::Mfe.registry_url }

    context 'when the mfe config section is present' do
      before do
        stub_config(mfe: { registry_url: 'https://custom.example.com' })
      end

      it { is_expected.to eq('https://custom.example.com') }
    end

    context 'when the mfe config section is missing' do
      before do
        allow(Gitlab.config).to receive(:mfe).and_raise(Gitlab::Configs::MissingConfig)
      end

      it { is_expected.to eq(Gitlab::Mfe::DEFAULT_REGISTRY_URL) }
    end
  end

  describe 'Gitlab::Mfe::VendorFile.entries' do
    it 'reads the committed pin file at the repository root' do
      committed_names = Array(YAML.safe_load_file(Rails.root.join('vendor/mfe.yml'))['apps']).pluck('name')

      expect(Gitlab::Mfe::VendorFile.entries.map(&:name)).to eq(committed_names)
    end
  end
end
