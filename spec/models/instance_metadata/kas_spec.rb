# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::InstanceMetadata::Kas do
  it 'has InstanceMetadataPolicy as declarative policy' do
    expect(described_class.declarative_policy_class).to eq("InstanceMetadataPolicy")
  end

  context 'when KAS is enabled' do
    it 'has the correct properties' do
      allow(Gitlab::Kas).to receive(:enabled?).and_return(true)

      expect(subject).to have_attributes(
        enabled: Gitlab::Kas.enabled?,
        version: Gitlab::Kas.version,
        external_url: Gitlab::Kas.external_url
      )
    end
  end

  context 'when KAS is disabled' do
    it 'has the correct properties' do
      allow(Gitlab::Kas).to receive(:enabled?).and_return(false)

      expect(subject).to have_attributes(
        enabled: Gitlab::Kas.enabled?,
        version: nil,
        external_url: nil
      )
    end
  end
end
