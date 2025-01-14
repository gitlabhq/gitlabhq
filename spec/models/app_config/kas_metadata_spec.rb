# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AppConfig::KasMetadata, feature_category: :api do
  let(:kas_version_info) { instance_double(Gitlab::VersionInfo) }

  it 'has InstanceMetadataPolicy as declarative policy' do
    expect(described_class.declarative_policy_class).to eq("AppConfig::InstanceMetadataPolicy")
  end

  context 'when KAS is enabled' do
    it 'has the correct properties' do
      allow(Gitlab::Kas).to receive(:enabled?).and_return(true)
      allow_next_instance_of(Gitlab::Kas::ServerInfo) do |instance|
        allow(instance).to receive(:version_info).and_return(kas_version_info)
      end

      expect(described_class.new).to have_attributes(
        enabled: Gitlab::Kas.enabled?,
        version: kas_version_info,
        external_url: Gitlab::Kas.external_url,
        external_k8s_proxy_url: Gitlab::Kas.tunnel_url
      )
    end
  end

  context 'when KAS is disabled' do
    it 'has the correct properties' do
      allow(Gitlab::Kas).to receive(:enabled?).and_return(false)

      expect(described_class.new).to have_attributes(
        enabled: Gitlab::Kas.enabled?,
        version: nil,
        external_url: nil,
        external_k8s_proxy_url: nil
      )
    end
  end
end
