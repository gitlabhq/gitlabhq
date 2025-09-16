# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::TerraformModule::Package, type: :model, feature_category: :package_registry do
  describe 'relationships' do
    it do
      is_expected.to have_one(:terraform_module_metadatum).inverse_of(:package)
        .class_name('Packages::TerraformModule::Metadatum')
    end
  end

  describe 'nested attributes' do
    it { is_expected.to accept_nested_attributes_for(:terraform_module_metadatum) }
  end

  describe 'validations' do
    describe '#name' do
      subject { build_stubbed(:terraform_module_package) }

      it { is_expected.to allow_value('my-module/my-system').for(:name) }
      it { is_expected.to allow_value('my/module').for(:name) }
      it { is_expected.not_to allow_value('my-module').for(:name) }
      it { is_expected.not_to allow_value('My-Module').for(:name) }
      it { is_expected.not_to allow_value('my_module').for(:name) }
      it { is_expected.not_to allow_value('my.module').for(:name) }
      it { is_expected.not_to allow_value('../../../my-module').for(:name) }
      it { is_expected.not_to allow_value('%2e%2e%2fmy-module').for(:name) }
    end

    describe '#version' do
      it_behaves_like 'validating version to be SemVer compliant for', :terraform_module_package
    end
  end

  describe 'scopes' do
    describe '.unscope_order' do
      subject(:unscoped) { described_class.order(:name, created_at: :desc).unscope_order }

      it 'removes order clauses' do
        expect(unscoped.order_values).to be_empty
      end
    end

    describe '.order_metadatum_semver_desc' do
      subject { described_class.order_metadatum_semver_desc }

      let_it_be(:package1) do
        create(:terraform_module_package, :with_metadatum, version: '0.0.9', without_package_files: true)
      end

      let_it_be(:package2) do
        create(:terraform_module_package, :with_metadatum, version: '0.0.10', without_package_files: true)
      end

      it { is_expected.to eq([package2, package1]) }
    end
  end
end
