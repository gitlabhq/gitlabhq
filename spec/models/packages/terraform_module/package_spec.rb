# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::TerraformModule::Package, type: :model, feature_category: :package_registry do
  describe 'relationships' do
    it do
      is_expected.to have_one(:terraform_module_metadatum).inverse_of(:package)
        .class_name('Packages::TerraformModule::Metadatum')
    end
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
end
