# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Composer::Package, type: :model, feature_category: :package_registry do
  describe 'relationships' do
    it { is_expected.to have_one(:composer_metadatum).inverse_of(:package).class_name('Packages::Composer::Metadatum') }
  end

  describe 'delegates' do
    it { is_expected.to delegate_method(:target_sha).to(:composer_metadatum) }
  end

  describe 'validations' do
    describe '#valid_composer_global_name' do
      let_it_be(:package) { create(:composer_package) }

      context 'with different name and different project' do
        let(:new_package) { build(:composer_package, name: 'different_name') }

        it { expect(new_package).to be_valid }
      end

      context 'with same name and different project' do
        let(:new_package) { build(:composer_package, name: package.name) }

        it 'does not validate second package' do
          expect(new_package).not_to be_valid
          expect(new_package.errors.to_a).to include('Name is already taken by another project')
        end

        context 'with pending destruction package' do
          let_it_be(:package) { create(:composer_package, :pending_destruction) }

          it { expect(new_package).to be_valid }
        end
      end
    end

    describe '#version' do
      it_behaves_like 'validating version to be SemVer compliant for', :composer_package
    end
  end

  describe '.with_composer_target' do
    let_it_be(:sha) { OpenSSL::Digest.hexdigest('SHA256', 'foo') }
    let_it_be(:package1) { create(:composer_package, :with_metadatum, sha: sha) }
    let_it_be(:package2) { create(:composer_package, :with_metadatum, sha: sha) }
    let_it_be(:package3) { create(:composer_package, :with_metadatum, sha: OpenSSL::Digest.hexdigest('SHA256', 'bar')) }

    subject(:result) { described_class.with_composer_target(sha) }

    it 'selects packages with the specified sha', :aggregate_failures do
      expect(result).to include(package1)
      expect(result).to include(package2)
      expect(result).not_to include(package3)
    end
  end

  describe '.installable' do
    it_behaves_like 'installable packages', :composer_package
  end
end
