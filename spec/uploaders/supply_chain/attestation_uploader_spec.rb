# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SupplyChain::AttestationUploader, feature_category: :artifact_security do
  subject { supply_chain_attestation.file }

  let(:supply_chain_attestation) { create(:supply_chain_attestation) }
  let(:sample_file) { fixture_file('supply_chain/attestation.json') }

  before do
    stub_uploads_object_storage(described_class)
  end

  describe '.direct_upload_enabled?' do
    it 'returns false' do
      expect(described_class.direct_upload_enabled?).to be(false)
    end
  end

  describe '.default_store' do
    context 'when object storage is enabled' do
      it 'returns REMOTE' do
        expect(described_class.default_store).to eq(ObjectStorage::Store::REMOTE)
      end
    end

    context 'when object storage is disabled' do
      before do
        stub_uploads_object_storage(described_class, enabled: false)
      end

      it 'returns LOCAL' do
        expect(described_class.default_store).to eq(ObjectStorage::Store::LOCAL)
      end
    end
  end
end
