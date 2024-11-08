# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Nuget::Symbol, type: :model, feature_category: :package_registry do
  subject(:symbol) { create(:nuget_symbol) }

  it { is_expected.to be_a FileStoreMounter }
  it { is_expected.to be_a ShaAttribute }
  it { is_expected.to be_a Packages::Destructible }

  describe 'relationships' do
    it { is_expected.to belong_to(:package).class_name('Packages::Nuget::Package').inverse_of(:nuget_symbols) }
    it { is_expected.to belong_to(:project) }

    # TODO: Remove with the rollout of the FF nuget_extract_nuget_package_model
    # https://gitlab.com/gitlab-org/gitlab/-/issues/499602
    it 'belongs legacy_package' do
      is_expected.to belong_to(:legacy_package).conditions(package_type: :nuget).class_name('Packages::Package')
        .inverse_of(:nuget_symbols).with_foreign_key(:package_id)
    end
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:package) }

    # TODO: Remove with the rollout of the FF nuget_extract_nuget_package_model
    # https://gitlab.com/gitlab-org/gitlab/-/issues/499602
    it { is_expected.not_to validate_presence_of(:legacy_package) }

    context 'when nuget_extract_nuget_package_model is disabled' do
      before do
        stub_feature_flags(nuget_extract_nuget_package_model: false)
      end

      it { is_expected.to validate_presence_of(:legacy_package) }
      it { is_expected.not_to validate_presence_of(:package) }
    end

    it { is_expected.to validate_presence_of(:file) }
    it { is_expected.to validate_presence_of(:file_path) }
    it { is_expected.to validate_presence_of(:signature) }
    it { is_expected.to validate_presence_of(:object_storage_key) }
    it { is_expected.to validate_presence_of(:size) }
    it { is_expected.to validate_uniqueness_of(:signature).scoped_to(:file_path) }
    it { is_expected.to validate_uniqueness_of(:object_storage_key).case_insensitive }
  end

  describe 'delegations' do
    it { is_expected.to delegate_method(:project_id).to(:package) }
    it { is_expected.to delegate_method(:project).to(:package) }

    context 'when nuget_extract_nuget_package_model is disabled' do
      before do
        stub_feature_flags(nuget_extract_nuget_package_model: false)
      end

      it { is_expected.to delegate_method(:project_id).to(:legacy_package) }
      it { is_expected.to delegate_method(:project).to(:legacy_package) }
    end
  end

  describe 'scopes' do
    describe '.stale' do
      subject { described_class.stale }

      let_it_be(:symbol) { create(:nuget_symbol) }
      let_it_be(:stale_symbol) { create(:nuget_symbol, :stale) }

      it { is_expected.to contain_exactly(stale_symbol) }
    end

    describe '.pending_destruction' do
      subject { described_class.pending_destruction }

      let_it_be(:symbol) { create(:nuget_symbol, :stale, :processing) }
      let_it_be(:stale_symbol) { create(:nuget_symbol, :stale) }

      it { is_expected.to contain_exactly(stale_symbol) }
    end

    describe '.with_signature' do
      subject(:with_signature) { described_class.with_signature(signature) }

      let_it_be(:signature) { 'signature' }
      let_it_be(:symbol) { create(:nuget_symbol, signature: signature) }

      shared_examples 'returns symbols with the given signature' do
        it { is_expected.to contain_exactly(symbol) }
      end

      it_behaves_like 'returns symbols with the given signature'

      context 'when signature is in uppercase' do
        subject(:with_signature) { described_class.with_signature(signature.upcase) }

        it_behaves_like 'returns symbols with the given signature'
      end
    end

    describe '.with_file_name' do
      subject(:with_file_name) { described_class.with_file_name(file_name) }

      let_it_be(:file_name) { 'file_name' }
      let_it_be(:symbol) { create(:nuget_symbol) }

      shared_examples 'returns symbols with the given file_name' do
        it 'returns symbols with the given file_name' do
          expect(with_file_name).to contain_exactly(symbol)
        end
      end

      before do
        symbol.update_column(:file, file_name)
      end

      it_behaves_like 'returns symbols with the given file_name'

      context 'when file_name is in uppercase' do
        subject(:with_file_name) { described_class.with_file_name(file_name.upcase) }

        it_behaves_like 'returns symbols with the given file_name'
      end
    end

    describe '.with_file_sha256' do
      subject { described_class.with_file_sha256(checksum) }

      let_it_be(:checksum) { OpenSSL::Digest.hexdigest('SHA256', 'checksum') }
      let_it_be(:symbol) { create(:nuget_symbol, file_sha256: checksum) }

      it { is_expected.to contain_exactly(symbol) }

      context 'when checksum is in uppercase' do
        subject { described_class.with_file_sha256(checksum.upcase) }

        it { is_expected.to contain_exactly(symbol) }
      end
    end

    describe '.find_by_signature_and_file_and_checksum' do
      subject { described_class.find_by_signature_and_file_and_checksum(signature, file_name, checksum) }

      let_it_be(:signature) { 'signature' }
      let_it_be(:file_name) { 'file.pdb' }
      let_it_be(:checksum) { OpenSSL::Digest.hexdigest('SHA256', 'checksums') }
      let_it_be(:symbol) { create(:nuget_symbol, signature: signature, file_sha256: checksum) }
      let_it_be(:another_symbol) { create(:nuget_symbol) }

      before do
        symbol.update_column(:file, file_name)
      end

      it { is_expected.to eq(symbol) }
    end
  end

  describe 'callbacks' do
    describe 'before_validation' do
      describe '#set_object_storage_key' do
        context 'when signature and project_id are present' do
          it 'sets the object_storage_key' do
            expected_key = Gitlab::HashedPath.new(
              'packages', 'nuget', symbol.package_id, 'symbols', OpenSSL::Digest::SHA256.hexdigest(symbol.signature),
              root_hash: symbol.project_id
            ).to_s

            symbol.valid?

            expect(symbol.object_storage_key).to eq(expected_key)
          end
        end

        context 'when signature is not present' do
          subject(:symbol) { build(:nuget_symbol, signature: nil) }

          it 'does not set the object_storage_key' do
            symbol.valid?

            expect(symbol.object_storage_key).to be_nil
          end
        end

        context 'when project_id is not present' do
          subject(:symbol) { build(:nuget_symbol) }

          before do
            allow(symbol).to receive(:project_id).and_return(nil)
          end

          it 'does not set the object_storage_key' do
            symbol.valid?

            expect(symbol.object_storage_key).to be_nil
          end
        end
      end
    end
  end
end
