# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SupplyChain::Attestation, feature_category: :artifact_security do
  subject(:attestation) { create(:supply_chain_attestation) }

  let(:sample_file) { fixture_file('supply_chain/attestation.json') }
  let(:sample_predicate_file) { fixture_file('supply_chain/predicate.json') }

  describe "validations" do
    it { is_expected.to belong_to(:project) }

    it { is_expected.to belong_to(:build) }

    it { is_expected.to validate_presence_of(:predicate_kind) }
    it { is_expected.to validate_presence_of(:predicate_type) }
    it { is_expected.to validate_presence_of(:subject_digest) }

    it { is_expected.to validate_uniqueness_of(:subject_digest).scoped_to([:project_id, :predicate_kind]) }
  end

  describe 'default attributes' do
    before do
      allow(SupplyChain::AttestationUploader).to receive(:default_store).and_return(5)
    end

    it { expect(described_class.new.file_store).to eq(5) }
    it { expect(described_class.new(file_store: 3).file_store).to eq(3) }
    it { expect(described_class.new.predicate_file_store).to eq(5) }
    it { expect(described_class.new(predicate_file_store: 3).predicate_file_store).to eq(3) }
  end

  describe '#file' do
    it 'returns the saved file' do
      expect(attestation.file.read).to eq(sample_file)
    end
  end

  describe '#predicate_file' do
    it 'returns the saved file' do
      expect(attestation.predicate_file.read).to eq(sample_predicate_file)
    end
  end

  describe '#find_provenance' do
    let(:subject_digest) { "5db1fee4b5703808c48078a76768b155b421b210c0761cd6a5d223f2d99f1eaa" }

    subject(:attestation) do
      create(:supply_chain_attestation, subject_digest: subject_digest)
    end

    context "when the right parameters are passed" do
      let(:result) do
        described_class.find_provenance(project: attestation.project, subject_digest: subject_digest)
      end

      it 'finds the required attestation if the attestation exists' do
        expect(result).to be_a(described_class)
        expect(result.id).to eq(attestation.id)
      end
    end

    context "when incorrect parameters are passed" do
      let(:result) do
        described_class.find_provenance(project: attestation.project,
          subject_digest: "f3d9bb2a27422532b5264e1e1e22010ef9d71f604ca5de574a42a3ec07c27721")
      end

      it 'finds the required attestation if the attestation exists' do
        expect(result).to be_nil
      end
    end
  end

  describe '#with_iid' do
    subject(:attestation) { create(:supply_chain_attestation) }

    it 'returns the appropriate attestation' do
      expect(described_class.for_project(attestation.project).with_iid(attestation.iid).take).to eq(attestation)
    end
  end

  describe 'modules' do
    let_it_be(:project) { create(:project) }

    it_behaves_like 'AtomicInternalId' do
      let(:internal_id_attribute) { :iid }
      let(:instance) { build(:supply_chain_attestation, project: project) }
      let(:scope) { :project }
      let(:scope_attrs) { { project: project } }
      let(:usage) { :slsa_attestations }
    end
  end

  it_behaves_like 'object storable' do
    let(:locally_stored) do
      object = create(:supply_chain_attestation)

      if object.file_store == ObjectStorage::Store::REMOTE
        object.update_column(described_class::STORE_COLUMN, ObjectStorage::Store::LOCAL)
      end

      object
    end

    let(:remotely_stored) do
      object = create(:supply_chain_attestation)

      if object.file_store == ObjectStorage::Store::LOCAL
        object.update_column(described_class::STORE_COLUMN, ObjectStorage::Store::REMOTE)
      end

      object
    end
  end
end
