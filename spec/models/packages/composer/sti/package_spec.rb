# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Composer::Sti::Package, feature_category: :package_registry do
  describe 'relationships' do
    it { is_expected.to have_one(:composer_metadatum).inverse_of(:package).class_name('Packages::Composer::Metadatum') }
  end

  describe 'delegates' do
    it { is_expected.to delegate_method(:target_sha).to(:composer_metadatum).allow_nil }
    it { is_expected.to delegate_method(:composer_json).to(:composer_metadatum).allow_nil }
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

    describe '#name' do
      it_behaves_like 'validate package name format', :composer_package
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

  describe 'sync with packages_composer_packages table' do
    let_it_be_with_refind(:package) do
      create(:composer_package, :with_metadatum, sha: OpenSSL::Digest.hexdigest('SHA256', 'foo'))
    end

    let_it_be_with_reload(:metadatum) { package.composer_metadatum }

    subject(:composer_package) do
      package.connection.select_one(<<~SQL)
        SELECT * FROM packages_composer_packages WHERE id = #{package.id}
      SQL
    end

    it 'creates composer package with original attributes' do
      expect(composer_package).to eq(
        package.attributes_before_type_cast.except('package_type').merge(
          metadatum.attributes_before_type_cast.except('package_id')
        )
      )
    end

    context 'when package is updated' do
      let(:name) { FFaker::Lorem.word }

      before do
        package.update!(name: name)
      end

      it 'updates the composer package' do
        expect(composer_package['name']).to eq(name)
      end
    end

    context 'when metadatum is updated' do
      let(:composer_json) { { 'name' => FFaker::Lorem.word, 'version' => '1.0.1' } }

      before do
        metadatum.update!(composer_json: composer_json)
      end

      it 'updates the composer package' do
        expect(Gitlab::Json.parse(composer_package['composer_json'])).to eq(composer_json)
      end
    end

    context 'when package is deleted' do
      before do
        package.destroy!
      end

      it 'deletes the composer package' do
        expect(composer_package).to be_nil
      end
    end

    context 'when created package is not composer' do
      it 'does not create a new entry in packages_composer_packages table' do
        count = count_composer_packages

        create(:generic_package)

        expect(count_composer_packages).to eq(count)
      end
    end

    context 'when deleting not composer package' do
      it 'does not delete an entry from packages_composer_packages table' do
        count = count_composer_packages

        package.update!(package_type: ::Packages::Package.package_types[:maven])
        package.destroy!

        expect(count_composer_packages).to eq(count)
      end
    end
  end

  def count_composer_packages
    package.connection.select_value(<<~SQL)
      SELECT COUNT(*) FROM packages_composer_packages
    SQL
  end
end
