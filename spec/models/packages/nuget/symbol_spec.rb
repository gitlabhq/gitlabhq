# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Nuget::Symbol, type: :model, feature_category: :package_registry do
  subject(:symbol) { create(:nuget_symbol) }

  it { is_expected.to be_a FileStoreMounter }
  it { is_expected.to be_a ShaAttribute }
  it { is_expected.to be_a Packages::Destructible }
  it { is_expected.to be_a UpdateProjectStatistics }

  it_behaves_like 'having unique enum values'
  it_behaves_like 'destructible', factory: :nuget_symbol

  describe 'relationships' do
    it { is_expected.to belong_to(:package).class_name('Packages::Nuget::Package').inverse_of(:nuget_symbols) }
    it { is_expected.to belong_to(:project) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:package) }
    it { is_expected.to validate_presence_of(:file) }
    it { is_expected.to validate_presence_of(:file_path) }
    it { is_expected.to validate_presence_of(:signature) }
    it { is_expected.to validate_presence_of(:object_storage_key) }
    it { is_expected.to validate_presence_of(:size) }
    it { is_expected.to validate_uniqueness_of(:object_storage_key).case_insensitive }
    it { is_expected.to validate_presence_of(:project) }

    context 'for signature & file_path uniqueness' do
      let(:package) { build_stubbed(:nuget_package) }

      let(:new_symbol) do
        build(
          :nuget_symbol,
          signature: symbol.signature,
          package: package,
          project: package.project
        )
      end

      context 'when symbol has basic validation error' do
        before do
          new_symbol.project = nil
          new_symbol.validate
        end

        it 'does not validate uniqueness of signature' do
          expect(new_symbol.errors.messages_for(:signature)).not_to include 'has already been taken'
        end
      end

      context 'when symbol does not have basic validation errors' do
        before do
          new_symbol.validate
        end

        it 'validates uniqueness of signature' do
          expect(new_symbol.errors.messages_for(:signature)).to include 'has already been taken'
        end
      end

      context 'when existing package is not installable' do
        before do
          new_symbol.package = symbol.package if package_exists
          symbol.package.update_column(:status, :pending_destruction)
          new_symbol.validate
        end

        context 'and package already exists' do
          let(:package_exists) { true }

          it 'does not validate uniqueness of signature' do
            expect(new_symbol.errors.messages_for(:signature)).not_to include 'has already been taken'
          end
        end

        context 'and package does not exist' do
          let(:package_exists) { false }

          it 'does not validate uniqueness of signature' do
            expect(new_symbol.errors.messages_for(:signature)).not_to include 'has already been taken'
          end
        end
      end
    end
  end

  describe 'scopes' do
    describe '.orphan' do
      subject { described_class.orphan }

      let_it_be(:symbol) { create(:nuget_symbol) }
      let_it_be(:orphan_symbol) { create(:nuget_symbol, :orphan) }

      it { is_expected.to contain_exactly(orphan_symbol) }
    end

    describe '.pending_destruction' do
      subject { described_class.pending_destruction }

      let_it_be(:symbol) { create(:nuget_symbol, :orphan, :processing) }
      let_it_be(:orphan_symbol) { create(:nuget_symbol, :orphan) }

      it { is_expected.to contain_exactly(orphan_symbol) }
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

    describe '.with_file_path' do
      let_it_be(:file_path) { 'symbol_package/file.pdb' }
      let_it_be(:symbol) { create(:nuget_symbol, file_path: file_path) }

      subject { described_class.with_file_path(file_path) }

      it { is_expected.to contain_exactly(symbol) }

      context 'when file_path is in uppercase' do
        subject { described_class.with_file_path(file_path.upcase) }

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

      context 'when package_id is not present' do
        before do
          symbol.update_column(:package_id, nil)
        end

        it { is_expected.to be_nil }
      end
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

  context 'for project statistics' do
    let_it_be_with_reload(:package) { create(:nuget_package) }

    it_behaves_like 'UpdateProjectStatistics', :packages_size do
      subject { build(:nuget_symbol, package: package) }
    end
  end
end
