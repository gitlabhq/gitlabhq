# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SupplyChain::Attestation, feature_category: :artifact_security do
  subject(:attestation) { create(:supply_chain_attestation) }

  let(:sample_file) { fixture_file('supply_chain/attestation.json') }

  describe "validations" do
    it { is_expected.to belong_to(:project) }

    it { is_expected.to belong_to(:build) }

    it { is_expected.to validate_presence_of(:predicate_kind) }
    it { is_expected.to validate_presence_of(:predicate_type) }
    it { is_expected.to validate_presence_of(:subject_digest) }

    it { is_expected.to validate_uniqueness_of(:subject_digest).scoped_to([:project_id, :predicate_kind]) }
  end

  it { is_expected.to be_a FileStoreMounter }

  describe 'default attributes' do
    before do
      allow(SupplyChain::AttestationUploader).to receive(:default_store).and_return(5)
    end

    it { expect(described_class.new.file_store).to eq(5) }
    it { expect(described_class.new(file_store: 3).file_store).to eq(3) }
  end

  describe '#file' do
    it 'returns the saved file' do
      expect(attestation.file.read).to eq(sample_file)
    end
  end
end
