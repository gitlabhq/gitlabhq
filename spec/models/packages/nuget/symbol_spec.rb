# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Nuget::Symbol, type: :model, feature_category: :package_registry do
  subject(:symbol) { create(:nuget_symbol) }

  it { is_expected.to be_a FileStoreMounter }
  it { is_expected.to be_a ShaAttribute }
  it { is_expected.to be_a Packages::Destructible }

  describe 'relationships' do
    it { is_expected.to belong_to(:package).inverse_of(:nuget_symbols) }
  end

  describe 'validations' do
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
