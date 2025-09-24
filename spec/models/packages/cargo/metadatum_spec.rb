# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Cargo::Metadatum, feature_category: :package_registry do
  describe 'relationships' do
    it { is_expected.to belong_to(:package) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:package) }
    it { is_expected.to validate_presence_of(:normalized_name) }
    it { is_expected.to validate_presence_of(:normalized_version) }
    it { is_expected.to validate_length_of(:normalized_name).is_at_most(64) }
    it { is_expected.to validate_length_of(:normalized_version).is_at_most(255) }
  end

  describe 'uniqueness validation' do
    let_it_be(:project) { create(:project) }
    let_it_be(:existing_package) { create(:cargo_package, project: project, name: 'test-package', version: '1.0.0') }
    let_it_be(:existing_metadatum) { create(:cargo_metadatum, package: existing_package) }

    context 'when creating a new metadatum with different normalized name' do
      let(:new_package) { create(:cargo_package, project: project, name: 'different-package', version: '1.0.0') }
      let(:new_metadatum) { build(:cargo_metadatum, package: new_package) }

      it 'is valid' do
        expect(new_metadatum).to be_valid
      end
    end

    context 'when creating a new metadatum with different normalized version' do
      let(:new_package) { create(:cargo_package, project: project, name: 'test-package', version: '2.0.0') }
      let(:new_metadatum) { build(:cargo_metadatum, package: new_package) }

      it 'is valid' do
        expect(new_metadatum).to be_valid
      end
    end

    context 'when creating a new metadatum in different project' do
      let_it_be(:other_project) { create(:project) }
      let(:new_package) { create(:cargo_package, project: other_project, name: 'test-package', version: '1.0.0') }
      let(:new_metadatum) { build(:cargo_metadatum, package: new_package) }

      it 'is valid' do
        expect(new_metadatum).to be_valid
      end
    end
  end

  describe 'automatic normalization' do
    let(:package) { create(:cargo_package, name: 'My_Package_123', version: '1.0.0+build123') }
    let(:metadatum) { build(:cargo_metadatum, package: package) }

    it 'automatically sets normalized_name from package name' do
      metadatum.valid?
      expect(metadatum.normalized_name).to eq('my-package-123')
    end

    it 'automatically sets normalized_version from package version' do
      metadatum.valid?
      expect(metadatum.normalized_version).to eq('1.0.0')
    end
  end

  describe 'index_json', :aggregate_failures do
    let(:valid_json) do
      { 'name' => 'foo', 'vers' => '0.1.0', 'deps' => [],
        'cksum' => 'd867001db0e2b6e0496f9fac96930e2d42233ecd3ca0413e0753d4c7695d289c', 'v' => 2 }
    end

    it { is_expected.to allow_value(valid_json).for(:index_content) }
  end

  describe 'index_content is invalid when extra field is present' do
    let(:invalid_json) do
      { 'name' => 'foo', 'vers' => '0.1.0', 'deps' => [],
        'cksum' => 'd867001db0e2b6e0496f9fac96930e2d42233ecd3ca0413e0753d4c7695d289c', 'v' => 2, 'bad' => 'bad' }
    end

    it { is_expected.not_to allow_value(invalid_json).for(:index_content) }
  end
end
